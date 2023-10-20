from typing import Optional

# noinspection PyPackageRequirements
from google.api_core.exceptions import InvalidArgument, NotFound
# noinspection PyPackageRequirements
from google.api_core.operation import from_gapic, Operation
# noinspection PyPackageRequirements
from google.api_core.retry import Retry
# noinspection PyPackageRequirements
from google.cloud.speech_v1p1beta1 import (
    SpeechClient, RecognitionConfig, RecognitionAudio, LongRunningRecognizeResponse, LongRunningRecognizeMetadata,
)

from mediawords.util.log import create_logger
from mediawords.workflow.exceptions import McProgrammingError

from .config import GCAuthConfig
from .transcript import Transcript, UtteranceAlternative, Utterance
from .media_info import MediaFileInfoAudioStream

log = create_logger(__name__)

# Speech API sometimes throws:
#
#   google.api_core.exceptions.ServiceUnavailable: 503 failed to connect to all addresses
#
# so let it retry for 10 minutes or so.
_GOOGLE_API_RETRIES = Retry(initial=5, maximum=60, multiplier=2, deadline=60 * 10)
"""Google Cloud API's own retry policy."""


def submit_transcribe_operation(gs_uri: str,
                                episode_metadata: MediaFileInfoAudioStream,
                                bcp47_language_code: str,
                                gc_auth_config: Optional[GCAuthConfig] = None) -> str:
    """
    Submit a Speech API long running operation to transcribe a podcast episode.

    :param gs_uri: Google Cloud Storage URI to a transcoded episode.
    :param episode_metadata: Metadata derived from the episode while transcoding it.
    :param bcp47_language_code: Episode's BCP 47 language code guessed from story's title + description.
    :param gc_auth_config: Google Cloud authentication configuration instance.
    :return Google Speech API operation ID by which the transcription operation can be referred to.
    """

    if not gc_auth_config:
        gc_auth_config = GCAuthConfig()

    try:
        client = SpeechClient.from_service_account_json(gc_auth_config.json_file())
    except Exception as ex:
        raise McProgrammingError(f"Unable to create Speech API client: {ex}")

    try:
        # noinspection PyTypeChecker
        config = RecognitionConfig(
            encoding=getattr(RecognitionConfig.AudioEncoding, episode_metadata.audio_codec_class.speech_api_codec()),
            sample_rate_hertz=episode_metadata.sample_rate,
            # We always set the channel count to 1 and disable separate recognition per channel as our inputs are all
            # mono audio files and do not have separate speakers per audio channel.
            audio_channel_count=1,
            enable_separate_recognition_per_channel=False,
            language_code=bcp47_language_code,
            alternative_language_codes=[],
            speech_contexts=[
                # Speech API works pretty well without custom contexts
            ],
            # Don't care that much about word confidence
            enable_word_confidence=False,
            # Punctuation doesn't work that well but we still enable it here
            enable_automatic_punctuation=True,
            # Not setting 'model' as 'use_enhanced' will then choose the best model for us
            # Using enhanced (more expensive) model, where available
            use_enhanced=True,
        )
    except Exception as ex:
        raise McProgrammingError(f"Unable to initialize Speech API configuration: {ex}")

    log.info(f"Submitting a Speech API operation for URI {gs_uri}...")

    try:

        # noinspection PyTypeChecker
        audio = RecognitionAudio(uri=gs_uri)

        speech_operation = client.long_running_recognize(config=config, audio=audio, retry=_GOOGLE_API_RETRIES)

    except Exception as ex:
        # If client's own retry mechanism doesn't work, then it's probably a programming error, e.g. outdated API client
        raise McProgrammingError(f"Unable to submit a Speech API operation: {ex}")

    try:
        # We get the operation name in a try-except block because accessing it is not that well documented, so Google
        # might change the property names whenever they please and we wouldn't necessarily notice otherwise
        operation_id = speech_operation.operation.name
        if not operation_id:
            raise McProgrammingError(f"Operation name is empty.")
    except Exception as ex:
        raise McProgrammingError(f"Unable to get operation name: {ex}")

    log.info(f"Submitted Speech API operation for URI {gs_uri}")

    return operation_id


def fetch_transcript(speech_operation_id: str, gc_auth_config: Optional[GCAuthConfig] = None) -> Optional[Transcript]:
    """
    Try to fetch a transcript for a given speech operation ID.

    :param speech_operation_id: Speech operation ID.
    :param gc_auth_config: Google Cloud authentication configuration instance.
    :return: Transcript, or None if the transcript hasn't been prepared yet.
    """
    if not speech_operation_id:
        raise McProgrammingError(f"Speech operation ID is unset.")

    if not gc_auth_config:
        gc_auth_config = GCAuthConfig()

    try:
        client = SpeechClient.from_service_account_json(gc_auth_config.json_file())
    except Exception as ex:
        raise McProgrammingError(f"Unable to initialize Speech API operations client: {ex}")

    try:
        operation = client.transport.operations_client.get_operation(
            name=speech_operation_id,
            retry=_GOOGLE_API_RETRIES,
        )
    except InvalidArgument as ex:
        raise McProgrammingError(f"Invalid operation ID '{speech_operation_id}': {ex}")
    except NotFound as ex:
        raise McProgrammingError(f"Operation ID '{speech_operation_id}' was not found: {ex}")
    except Exception as ex:
        # On any other errors, raise a hard exception
        raise McProgrammingError(f"Error while fetching operation ID '{speech_operation_id}': {ex}")

    if not operation:
        raise McProgrammingError(f"Operation is unset.")

    try:
        gapic_operation: Operation = from_gapic(
            operation=operation,
            operations_client=client.transport.operations_client,
            result_type=LongRunningRecognizeResponse,
            metadata_type=LongRunningRecognizeMetadata,
            retry=_GOOGLE_API_RETRIES,
        )
    except Exception as ex:
        raise McProgrammingError(f"Unable to create GAPIC operation: {ex}")

    log.debug(f"GAPIC operation: {gapic_operation}")
    log.debug(f"Operation metadata: {gapic_operation.metadata}")
    log.debug(f"Operation is done: {gapic_operation.done()}")
    log.debug(f"Operation error: {gapic_operation.done()}")

    try:
        operation_is_done = gapic_operation.done(retry=_GOOGLE_API_RETRIES)
    except Exception as ex:
        # 'done' attribute might be gone in a newer version of the Speech API client
        raise McProgrammingError(
            f"Unable to test whether operation '{speech_operation_id}' is done: {ex}"
        )

    if not operation_is_done:
        log.info(f"Operation '{speech_operation_id}' is still not done.")
        return None

    utterances = []

    try:
        for result in gapic_operation.result(retry=_GOOGLE_API_RETRIES).results:

            alternatives = []
            for alternative in result.alternatives:
                alternatives.append(
                    UtteranceAlternative(
                        text=alternative.transcript.strip(),
                        confidence=alternative.confidence,
                    )
                )

            utterances.append(
                Utterance(
                    alternatives=alternatives,
                    bcp47_language_code=result.language_code,
                )
            )

    except Exception as ex:
        raise McProgrammingError(
            f"Unable to read transcript for operation '{speech_operation_id}' due to other error: {ex}"
        )

    return Transcript(utterances=utterances)
