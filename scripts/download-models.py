from huggingface_hub import snapshot_download

def download_safetensors(repo_id: str) -> None:
    snapshot_download(
        repo_id = repo_id,
        local_dir=f"/HDD_12TB/kerry/models/safetensors/{repo_id.split('/')[0]}/{repo_id.split('/')[1]}",
        max_workers=1,
        allow_patterns = "*.safetensors",
    )

def download_gguf(repo_id: str) -> None:
    snapshot_download(
        repo_id = repo_id,
        local_dir=f"/HDD_12TB/kerry/models/gguf/{repo_id.split('/')[0]}/{repo_id.split('/')[1]}",
        max_workers=1,
        allow_patterns = "*Q4_K_M*.gguf",
    )
    
gguf_models = [
    "unsloth/Llama-3.3-70B-Instruct-GGUF",
    "unsloth/DeepSeek-R1-Distill-Llama-70B-GGUF",
    "unsloth/Llama-4-Scout-17B-16E-Instruct-GGUF",
    # "bartowski/Mistral-Large-Instruct-2407-GGUF",
]
safetensors_models = [
    "microsoft/MediPhi-Instruct",
    "microsoft/Phi-4-reasoning",
    "microsoft/Phi-4-mini-flash-reasoning",
    "meta-llama/Llama-3.2-1B-Instruct",
    "tiiuae/Falcon-H1-34B-Instruct",
    "deepseek-ai/deepseek-vl-7b-chat",
    "mistralai/Voxtral-Small-24B-2507",
    "mistralai/Voxtral-Mini-3B-2507",
    "mistralai/Mixtral-8x7B-Instruct-v0.1",
    "mistralai/Pixtral-12B-2409",
    "mistralai/Magistral-Small-2506"
]

for model in gguf_models:
    print(f"downloading {model}...")
    download_gguf(model)
for model in safetensors_models:
    print(f"downloading {model}...")
    download_safetensors(model)
