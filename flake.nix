{
	description = "Devshells for AI development at IMHR.";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
	};

	outputs =
		{ self, nixpkgs }:
		let
			system = "x86_64-linux";
			cudaDriverPath = "/usr/lib/x86_64-linux-gnu/libcuda.so.1";
			shellHook = # bash
				''
				python -m ipykernel install --user --name nix
				'';
		in
			{
			devShells.${system} = {
				cudaInference = let
					pkgs = import nixpkgs {
						system = system;
						config.allowUnfree = true;
						config.cudaSupport = true;
					};
				in pkgs.mkShell {
						buildInputs = with pkgs; [
							(python3.withPackages ( ps: with ps; [
								torch
								transformers
								llama-cpp-python
								ipython
								ipykernel
								langchain
								langchain-community
								langchain-huggingface
								langgraph
								langsmith
								fastapi
								uvicorn
								sse-starlette
								starlette-context
								pydantic-settings
								psutil
								numpy diskcache
							]))
							jupyter
						];
						LD_PRELOAD = cudaDriverPath;
						inherit shellHook;
					};
				langchainDev = let
					pkgs  = import nixpkgs {
						system = system;
				};
				in pkgs.mkShell {
						buildInputs = with pkgs; [
							(python3.withPackages ( ps: with ps; [
								ipython
								ipykernel
								langchain
								langchain-community
								langchain-huggingface
								langchain-openai
								langgraph
							]))
							jupyter
						];
						inherit shellHook;
					};
			};
		};
}
