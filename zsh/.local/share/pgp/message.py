#!/usr/bin/env python3
"""Interactive in-memory OpenPGP encryption, decryption, signing, and verification."""

from __future__ import annotations

import base64
import getpass
import importlib
import os
import subprocess
import sys
import warnings
from contextlib import contextmanager
from importlib.metadata import PackageNotFoundError, version
from pathlib import Path


DEPENDENCY_DIR = (
    Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    / "pgp-paste-tool"
    / "dependencies"
)
TERM_COLORS = sys.stdout.isatty()
WIDTH = 68


def styled(text: str, code: str) -> str:
    return f"\033[{code}m{text}\033[0m" if TERM_COLORS else text


def banner() -> None:
    title = "PGP TOOLKIT"
    subtitle = "Encrypt · Decrypt · Sign · Verify"
    print()
    print(styled("╭" + "─" * WIDTH + "╮", "36"))
    print(styled(f"│  🔐  {title:<{WIDTH - 6}}│", "1;36"))
    print(styled(f"│      {subtitle:<{WIDTH - 6}}│", "36"))
    print(styled("╰" + "─" * WIDTH + "╯", "36"))


def step(number: int, title: str, details: list[str]) -> None:
    print()
    print(styled(f"[{number}] {title}", "1;35"))
    for detail in details:
        print(styled(f"    {detail}", "2"))
    print(styled("    › ", "1;35"), end="", flush=True)


def status(message: str) -> None:
    print(styled(f"\n    ✓ {message}", "1;32"))


def result_panel(title: str, content: str, color: str) -> None:
    heading = f" {title} "
    remaining = max(1, WIDTH - len(heading))
    print()
    print(styled("╭─" + heading + "─" * remaining, f"1;{color}"))
    print()
    print(content.rstrip("\n"))
    print()
    print(styled("╰─" + "─" * WIDTH, f"1;{color}"))
    print(styled("  Done. Copy only the content between the lines above.", "2"))


def suppress_dependency_warnings() -> None:
    """Keep third-party cryptography migration notices out of the UI."""
    try:
        from cryptography.utils import CryptographyDeprecationWarning
    except ImportError:
        return
    warnings.filterwarnings("ignore", category=CryptographyDeprecationWarning)


def check_dependencies():
    """Check Python and install the pinned OpenPGP dependency when absent."""
    if sys.version_info < (3, 9):
        raise RuntimeError(
            f"Python 3.9+ is required; this is Python {sys.version.split()[0]}."
        )

    if DEPENDENCY_DIR.is_dir():
        sys.path.insert(0, str(DEPENDENCY_DIR))

    try:
        suppress_dependency_warnings()
        pgpy_version = version("PGPy")
        from pgpy import PGPKey, PGPMessage
    except (ImportError, PackageNotFoundError):
        print(styled("Installing the OpenPGP engine (first run only)...", "1;33"))
        DEPENDENCY_DIR.mkdir(parents=True, exist_ok=True)
        requirements = ["PGPy==0.6.0"]
        if sys.version_info >= (3, 13):
            requirements.append("standard-imghdr==3.13.0")
        try:
            subprocess.run(
                [
                    sys.executable,
                    "-m",
                    "pip",
                    "install",
                    "--quiet",
                    "--disable-pip-version-check",
                    "--target",
                    str(DEPENDENCY_DIR),
                    *requirements,
                ],
                check=True,
            )
        except (OSError, subprocess.CalledProcessError) as error:
            raise RuntimeError(
                "Could not install PGPy. Check your internet connection and pip setup."
            ) from error

        if str(DEPENDENCY_DIR) not in sys.path:
            sys.path.insert(0, str(DEPENDENCY_DIR))
        importlib.invalidate_caches()
        suppress_dependency_warnings()
        from pgpy import PGPKey, PGPMessage
        pgpy_version = version("PGPy")
    return PGPKey, PGPMessage, pgpy_version


def choose_action() -> str | None:
    print()
    print(styled("  Choose an action", "1;35"))
    options = [
        ("1", "Encrypt", "Use somebody's public key, or a private key"),
        ("2", "Decrypt", "Use your private key"),
        ("3", "Sign", "Create a clear-signed message with your private key"),
        ("4", "Verify", "Check a clear-signed message with a public key"),
        ("q", "Quit", "Exit without doing anything"),
    ]
    for number, name, description in options:
        print(
            f"    {styled(number, '1;36')}  "
            f"{styled(f'{name:<8}', '1')} "
            f"{styled(description, '2')}"
        )
    print()
    print(styled("    Selection › ", "1;35"), end="", flush=True)
    choice = sys.stdin.readline()
    if choice == "":
        raise EOFError("No menu selection was entered.")

    choice = choice.strip().lower()
    if choice in {"q", "quit", "exit"}:
        return None

    actions = {
        "1": "encrypt",
        "e": "encrypt",
        "encrypt": "encrypt",
        "2": "decrypt",
        "d": "decrypt",
        "decrypt": "decrypt",
        "3": "sign",
        "s": "sign",
        "sign": "sign",
        "4": "verify",
        "v": "verify",
        "verify": "verify",
    }
    if choice not in actions:
        raise ValueError("Choose 1, 2, 3, 4, or q.")
    return actions[choice]


def read_key(step_number: int, PGPKey, *, require_private: bool, purpose: str):
    accepted = "private key" if require_private else "public or private key"
    step(
        step_number,
        f"{purpose.upper()} KEY",
        [
            f"Paste the complete armored {accepted} below.",
            "The paste is visible and stops automatically at its END line.",
        ],
    )

    first = sys.stdin.readline()
    if first == "":
        raise EOFError("No key was pasted.")

    begin = first.strip()
    key_end_markers = {
        "-----BEGIN PGP PUBLIC KEY BLOCK-----": "-----END PGP PUBLIC KEY BLOCK-----",
        "-----BEGIN PGP PRIVATE KEY BLOCK-----": "-----END PGP PRIVATE KEY BLOCK-----",
    }
    if begin not in key_end_markers:
        raise ValueError("Expected an armored PGP public or private key.")

    end_marker = key_end_markers[begin]
    lines = [first]
    while lines[-1].strip() != end_marker:
        line = sys.stdin.readline()
        if line == "":
            raise EOFError(f"Input ended before {end_marker}.")
        lines.append(line)

    key, _ = PGPKey.from_blob("".join(lines))
    if require_private and key.is_public:
        raise ValueError(f"{purpose.capitalize()} requires a private key.")

    fingerprint = str(key.fingerprint)
    grouped_fingerprint = " ".join(
        fingerprint[index : index + 4] for index in range(0, len(fingerprint), 4)
    )
    key_kind = "Public key" if key.is_public else "Private key"
    status(f"{key_kind} loaded · {grouped_fingerprint}")
    return key


def read_plaintext(step_number: int, purpose: str) -> str:
    step(
        step_number,
        "PLAINTEXT",
        [
            f"Type or paste one line to {purpose}.",
            "The operation starts immediately when you press Return.",
        ],
    )
    text = sys.stdin.readline()
    if text == "":
        raise EOFError("No plaintext was entered.")
    if not text.strip():
        raise ValueError("The plaintext was empty.")
    return text


def read_armored_block(
    step_number: int,
    *,
    title: str,
    begin_marker: str,
    end_marker: str,
) -> str:
    step(
        step_number,
        title,
        [
            f"Paste from {begin_marker}",
            f"through {end_marker}; it stops automatically.",
        ],
    )
    first = sys.stdin.readline()
    if first == "":
        raise EOFError(f"No {title.lower()} was pasted.")
    if first.strip() != begin_marker:
        raise ValueError(f"Expected {begin_marker}.")

    lines = [first]
    while lines[-1].strip() != end_marker:
        line = sys.stdin.readline()
        if line == "":
            raise EOFError(f"Input ended before {end_marker}.")
        lines.append(line)
    return "".join(lines)


@contextmanager
def unlocked_key(key):
    if not key.is_protected:
        yield key
        return

    passphrase = getpass.getpass("    Private-key passphrase › ")
    try:
        with key.unlock(passphrase):
            yield key
    finally:
        passphrase = ""


def message_text(value) -> str:
    if isinstance(value, (bytes, bytearray, memoryview)):
        raw = bytes(value)
        try:
            return raw.decode("utf-8")
        except UnicodeDecodeError:
            encoded = base64.b64encode(raw).decode("ascii")
            return "[Binary result shown as Base64]\n" + encoded
    return str(value)


def normalize_armored_message(armored_message: str) -> str:
    """Repair two frequent paste errors without altering valid armor."""
    text = armored_message.strip()

    if "\\n" in text and "\n" not in text:
        text = text.replace("\\r\\n", "\n").replace("\\n", "\n")

    lines = text.splitlines()
    if lines and lines[0].strip() == "-----BEGIN PGP MESSAGE-----":
        if len(lines) > 1 and lines[1].strip() and ":" not in lines[1]:
            lines.insert(1, "")
    return "\n".join(lines) + "\n"


def encrypt_action(PGPKey, PGPMessage) -> None:
    key = read_key(2, PGPKey, require_private=False, purpose="recipient")
    plaintext = read_plaintext(3, "encrypt")
    recipient = key if key.is_public else key.pubkey
    print(styled("\n  Encrypting...", "1;33"))
    encrypted = recipient.encrypt(PGPMessage.new(plaintext))
    result_panel("ENCRYPTED PGP MESSAGE", str(encrypted), "36")


def decrypt_action(PGPKey, PGPMessage) -> None:
    key = read_key(2, PGPKey, require_private=True, purpose="decryption")
    armored = read_armored_block(
        3,
        title="ENCRYPTED MESSAGE",
        begin_marker="-----BEGIN PGP MESSAGE-----",
        end_marker="-----END PGP MESSAGE-----",
    )
    print(styled("\n  Decrypting...", "1;33"))
    message = PGPMessage.from_blob(normalize_armored_message(armored))
    with unlocked_key(key):
        decrypted = key.decrypt(message).message
    rendered = message_text(decrypted)
    title = (
        "DECRYPTED SIGNED MESSAGE"
        if rendered.lstrip().startswith("-----BEGIN PGP SIGNED MESSAGE-----")
        else "DECRYPTED PLAINTEXT"
    )
    result_panel(title, rendered, "32")


def sign_action(PGPKey, PGPMessage) -> None:
    key = read_key(2, PGPKey, require_private=True, purpose="signing")
    plaintext = read_plaintext(3, "sign")
    print(styled("\n  Signing...", "1;33"))
    message = PGPMessage.new(plaintext, cleartext=True)
    with unlocked_key(key):
        signature = key.sign(message)
    message |= signature
    result_panel("CLEAR-SIGNED PGP MESSAGE", str(message), "36")


def verify_action(PGPKey, PGPMessage) -> bool:
    key = read_key(2, PGPKey, require_private=False, purpose="verification")
    armored = read_armored_block(
        3,
        title="SIGNED MESSAGE",
        begin_marker="-----BEGIN PGP SIGNED MESSAGE-----",
        end_marker="-----END PGP SIGNATURE-----",
    )
    print(styled("\n  Verifying...", "1;33"))
    message = PGPMessage.from_blob(armored)
    verification_key = key if key.is_public else key.pubkey
    with warnings.catch_warnings():
        warnings.filterwarnings(
            "ignore",
            message="TODO:.*",
            category=UserWarning,
            module="pgpy.pgp",
        )
        valid = bool(verification_key.verify(message))

    if valid:
        result_panel("✓ VALID SIGNATURE · PLAINTEXT", message_text(message.message), "32")
    else:
        result_panel(
            "✗ INVALID SIGNATURE",
            "The signature does not match this message and key.",
            "31",
        )
    return valid


def main() -> int:
    try:
        banner()
        PGPKey, PGPMessage, pgpy_version = check_dependencies()
        print(
            styled(
                f"  ✓ Ready  ·  Python {sys.version.split()[0]}  ·  PGPy {pgpy_version}",
                "1;32",
            )
        )

        action = choose_action()
        if action is None:
            print(styled("\n  Goodbye.", "2"))
            return 0

        if action == "encrypt":
            encrypt_action(PGPKey, PGPMessage)
        elif action == "decrypt":
            decrypt_action(PGPKey, PGPMessage)
        elif action == "sign":
            sign_action(PGPKey, PGPMessage)
        elif action == "verify":
            return 0 if verify_action(PGPKey, PGPMessage) else 2
        return 0
    except (EOFError, RuntimeError, ValueError) as error:
        print(styled(f"\n  ✗ Error: {error}", "1;31"), file=sys.stderr)
        return 1
    except Exception as error:
        print(
            styled(f"\n  ✗ OpenPGP operation failed: {error}", "1;31"),
            file=sys.stderr,
        )
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
