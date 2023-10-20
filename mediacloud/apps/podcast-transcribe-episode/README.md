# Podcast transcription

## TODO

* [Upload transcriptions directly to GCS](https://cloud.google.com/speech-to-text/docs/async-recognize#speech_transcribe_async_gcs-python)
  once that's no longer a demo feature
* Add all Chinese variants to `alternative_language_codes`
* Add all Mexican Spanish variants to `alternative_language_codes`
* Post-init [validation of dataclasses](https://docs.python.org/3/library/dataclasses.html#post-init-processing)
* When operation ID can't be found, resubmit the podcast for transcription as that might mean that the operation results
  weren't fetched in time and so the operation has expired
* Add heartbeats to transcoding activity
* Test running the same activity multiple times
* If an activity throws an exception, its message should get printed out to the console as well (in addition to
  Temporal's log)
* Track failed workflows / activities in Munin
* Instead (in addition to) of setting `workflow_run_timeout` in `test_workflow.py`, limit retries of the individual
  activities too so that when they fail, we'd get a nice error message printed to the test log
