import glob
from transformers import pipeline
from os.path import basename, join, splitext

data_dir = "../data"
interviews_dir = join(data_dir, "interviews/audio")
transcripts_dir = join(data_dir, "interviews/transcripts")

audio_paths = glob.glob(
    join(data_dir, "interviews/audio/*.mp3")
)

existing_transcripts = [
    splitext(basename(path))[0]
    for path in glob.glob(join(transcripts_dir, "*.txt"))
]

interviews_to_transcribe = [
    path for path in audio_paths
    if splitext(basename(path))[0] not in existing_transcripts
]
print(str(len(interviews_to_transcribe)) + " interviews to transcribe...")
pipe = pipeline(
  "automatic-speech-recognition",
  model="openai/whisper-tiny",
  chunk_length_s=30,
  device="cpu",
)

predictions = pipe(interviews_to_transcribe)
for i in range(0, len(interviews_to_transcribe)):
    file_path = join(
        transcripts_dir,
        splitext(basename(interviews_to_transcribe[i]))[0] + ".txt"
    )
    with open(file_path, 'w') as file:
        file.write(predictions[i]['text'])

print("transcription finished.")
