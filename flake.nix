{
	description = "MADRS-AI development and inference environment";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
	};
	# nixConfig = {
	# 	allowUnfree = true;
	# };
	outputs = { nixpkgs, ... }:
		let
			system = "x86_64-linux";
			pkgs = import nixpkgs {
				system = system;
				config.allowUnfree = true;
			};
		in {
			devShells.${system}.default = pkgs.mkShell {
				buildInputs = with pkgs; [
					(python3.withPackages (pypkgs: with pypkgs; [
						torchWithCuda
						torchaudio
						torchvision
						transformers
						accelerate
						librosa
						gitpython
						pyannote-audio
						llama-cpp-python.override { cudaSupport = true; }
						jupyter
						ipykernel
					]))
					ffmpeg
					cudatoolkit
					cudaPackages.cudnn
					cudaPackages.cuda_cudart
					gcc13
				];
			};
			shellHook = # bash
			''
				export CUDA_PATH=${pkgs.cudatoolkit}

				# Set CC to GCC 13 to avoid the version mismatch error
				export CC=${pkgs.gcc13}/bin/gcc
				export CXX=${pkgs.gcc13}/bin/g++
				export PATH=${pkgs.gcc13}/bin:$PATH

				# Add necessary paths for dynamic linking
				export LD_LIBRARY_PATH=${
					pkgs.lib.makeLibraryPath [
						"/run/opengl-driver" # Needed to find libGL.so
						pkgs.cudatoolkit
						pkgs.cudaPackages.cudnn
					]
				}:$LD_LIBRARY_PATH

				# Set LIBRARY_PATH to help the linker find the CUDA static libraries
				export LIBRARY_PATH=${
					pkgs.lib.makeLibraryPath [
						pkgs.cudatoolkit
					]
				}:$LIBRARY_PATH
			'';
		};
}

