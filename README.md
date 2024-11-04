## plane-tracker
A little powershell script that uses the ADS-B Exchange API to let you know when an airplane is about to come into audible airspace around a location you set.

Now a standalone webapp at [(https://heimeyra.app)].

## audiobook-stats
A couple of scripts which make it easy to manage a large number of data reports created by Steven Jay Cohen's [2nd Opinion](https://stevenjaycohen.com/2ndopinion/) software. The resultant dataset is published [here](https://docs.google.com/spreadsheets/d/e/2PACX-1vTckR6edf8DZZN6qKDEisn4JvHTs-tG8kzxq3coDeW_laVbvlLBJBNzCe_sxwGqfJvpNwC_gTMwYcTo/pubhtml).

## reaper-count-edits
A quick-and-dirty utility to count clip edits in Reaper project files. Used for audiobooks where every chapter is a discrete project file, and you want to know how many edits you made in each chapter.

## folder-structures
A couple of AutoHotKey scripts which set up my local project folder structures very quickly and easily. Nothing groundbreaking here, but if you want to save yourself some steps but don't speak enough AutoHotKey to write your own, you can use mine or modify them pretty easily.

## whisper-transcription
A simple command-line wrapper for [OpenAI's Whisper](https://github.com/openai/whisper) text-to-speech LM, using [regstuff's](https://github.com/regstuff/whisper.cpp_windows) windows binary of Whisper.cpp and [ggerganov's](https://ggml.ggerganov.com/) GGML model files. Faster than realtime audio transcription with output directly to clipboard. Excellent for short files like voicemails, dictated notes, etc.

## blink1-busy-light
A simple Autohotkey script which triggers a blink(1) device to toggle between RED and OFF states on Ctrl+Shift+1 keypress. Requires blink1-tool. 

## SSMS subscription email-recipient parser
A small script to convert a raw list of email addresses (in sundry syntaxes) into a semicolon-delimited list that SSMS can accept. Strips commas, brackets, and newlines.
