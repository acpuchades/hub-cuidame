{
	description = "Reproducible R environment with Nix flake";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
	};

	outputs = { nixpkgs, flake-utils, ... }:
		flake-utils.lib.eachDefaultSystem (system:
		let
			pkgs = import nixpkgs { inherit system; };
			r-packages = with pkgs.rPackages; [
				tidyverse
				nlme
				mgcv
				sjPlot
				effects
				emmeans
				ggeffects
				gtsummary
				gt
				janitor
				readxl
			];
			r-with-packages = pkgs.rWrapper.override { packages = r-packages; };
			rstudio-with-packages = pkgs.rstudioWrapper.override { packages = r-packages; };
			render-cmd = pkgs.writeShellApplication {
				name = "render";
				runtimeInputs = [ pkgs.ffmpeg pkgs.quarto pkgs.pandoc pkgs.texliveFull r-with-packages ];
				text = ''
					${r-with-packages}/bin/Rscript -e "quarto::quarto_render('analisis.qmd')"
				'';
			};
			rstudio-cmd = pkgs.writeShellApplication {
				name = "rstudio";
				runtimeInputs = [ pkgs.ffmpeg pkgs.quarto rstudio-with-packages ];
				text = ''
					${rstudio-with-packages}/bin/rstudio ./analisis.qmd
				'';
			};
		in {
			devShells.default = pkgs.mkShell {
				packages = [
					r-with-packages
					rstudio-with-packages
				];
			};
			apps.rstudio = {
				type = "app";
				program = "${rstudio-cmd}/bin/rstudio";
			};
			apps.render = {
				type = "app";
				program = "${render-cmd}/bin/render";
			};
		});
}
