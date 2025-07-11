# NixOS Dotfiles Guidelines

## Build/Test Commands

### Primary Commands
- **Format code**: `nix fmt`
- **Build NixOS config**: `nixos-rebuild switch --flake .#`
- **Build Darwin config**: `nix run nix-darwin -- switch --flake .#`
- **Update flake**: `nix flake update`
- **Enter dev shell**: `nix develop`

### Testing & Validation
- **Flake validation**: `nix flake check --no-build`
- **Individual module test**: `nix eval .#nixosConfigurations.<host>.config.modules.<module>`
- **Config validation**: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run`
- **Module options check**: `nix eval .#nixosConfigurations.<host>.options.modules.<module> --apply "builtins.attrNames"`
- **VM testing**: `nix build ./#nixosConfigurations.vm.config.system.build.vm`

## Architecture & Organization

### Repository Structure
- **`flake.nix`**: Entry point defining inputs, outputs, and host configurations
- **`hosts/<hostname>/`**: Host-specific configurations
  - `configuration.nix` - NixOS system configuration
  - `hardware-configuration.nix` - Hardware-specific settings
  - `home.nix` - Home Manager user environment
- **`modules/`**: Reusable configuration modules organized by category
  - `cli/` - Command-line tools and utilities
  - `gui/` - Desktop applications and window managers
  - `secrets/` - Secret management (agenix)
  - `system/` - Legacy system configurations (being migrated)
- **`overlays/`**: Custom Nix overlays with numerical prefixes
  - `00-themes/` - Theme-related overlays (colors, fonts)
  - `10-wrappers/` - Application wrapper scripts
  - `20-scripts/` - Custom utility scripts
  - `90-apps/` - Application-specific overlays
- **`secrets/`**: Encrypted secrets managed with agenix

### NixOS vs Home Manager Decision Framework

#### Keep in NixOS (System-level)
- System services (daemons, background services)
- Hardware configuration (drivers, kernel modules)
- Security/permissions (sudo, polkit, groups)
- Network services (SSH, VPN, firewall)
- System-wide programs requiring root privileges
- Virtualization (libvirt, docker, etc.)

#### Move to Home Manager (User-level)
- User applications (browsers, editors, media players)
- Desktop applications without system integration needs
- User configuration files (dotfiles, themes)
- Development tools (unless system-wide needed)

#### Special Cases
- **Games**: Steam system integration stays in NixOS, individual games in Home Manager
- **Fonts**: System-wide fonts in NixOS, user preferences in Home Manager
- **Mixed apps**: Apps needing polkit/system integration stay in NixOS

## Code Style & Conventions

### Module Structure
- Use standard module pattern with `mkEnableOption` and `mkIf cfg.enable`
- Import order: `{ pkgs, config, lib, ... }:` then `with lib;`
- Group related options together, separate with blank lines
- Use descriptive option names with prefixes (e.g., `programs.neovim.enable`)

### Formatting
- Use 2-space indentation, no tabs
- Always format with `nix fmt` before committing
- Follow existing patterns in similar modules

### Host Configuration
- Username should be configurable per host (not hardcoded)
- Use `mkSystem` function for new hosts in `flake.nix`
- Each host imports `../../modules/default.nix` for module discovery

## Secret Management

### Agenix Setup
- Secrets managed with agenix, stored in `secrets/` directory
- SSH identity key required at `/home/dejanr/.ssh/agenix` (stored in 1Password)
- Must provide agenix SSH key before rebuilding system
- All secrets defined in `secrets/secrets.nix` with public keys

### Usage Pattern
```nix
# In module
age.secrets.secret_name.file = ../../../secrets/secret_name.age;

# Access in configuration
config.age.secrets.secret_name.path
```

## Development Workflows

### Adding New Hosts
1. Create `hosts/<hostname>/` directory
2. Add `configuration.nix`, `hardware-configuration.nix`, `home.nix`
3. Extend `nixosConfigurations` in `flake.nix` using `mkSystem`
4. Configure username and host-specific settings

### Creating New Modules
1. Use `modules/template.nix` as starting point
2. Place in appropriate category directory (`cli/`, `gui/`, etc.)
3. Follow standard module pattern with enable option
4. Import automatically discovered by `modules/default.nix`

### Adding New Overlays
1. Place in appropriate numbered directory:
   - `00-themes/` - Colors, fonts, themes
   - `10-wrappers/` - Application wrappers
   - `20-scripts/` - Utility scripts
   - `90-apps/` - Application packages
2. Follow existing overlay patterns
3. Automatically imported by flake overlay system

### Managing Secrets
1. Create encrypted file: `agenix -e secrets/new_secret.age`
2. Add to `secrets/secrets.nix` with public keys
3. Reference in modules via `age.secrets.new_secret.file`
4. Ensure agenix SSH key is available before rebuild

## Migration Notes

### Current State
- Legacy system configurations in `modules/system/roles/` being migrated
- Moving towards Home Manager for user-level configurations
- Some mixed configurations need splitting between NixOS and Home Manager

### Migration Priority
1. **Move to Home Manager**: `desktop.nix`, `development.nix`, `multimedia.nix`
2. **Keep in NixOS**: `services.nix`, `virtualisation.nix`
3. **Split**: `games.nix` (system integration vs user games), `fonts.nix`
