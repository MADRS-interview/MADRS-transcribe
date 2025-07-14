{
	description = "Devshells for AI development at IMHR.";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
		expy-flake.url = "github:KerryCerqueira/expy";
	};

	outputs =
		{ nixpkgs, flake-utils, expy-flake, ... }:
		flake-utils.lib.eachDefaultSystem (system:
			let
				shellHook = # bash
					''
				python -m ipykernel install --user --name nix
				'';
				skipSentenceTests = self: super: {
					# Extend the per-interpreter overrides
					pythonPackagesExtensions = (super.pythonPackagesExtensions or []) ++ [
						(pySelf: pySuper: {
							sentence-transformers = pySuper.sentence-transformers.overrideAttrs (old: {
								disabledTests = (old.disabledTests or []) ++ [
									# Fails on Nix builders ⇒ skip it
									"test_performance_with_large_vectors"
								];
							});
						})
					];
				};
			in {
				devShells = {
					cudaInference = let
						pkgs = import nixpkgs {
							system = system;
							config.allowUnfree = true;
							config.cudaSupport = true;
							overlays = [
								expy-flake.overlays.${system}.default
								skipSentenceTests
							];
						};
						cudaDriverPath = "/usr/lib/x86_64-linux-gnu/libcuda.so.1";
					in pkgs.mkShell {
							buildInputs = with pkgs; [
								(python3.withPackages ( ps: with ps; [
									expy
									torch
									llama-cpp-python
									ipython
									ipykernel
									langchain
									langchain-community
									langchain-huggingface
									langgraph
									langsmith
									pip
									fastapi
									uvicorn
									sse-starlette
									starlette-context
									pydantic-settings
									psutil
									numpy
									diskcache
								]))
							];
							LD_PRELOAD = cudaDriverPath;
							inherit shellHook;
						};
				};
			}
		);
}
