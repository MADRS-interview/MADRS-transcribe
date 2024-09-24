from pyannote.audio import Pipeline as Pyannote_Pipeline
from pyannote.audio.pipelines.utils.hook import ProgressHook
from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor, pipeline as Transformers_Pipeline

import librosa
import torch

def Pipeline(
    auth_token,
    diarization_model="pyannote/speaker-diarization-3.1",
    transcription_model = "openai/whisper-tiny",
    pad=0.5,
    sample_rate = 16000,
    collar = 3,
):
    return lambda x: PipelineGenerator(
        auth_token,
        diarization_model,
        transcription_model,
        pad,
        sample_rate,
        collar,
    ).transcribe(x)

class PipelineGenerator:

    def __init__(
        self,
        auth_token,
        diarization_model,
        transcription_model,
        pad,
        sample_rate,
        collar,
    ):
        device = "cuda:0" if torch.cuda.is_available() else "cpu"
        self.diarization_pipeline = Pyannote_Pipeline.from_pretrained(
            diarization_model,
            use_auth_token = auth_token,
        ).to(torch.device(device))
        processor = AutoProcessor.from_pretrained(transcription_model)
        self.transcription_pipeline = Transformers_Pipeline(
            "automatic-speech-recognition",
            model = AutoModelForSpeechSeq2Seq.from_pretrained(
                transcription_model,
                torch_dtype = torch.float16 if torch.cuda.is_available() else torch.float32,
                low_cpu_mem_usage=True,
                use_safetensors=True
            ).to(device),
            tokenizer= processor.tokenizer,
            feature_extractor= processor.feature_extractor,
            return_timestamps=True,
            generate_kwargs={"language": "english"},
        )
        self.pad = pad
        self.sample_rate = sample_rate
        self.collar = collar

    def transcribe(self, target):
        with ProgressHook() as hook:
            diarization = (
                self
                .diarization_pipeline(target, hook=hook)
                .support(collar = self.collar)
            )
        audio, _ = librosa.load(target, sr=self.sample_rate)
        transcript = ""
        for segment, _, label in diarization.itertracks(yield_label=True):
            audio_segment = audio[
                int(max(0,segment.start-self.pad)*self.sample_rate):
                int(min(len(audio), (segment.end+self.pad)*self.sample_rate))
            ]
            transcript_segment = self.transcription_pipeline(audio_segment)
            transcript += label + ":" + transcript_segment["text"] + "\n\n"
        return transcript
