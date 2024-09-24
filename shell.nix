{ pkgs ? import <nixpkgs> {} }:
let
	fhs = pkgs.buildFHSUserEnv {
		name = "mamba:MADRS-transcribe";

		targetPkgs = _: [
			pkgs.micromamba
		];

		profile = ''
			set -e
			eval "$(micromamba shell hook --shell=posix)"
			export MAMBA_ROOT_PREFIX=${builtins.getEnv "PWD"}/.mamba
			if ! micromamba list --name MADRS-transcribe > /dev/null 2>&1; then
				echo "Creating conda env..."
				micromamba create --name MADRS-transcribe --file environment.yml --yes
			else
				echo "conda env exists. Updating fron environment.yml..."
				micromamba update --name MADRS-transcribe --file environment.yml --prune
			fi
			if [ -x "$(command -v pip)" ] && [ -f requirements.txt ]; then
				pip install -r requirements.txt
			else
				echo "Either pip is not installed or requirements.txt does not exist."
			fi
			micromamba run --name MADRS-transcribe python -m ipykernel install --user --name MADRS-transcribe
			echo "Activating environment..."
			micromamba activate MADRS-transcribe
			zsh
			set +e
		'';
	};
in
	fhs.env
