from pyannote.audio import Pipeline as Pyannote_Pipeline
from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor, pipeline as Transformers_Pipeline

import librosa
import torch

def Pipeline(
    diarization_model="pyannote/speaker-diarization-3.1",
    transcription_model = "openai/whisper-large-v3",
    collar = 2,
    diarize = True,
):
    return lambda x: PipelineGenerator(
        diarization_model = diarization_model,
        transcription_model = transcription_model,
        collar = collar,
        diarize = diarize,
    ).transcribe(x)

class PipelineGenerator:

    def __init__(
        self,
        *,
        diarization_model,
        transcription_model,
        collar,
        diarize,
    ):
        device = "cuda" if torch.cuda.is_available() else "cpu"
        self.diarization_pipeline = Pyannote_Pipeline.from_pretrained(
            diarization_model,
        ).to(torch.device(device))
        self.transcription_pipeline = Transformers_Pipeline(
            "automatic-speech-recognition",
            model = transcription_model,
            return_timestamps=True,
            generate_kwargs={"language": "english"},
            device = device,
        )
        self.pad = 0.5
        self.sample_rate = 16000
        self.collar = collar
        self.num_speakers = 2
        self.diarize = diarize

    def transcribe(self, target):
        if self.diarize:
            return self.diarize_transcribe(target)
        else:
            return self.nodiarize_transcribe(target)

    def diarize_transcribe(self, target):
        diarization = (
            self
            .diarization_pipeline(
                target, 
                num_speakers = self.num_speakers
            )
            .support(collar = self.collar)
        )
        audio, _ = librosa.load(target, sr = self.sample_rate)
        transcript = ""
        for segment, _, label in diarization.itertracks(yield_label=True):
            audio_segment = audio[
                int(max(0,segment.start-self.pad)*self.sample_rate):
                int(min(len(audio), (segment.end+self.pad)*self.sample_rate))
            ]
            transcript_segment = self.transcription_pipeline(audio_segment)
            transcript += label + ":" + transcript_segment["text"] + "\n\n"
        return transcript

    def nodiarize_transcribe(self, target):
        audio, _ = librosa.load(target, sr=self.sample_rate)
        return self.transcription_pipeline(audio)["text"]
            
