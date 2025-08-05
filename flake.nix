{
	description = "AI infrastructure for IMHR.";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
		expy-flake.url = "github:KerryCerqueira/expy";
		tgi-flake.url = "github:huggingface/text-generation-inference";
	};
	outputs =
		{ nixpkgs, flake-utils, expy-flake, tgi-flake, ... }:
		flake-utils.lib.eachDefaultSystem (system:
			let
				cudaDriverPath = "/usr/lib/x86_64-linux-gnu/libcuda.so.1";
				cudaPkgs = import nixpkgs {
					system = system;
					config.allowUnfree = true;
					config.cudaSupport = true;
				};
				skipSentenceTests = self: super: {
					pythonPackagesExtensions = (super.pythonPackagesExtensions or []) ++ [
						(pySelf: pySuper: {
							sentence-transformers = pySuper.sentence-transformers.overrideAttrs (old: {
								disabledTests = (old.disabledTests or []) ++ [
									"test_performance_with_large_vectors"
								];
							});
						})
					];
				};
			in {
				devShells = {
					expy = let
						pkgs = import nixpkgs {
							system = system;
							overlays = [
								expy-flake.overlays.${system}.default
								skipSentenceTests
							];
						};
					in pkgs.mkShell {
							buildInputs = with pkgs; [
								(python3.withPackages ( ps: with ps; [
									expy
									huggingface-hub
									hf-xet
									matplotlib
									pandas
									jupyter
							]))
							];
							shellHook = # bash
								''
								python -m ipykernel install --user --name nix
								'';
						};
					llamaInference = let
						pkgs = cudaPkgs;
					in pkgs.mkShell {
							buildInputs = with pkgs; [
								(python3.withPackages ( ps: with ps; [
									diskcache
									fastapi
									huggingface-hub
									llama-cpp-python
									numpy
									psutil
									pydantic-settings
									sse-starlette
									starlette-context
									uvicorn
								]))
							];
							LD_PRELOAD = cudaDriverPath;
						};
				};
				apps = {
					expy = flake-utils.lib.mkApp { drv = expy-flake.packages.${system}.default; };
					llamaServer = let
						pkgs = cudaPkgs;
						llamaServerWrapped = pkgs.writeShellApplication {
							name = "llama-server";
							runtimeInputs = [ pkgs.llama-cpp ];
							text = ''
								export LD_PRELOAD=${cudaDriverPath}
								exec ${pkgs.llama-cpp}/bin/llama-server "$@"
							'';
						};
					in flake-utils.lib.mkApp { drv = llamaServerWrapped; };
					hfServer = flake-utils.lib.mkApp { drv = tgi-flake.packages.${system}.default; };
					owuiServer = let
						pkgs = import nixpkgs {
							inherit system;
							config.allowUnfree = true;
						};
						runner = pkgs.writeShellScriptBin "openwebui" ''
							set -euo pipefail

							: ''${XDG_DATA_HOME:="$HOME/.local/share"}
							: ''${DATA_DIR:="$XDG_DATA_HOME/open-webui"}
							mkdir -p "''${DATA_DIR}"
							export DATA_DIR
							: ''${PORT:=8082}

							exec ${pkgs.open-webui}/bin/open-webui serve \
							--host 0.0.0.0 --port "''${PORT}" "$@"
						'';
					in {
						type = "app";
						program = "${runner}/bin/openwebui";
					};
				};
			}
		);
}
