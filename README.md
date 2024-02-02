# MADRS Interview Transcription

A repository to implement the transcription pipeline for MADRS.

## Usage

A conda environment with required dependencies can be initialized by running
`conda env create -f environment.yml` from the repository root. You can activate
the new environment by running `conda activate MADRS-transcribe`.

Audio files to be transcribed should be placed in `data/interviews/audio`. The
transcription pipeline can then by run by running the python script
`/scripts/transcribe.py`, or run `git transcribe` after initializing the
repository with the script described below. Transcripts will appear in
`data/interviews/transcripts`.

### `git` aliases
Run the script `/scripts/init-repo` to configure aliases local to this
repository to run key data ops.
