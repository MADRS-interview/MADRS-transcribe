{
	description = "AI infrastructure for IMHR.";
	inputs = {
		nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
		expy-flake.url = "github:KerryCerqueira/expy";
		tgi-flake.url = "github:huggingface/text-generation-inference";
	};
	outputs =
		{ nixpkgs, flake-utils, expy-flake, tgi-flake, ... }:
		flake-utils.lib.eachDefaultSystem (system:
			let
				shellHook = # bash
					''
				python -m ipykernel install --user --name nix
				'';
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
									langchain
									langchain-community
									langchain-huggingface
									langchain-openai
									langgraph
									matplotlib
									pandas
									jupyter
							]))
							];
							inherit shellHook;
						};
					LlamaInference = let
						pkgs = import nixpkgs {
							system = system;
							config.allowUnfree = true;
							config.cudaSupport = true;
						};
						cudaDriverPath = "/usr/lib/x86_64-linux-gnu/libcuda.so.1";
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
						pkgs = import nixpkgs {
							system = system;
							overlays = [
								expy-flake.overlays.${system}.default
								skipSentenceTests
							];
						};
						in {
						type = "app";
						program = "${pkgs.llama-cpp}/bin/llama-server";
					};
					hfServer = flake-utils.lib.mkApp { drv = tgi-flake.packages.${system}.default; };
					expy = flake-utils.lib.mkApp { drv = expy-flake.packages.${system}.default; };
				};
			}
		);
}
