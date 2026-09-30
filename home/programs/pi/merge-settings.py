"""Deploy shared Pi preferences while retaining local provider and runtime settings."""

import json
import os
from pathlib import Path
import sys
import tempfile


PROVIDER_SETTINGS = {
    "defaultProvider", "defaultModel", "enabledModels", "modelThinkingLevels", "providers"
}


def read_object(path):
    value = json.loads(path.read_text()) if path.exists() else {}
    if not isinstance(value, dict):
        raise ValueError(f"Expected a JSON object in {path}")
    return value


def validate_shared(settings):
    if PROVIDER_SETTINGS.intersection(settings):
        raise ValueError("Shared Pi preferences must not contain provider/model settings")


def reconcile(local, previous, shared):
    """Replace managed leaves, remove retired leaves, and keep unmanaged siblings."""
    result = dict(local)
    for key in previous.keys() | shared.keys():
        before = previous.get(key)
        after = shared.get(key)
        current = result.get(key)
        if isinstance(current, dict) and isinstance(before, dict) and (
            key not in shared or isinstance(after, dict)
        ):
            nested = reconcile(current, before, after if key in shared else {})
            if nested or key in shared:
                result[key] = nested
            else:
                result.pop(key, None)
        elif key not in shared:
            result.pop(key, None)
        elif isinstance(current, dict) and isinstance(after, dict):
            result[key] = reconcile(current, {}, after)
        else:
            result[key] = after
    return result


def write_object(path, value):
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(value, stream, ensure_ascii=False, indent=2)
            stream.write("\n")
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def deploy(source, agent_directory):
    shared = read_object(source)
    validate_shared(shared)
    agent_directory.mkdir(parents=True, exist_ok=True)
    settings_path = agent_directory / "settings.json"
    state_path = agent_directory / ".dotfiles-settings.json"
    # Match Pi's proper-lockfile lock directory so an active settings writer
    # cannot race activation. Leave a held/stale lock for its owner to resolve.
    lock = agent_directory / "settings.json.lock"
    try:
        lock.mkdir()
    except FileExistsError:
        raise RuntimeError(f"Pi settings are locked; retry activation after resolving {lock}") from None
    try:
        if settings_path.is_symlink() or state_path.is_symlink():
            raise ValueError("Pi settings and deployment state must be regular writable files")
        local = read_object(settings_path)
        previous = read_object(state_path)
        validate_shared(previous)
        merged = reconcile(local, previous, shared)
        if not settings_path.exists() or merged != local:
            write_object(settings_path, merged)
        if not state_path.exists() or previous != shared:
            write_object(state_path, shared)
    finally:
        lock.rmdir()


if __name__ == "__main__":
    deploy(Path(sys.argv[1]), Path(sys.argv[2]))
