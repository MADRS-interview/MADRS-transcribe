# MADRS Interview Transcription

A repository to implement the transcription pipeline for MADRS automation.

## Usage

A nix flake is provided to set up the computational environments to run this
project. On `counter`, from the root directory of this project run

```sh
nix develop .#cudaInference
```

On another machine with access to remote LLM inference we can run a more minimalistic

```sh
nix develop .#langchainDev
```

