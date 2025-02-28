# dotfiles conventions

## Host Configuration
- Each machine host is defined under `hosts/<hostname>/`
- Contains from three core files:
  - `configuration.nix` - System configuration
  - `hardware-configuration.nix` - Hardware-specific settings
  - `home.nix` - User environment configuration

## Flake Structure
- Host configurations are defined using `mkSystem` in `flake.nix`
- New hosts must extend the `nixosConfigurations` attribute

## Module Organization
- Home Manager modules are located under `modules/`
  - Contains customized configurations for services and packages
- Legacy system configurations are temporarily stored in `modules/system/`
  - These will be migrated to appropriate module locations

## Overlays
- Custom Nix overlays are stored in the `overlays/` directory
