# Dotfiles

Nix-based system configurations for NixOS and macOS (nix-darwin).

## Architecture & Organization

### Repository Structure

- **`flake.nix`**: Entry point defining inputs, outputs, and host configurations
- **`hosts/<hostname>/`**: Host-specific configurations
  - `configuration.nix` - System configuration
  - `hardware-configuration.nix` - Hardware-specific settings (NixOS only)
  - `home.nix` - Home Manager user environment
- **`modules/`**: Reusable configuration modules (see Module Conventions)
- **`overlays/`**: Custom Nix overlays (numerical prefixes for load order when needed)
- **`secrets/`**: Encrypted secrets (see Secrets Management)

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

## Commands

```bash
# Darwin rebuild
nix run nix-darwin -- switch --flake .#

# NixOS rebuild
sudo nixos-rebuild switch --flake .#

# Remote rebuild
nixos-rebuild switch --flake .#<host> --target-host <ip>

# Check/format
nix flake check
nix fmt

# Dev shell (direnv)
direnv allow
# Run commands in the dev shell
# Example: direnv exec . agenix --version
```

## Pi-mono Extensions

Extensions live in `modules/home/cli/pi-mono/extensions`. See `modules/home/cli/pi-mono/extensions/README.md` for how to add a new extension, run lint/typecheck, and test with `pi -e`.

## Module Conventions

### Directory Structure

```
modules/
├── darwin/           # macOS-specific system modules
│   ├── default.nix   # Base darwin config
│   └── gui/          # GUI apps (aerospace, sketchybar, etc.)
├── home/             # Home Manager modules (cross-platform)
│   ├── default.nix   # Base home config, auto-imports modules
│   ├── apps/         # GUI applications (kitty)
│   ├── cli/          # CLI tools (git, zsh, tmux, nixvim, etc.)
│   ├── common/       # Shared packages
│   ├── gui/          # Desktop environment configs
│   ├── secrets/      # Agenix secrets for home
│   └── stylix/       # Theming
├── nixos/            # NixOS-specific system modules
│   ├── default.nix   # Base NixOS config
│   ├── roles/        # Composable system roles (desktop, dev, games, etc.)
│   └── secrets/      # System-level secrets
├── themes/           # Color schemes
└── template.nix      # Module template
```

### Module Pattern

All modules follow the template in `modules/template.nix`.

Options follow the path structure:

- `modules.home.cli.git` → `modules/home/cli/git.nix`
- `modules.apps.kitty` → `modules/home/apps/kitty.nix`
- `modules.nixos.roles.desktop` → `modules/nixos/roles/desktop.nix`
- `modules.darwin.gui.aerospace` → `modules/darwin/gui/aerospace.nix`

### Adding New Modules

Start small with a single file, then grow as needed:

1. **Simple module**: `modules/home/cli/tool.nix`
2. **Growing module**: Create `modules/home/cli/tool/` directory for related files
3. **Exclude from auto-import**: Add directory to `importsFrom` exclude list

```nix
# In parent default.nix:
imports = importsFrom {
  path = ./.;
  exclude = [ ./cli/tool ];  # Prevent double-import
};
```

## Adding a New Host

1. Create `hosts/<hostname>/` directory
2. Add `configuration.nix` with system config
3. Add `home.nix` with user module enables
4. For NixOS: add `hardware-configuration.nix`
5. Register in `flake.nix`:
   - NixOS: Add to `nixosConfigurations` using `mkSystem`
   - Darwin: Add to `darwinConfigurations`

## Secrets Management

Secrets are managed with [agenix](https://github.com/ryantm/agenix).

```
secrets/
├── secrets.nix           # Declares which keys can decrypt each secret
├── *.age                 # Encrypted secret files
```

**Adding a secret:**

1. Add entry to `secrets/secrets.nix` with public keys
2. Run `cd secrets && agenix -i ~/.ssh/agenix -e <name>.age`
3. Reference in modules via `config.age.secrets.<name>.path`

## Guidelines

- Follow existing Nix patterns in the codebase
- Use Home Manager for user-level configuration
- Prefer enabling existing modules over adding inline config
- Use roles for NixOS system-level feature bundles
- Keep host configs minimal - put reusable logic in modules
