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
					LlamaInference = let
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
					expy = flake-utils.lib.mkApp { drv = expy-flake.packages.${system}.default; };
				};
			}
		);
}
