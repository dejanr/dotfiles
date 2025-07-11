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
- **`modules/`**: Reusable configuration modules organized by context
  - `home/` - Home Manager modules (user-level configuration)
    - Organized into logical categories for related functionality
    - `default.nix` - Auto-discovery mechanism for module loading
  - `system/` - NixOS modules (system-level configuration)
    - System-level modules with appropriate grouping
    - Auto-import system for module management
- **`overlays/`**: Custom Nix overlays with logical organization
  - Numerical prefixes for load order when needed
  - Categorized by purpose and functionality
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

### Module Namespaces
- **Namespace mapping**: Module namespaces should reflect the directory structure
- **NixOS modules**: System-level configuration under `modules.system.*`
- **Home Manager modules**: User-level configuration under `modules.home.*`
- **Category organization**: Group related modules in logical directories
- **File naming**: Use descriptive names that match their purpose
- **Namespace pattern**: `modules.<category>.<name>` where category matches directory structure
- **Consistency**: Maintain consistent naming patterns across similar module types

### Formatting
- Use 2-space indentation, no tabs
- Always format with `nix fmt` before committing
- Follow existing patterns in similar modules

### Host Configuration
- Username should be configurable per host (not hardcoded)
- Use `mkSystem` function for new hosts in `flake.nix`
- Each host imports `../../modules/home/default.nix` for Home Manager module discovery
- NixOS system modules are auto-imported via flake configuration

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
2. **Home Manager modules**: 
   - Place in appropriate category directory under `modules/home/`
   - Choose logical categories that group related functionality
   - Use namespace that matches directory structure: `modules.<category>.<name>`
   - Ensure auto-discovery mechanism can find the module
3. **NixOS modules**: 
   - Place system-level modules under `modules/system/`
   - Use appropriate namespace reflecting the module's purpose
   - Add to auto-import system if available
4. Follow standard module pattern with enable option and consistent structure

### Adding New Overlays
1. **Categorization**: Place overlays in logically organized directories
2. **Naming convention**: Use consistent naming that reflects overlay purpose
3. **Priority ordering**: Use numerical prefixes if load order matters
4. **Pattern consistency**: Follow existing overlay patterns and structure
5. **Auto-import**: Ensure overlays are discoverable by the import system

### Managing Secrets
1. Create encrypted file: `agenix -e secrets/new_secret.age`
2. Add to `secrets/secrets.nix` with public keys
3. Reference in modules via `age.secrets.new_secret.file`
4. Ensure agenix SSH key is available before rebuild

## Migration Guidelines

### General Migration Principles
- Evaluate each configuration for appropriate placement (system vs user level)
- Follow the NixOS vs Home Manager decision framework
- Maintain backward compatibility during transitions
- Test thoroughly to ensure no functionality is lost

### Module Migration Pattern
1. **Add enable option**: Use `mkEnableOption` and `mkIf cfg.enable` pattern
2. **Add to auto-import**: Ensure modules are discoverable by import systems
3. **Update configurations**: Replace manual imports with enable-based configuration
4. **Test thoroughly**: Ensure no conflicts between different module types

### Configuration Splitting Guidelines
- **System integration**: Keep components requiring root privileges in NixOS
- **User preferences**: Move user-specific configurations to Home Manager
- **Mixed configurations**: Split appropriately based on functionality
- **Gradual migration**: Migrate incrementally to minimize disruption

### Module Organization Principles
- **Clear separation**: Separate user-level and system-level configurations
- **Home Manager modules**: User-level configuration organized by logical categories
  - Auto-discovery mechanism for seamless module loading
  - Namespace structure that reflects directory organization
- **NixOS modules**: System-level configuration with appropriate grouping
  - Auto-import system for easy module management
  - Enable-based configuration pattern for consistency
- **Conflict prevention**: Avoid namespace collisions between different module types
- **Consistent structure**: Maintain uniform patterns across all module types
