import hashlib
import inspect
import os
import tempfile

# noinspection PyPackageRequirements
import pytest

from mediawords.workflow.exceptions import McPermanentError

from podcast_transcribe_episode.audio_codecs import AbstractAudioCodec
from podcast_transcribe_episode.media_info import media_file_info, MediaFileInfo
from podcast_transcribe_episode.transcode import transcode_file_if_needed

MEDIA_SAMPLES_PATH = '/opt/mediacloud/tests/data/media-samples/samples/'
assert os.path.isdir(MEDIA_SAMPLES_PATH), f"Directory with media samples '{MEDIA_SAMPLES_PATH}' should exist."

SAMPLE_FILENAMES = [
    f for f in os.listdir(MEDIA_SAMPLES_PATH)

    # Skip the long audio recording as it takes a few seconds more to transcode it and it really doesn't test anything
    # at this point
    if os.path.isfile(os.path.join(MEDIA_SAMPLES_PATH, f)) and 'nixon_speech-' not in f
]
assert SAMPLE_FILENAMES, f"There should be some sample files available in {MEDIA_SAMPLES_PATH}."
assert [f for f in SAMPLE_FILENAMES if '.mp3' in f], f"There should be at least one .mp3 file in {MEDIA_SAMPLES_PATH}."
assert not [f for f in SAMPLE_FILENAMES if '/' in f], f"There can't be any paths in {SAMPLE_FILENAMES}."


def test_media_file_info():
    at_least_one_stereo_file_found = False

    for filename in SAMPLE_FILENAMES:

        input_file_path = os.path.join(MEDIA_SAMPLES_PATH, filename)

        if '-invalid' in filename:

            with pytest.raises(McPermanentError):
                media_file_info(media_file_path=input_file_path)

        else:

            media_info = media_file_info(media_file_path=input_file_path)
            assert isinstance(media_info, MediaFileInfo)
            if '.mp3' in filename:
                assert not media_info.has_video_streams, f"MP3 file '{filename}' is not expected to have video streams."
            if '.mkv' in filename:
                assert media_info.has_video_streams, f"MKV file '{filename}' is expected to have video streams."
            if 'noaudio' in filename:
                assert not media_info.audio_streams, f"File '{filename}' is not expected to have any audio streams."
            else:
                assert media_info.audio_streams, f"File '{filename}' is expected to have audio streams."

            if media_info.audio_streams:
                for stream in media_info.audio_streams:
                    assert stream.duration > 0, f"File's '{filename}' stream's {stream} duration should be positive."
                    if stream.audio_channel_count > 1:
                        at_least_one_stereo_file_found = True

    # We expect to be able to test out stereo -> mono mixing
    assert at_least_one_stereo_file_found, "At least one of the input test files should be a stereo audio file."


def _file_sha1_hash(file_path: str) -> str:
    """Return file's SHA1 hash."""

    sha1 = hashlib.sha1()

    with open(file_path, 'rb') as f:
        while True:
            data = f.read(65536)
            if not data:
                break
            sha1.update(data)

    return sha1.hexdigest()


def test_transcode_file_if_needed():
    for filename in SAMPLE_FILENAMES:
        input_file_path = os.path.join(MEDIA_SAMPLES_PATH, filename)
        assert os.path.isfile(input_file_path), f"Input file '{filename}' exists."

        before_sha1_hash = _file_sha1_hash(input_file_path)

        if '-noaudio' in filename:

            # Media file with no audio
            with pytest.raises(McPermanentError):
                transcode_file_if_needed(
                    input_file=input_file_path,
                    output_file=os.path.join(tempfile.mkdtemp('test'), 'test'),
                )

        elif '-invalid' in filename:

            # Invalid media file
            with pytest.raises(McPermanentError):
                transcode_file_if_needed(
                    input_file=input_file_path,
                    output_file=os.path.join(tempfile.mkdtemp('test'), 'test'),
                )

        else:
            output_file = os.path.join(tempfile.mkdtemp('test'), 'test')

            media_file_transcoded = transcode_file_if_needed(
                input_file=input_file_path,
                output_file=output_file,
            )

            output_file_info = media_file_info(
                media_file_path=output_file if media_file_transcoded else input_file_path,
            )

            assert not output_file_info.has_video_streams, f"There should be no video streams in '{filename}'."
            assert len(output_file_info.audio_streams) == 1, f"There should be only one audio stream in '{filename}'."

            audio_stream = output_file_info.audio_streams[0]
            assert audio_stream.audio_codec_class, f"Audio codec class is set for filename '{filename}'."
            assert inspect.isclass(audio_stream.audio_codec_class), f"Audio codec is a class for filename '{filename}'."
            assert issubclass(
                audio_stream.audio_codec_class,
                AbstractAudioCodec,
            ), f"Processed '{filename}' should be in one of the supported codecs."
            assert audio_stream.audio_channel_count == 1, f"Output file should be only mono for filename '{filename}'."

            if '-mp3-mono' in filename:
                assert media_file_transcoded is False, "Mono MP3 file shouldn't have been transcoded."
                assert not os.path.isfile(output_file), "Output file should not exist."
            else:
                assert media_file_transcoded is True, f"File '{filename}' should have been transcoded."
                assert os.path.isfile(output_file), "Output file should exist."

        after_sha1_hash = _file_sha1_hash(input_file_path)

        assert before_sha1_hash == after_sha1_hash, f"Input file '{filename}' shouldn't have been modified."
