# Claude Assistant Guide for Dotfiles Repository

## Commands
- Format code: `nix fmt`
- Build system & home config: `nixos-rebuild switch --flake .#`
- Darwin build: `nix run nix-darwin -- switch --flake .#`
- VM testing: `nix build ./#nixosConfigurations.vm.config.system.build.vm`
- Reload flake lock: `nix flake update`

## Code Style Guidelines
- Follow module-based architecture in `modules/` directory
- Host configurations in `hosts/<hostname>/` directory
- Home-manager configuration in `hosts/<hostname>/home.nix`
- Use descriptive names for options with prefixes (e.g., `programs.neovim.enable`)
- Maintain consistent indentation (2 spaces) in .nix files
- Group related options together
- Include comments for complex configurations
- Use sops-nix for secret management

## Repository Structure
- `flake.nix`: Entry point defining inputs and outputs
- `modules/`: Reusable configuration modules
- `hosts/`: Host-specific and home-manager configurations
- `overlays/`: Nixpkgs overlays, organized numerically:
  - `00-themes/`: Theme-related overlays
  - `10-wrappers/`: Wrapper scripts
  - `20-scripts/`: Custom scripts
  - `90-apps/`: Application-specific overlays