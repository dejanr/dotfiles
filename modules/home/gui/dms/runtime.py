import argparse
import fcntl
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile

JSON_FILES = ("settings.json", "plugin_settings.json")
GENERATED_FILES = tuple(
    Path("niri/dms") / (name + ".kdl")
    for name in "alttab binds colors cursor input layout outputs windowrules wpblur".split()
)


def load_object(path):
    value = json.loads(path.read_text())
    if not isinstance(value, dict):
        raise ValueError(f"Expected a JSON object: {path}")
    return value


def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=".desktop-profile-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(content)
        # Replace the link itself, never the checkout or store file it references.
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def archive(source, destination):
    if source.is_dir():
        if source.is_symlink():
            raise ValueError(f"Refusing a symlinked configuration directory: {source}")
        destination.mkdir(mode=0o700, parents=True, exist_ok=True)
        for child in source.iterdir():
            archive(child, destination / child.name)
    elif source.is_file():
        atomic_write(destination, source.read_bytes())
    elif source.is_symlink():
        destination.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        destination.symlink_to(os.readlink(source))
    elif source.exists():
        raise ValueError(f"Refusing a non-file configuration entry: {source}")


def prepare(profile, config_home, state_home):
    settings = {name: load_object(profile / name) for name in JSON_FILES}
    session_preferences = load_object(profile / "session-preferences.json")
    session_path = state_home / "dms/session.json"
    for relative in ("dms", "niri", "niri/dms"):
        directory = config_home / relative
        if directory.is_symlink() or (directory.exists() and not directory.is_dir()):
            raise ValueError(f"Expected a local configuration directory: {directory}")
    for relative in (*[Path("dms") / name for name in JSON_FILES], *GENERATED_FILES):
        target = config_home / relative
        if target.exists() and not target.is_file() and not target.is_symlink():
            raise ValueError(f"Expected a configuration file: {target}")

    state = state_home / "dms"
    state.mkdir(parents=True, exist_ok=True)
    lock = state / "desktop-profile.lock"
    with lock.open("a") as stream:
        lock.chmod(0o600)
        fcntl.flock(stream, fcntl.LOCK_EX)
        session = load_object(session_path) if session_preferences and session_path.exists() else {}
        marker = state / "desktop-profile-v1"
        fragments = config_home / "dms/config.d"
        initial = not marker.exists()
        if initial or fragments.exists() or fragments.is_symlink():
            backup_root = state / "config-backups"
            backup_root.mkdir(mode=0o700, exist_ok=True)
            backup_root.chmod(0o700)
            backup = Path(tempfile.mkdtemp(prefix="profile-", dir=backup_root))
            if initial:
                for relative in (*[Path("dms") / name for name in JSON_FILES], *GENERATED_FILES):
                    archive(config_home / relative, backup / relative)
                if session_preferences:
                    archive(session_path, backup / "session.json")
            archive(fragments, backup / "dms/config.d")
            print(f"Saved existing desktop configuration to {backup}", file=sys.stderr)

        if fragments.is_symlink():
            fragments.unlink()
        elif fragments.exists():
            shutil.rmtree(fragments)

        for name, value in settings.items():
            atomic_write(config_home / "dms" / name, (json.dumps(value, indent=2) + "\n").encode())
        if session_preferences:
            atomic_write(session_path, (json.dumps(session | session_preferences, indent=2) + "\n").encode())
        for relative in GENERATED_FILES:
            atomic_write(config_home / relative, b"")
        atomic_write(marker, b"Declared profile materialized; session state remains application-owned.\n")


def matches(expected, actual):
    if isinstance(expected, dict):
        return isinstance(actual, dict) and all(
            key in actual and matches(value, actual[key]) for key, value in expected.items()
        )
    if isinstance(expected, list):
        return isinstance(actual, list) and len(expected) == len(actual) and all(
            matches(left, right) for left, right in zip(expected, actual)
        )
    return type(expected) is type(actual) and expected == actual


def main():
    parser = argparse.ArgumentParser(description="Apply, inspect, or export the declared DMS desktop profile")
    parser.add_argument("--profile", type=Path, required=True)
    parser.add_argument("action", choices=("prepare", "check", "export"))
    args = parser.parse_args()
    config_home = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    state_home = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
    if not config_home.is_absolute() or not state_home.is_absolute():
        parser.error("XDG configuration and state paths must be absolute")
    try:
        if args.action == "prepare":
            prepare(args.profile, config_home, state_home)
            return
        profile = {name: load_object(args.profile / name) for name in JSON_FILES}
        current = {name: load_object(config_home / "dms" / name) for name in JSON_FILES}
        profile["session-preferences.json"] = load_object(args.profile / "session-preferences.json")
        current["session-preferences.json"] = load_object(state_home / "dms/session.json") if profile["session-preferences.json"] else {}
        if args.action == "export":
            selected = {
                name: {key: current[name].get(key, value) for key, value in expected.items()}
                for name, expected in profile.items()
            }
            print(json.dumps({
                "settings": selected["settings.json"],
                "plugins": selected["plugin_settings.json"],
                "sessionPreferences": selected["session-preferences.json"],
            }, indent=2))
        else:
            changed = [name for name, expected in profile.items() if not matches(expected, current[name])]
            if changed:
                raise ValueError("GUI preferences differ from the declared profile: " + ", ".join(changed))
            print("DMS preferences match the declared profile")
    except (OSError, ValueError) as error:
        parser.exit(1, f"desktop-config: {error}\n")


if __name__ == "__main__":
    main()
