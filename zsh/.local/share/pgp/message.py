#!/usr/bin/env python3
"""Encrypt or decrypt pasted text without storing keys or messages on disk."""

from __future__ import annotations

import base64
import getpass
import importlib
import os
import subprocess
import sys
import warnings
from importlib.metadata import PackageNotFoundError, version
from pathlib import Path


END_MARKER = "::END::"
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
    title = "PGP PASTE TOOL"
    subtitle = "Encrypt or decrypt without saving your input"
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
    print(content.rstrip("\n"))
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
                    "PGPy==0.6.0",
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


def read_private_key() -> str:
    step(
        1,
        "PRIVATE KEY",
        [
            "Paste the complete armored private key below.",
            "It will be visible and stops automatically at its END line.",
        ],
    )
    lines: list[str] = []
    while True:
        line = sys.stdin.readline()
        if line == "":
            raise EOFError("Input ended before the private key was complete.")
        lines.append(line)
        if line.strip() == "-----END PGP PRIVATE KEY BLOCK-----":
            break
    return "".join(lines)


def read_payload() -> str:
    step(
        2,
        "MESSAGE",
        [
            "Paste plaintext to encrypt, or an armored PGP message to decrypt.",
            f"PGP stops automatically; finish plaintext with {END_MARKER}.",
        ],
    )
    first = sys.stdin.readline()
    if first == "":
        raise EOFError("No message was pasted.")

    lines: list[str] = [first]
    is_armored_message = first.strip() == "-----BEGIN PGP MESSAGE-----"
    while True:
        line = sys.stdin.readline()
        if line == "":
            expected = "the END PGP MESSAGE line" if is_armored_message else END_MARKER
            raise EOFError(f"Input ended before {expected}.")
        if is_armored_message:
            lines.append(line)
            if line.strip() == "-----END PGP MESSAGE-----":
                break
        elif line.rstrip("\r\n") == END_MARKER:
            break
        else:
            lines.append(line)
    return "".join(lines)


def decrypt_text(key, armored_message: str, PGPMessage) -> str:
    armored_message = normalize_armored_message(armored_message)
    message = PGPMessage.from_blob(armored_message)

    if key.is_protected:
        passphrase = getpass.getpass("Private-key passphrase: ")
        with key.unlock(passphrase):
            decrypted = key.decrypt(message).message
        passphrase = ""
    else:
        decrypted = key.decrypt(message).message

    if isinstance(decrypted, bytes):
        try:
            return decrypted.decode("utf-8")
        except UnicodeDecodeError:
            encoded = base64.b64encode(decrypted).decode("ascii")
            return "[Binary result shown as Base64]\n" + encoded
    return str(decrypted)


def normalize_armored_message(armored_message: str) -> str:
    """Repair two frequent paste errors without altering valid armor."""
    text = armored_message.strip()

    # Some chat/JSON copies contain visible backslash-n sequences.
    if "\\n" in text and "\n" not in text:
        text = text.replace("\\r\\n", "\n").replace("\\n", "\n")

    lines = text.splitlines()
    if lines and lines[0].strip() == "-----BEGIN PGP MESSAGE-----":
        # OpenPGP armor requires a blank line between its optional headers and
        # Base64 body. Add it when a paste omitted it and has no armor headers.
        if len(lines) > 1 and lines[1].strip() and ":" not in lines[1]:
            lines.insert(1, "")
    return "\n".join(lines) + "\n"


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
        private_key_text = read_private_key()
        key, _ = PGPKey.from_blob(private_key_text)
        if key.is_public:
            raise ValueError("That is a public key; decryption requires a private key.")
        fingerprint = str(key.fingerprint)
        grouped_fingerprint = " ".join(
            fingerprint[index : index + 4] for index in range(0, len(fingerprint), 4)
        )
        status(f"Key loaded · {grouped_fingerprint}")

        payload = read_payload()
        if not payload:
            raise ValueError("The message was empty.")

        if payload.lstrip().startswith("-----BEGIN PGP MESSAGE-----"):
            print(styled("\n  Decrypting...", "1;33"))
            decrypted = decrypt_text(key, payload, PGPMessage)
            result_panel("DECRYPTED PLAINTEXT", decrypted, "32")
        else:
            print(styled("\n  Encrypting...", "1;33"))
            encrypted = key.pubkey.encrypt(PGPMessage.new(payload))
            result_panel("ENCRYPTED PGP MESSAGE", str(encrypted), "36")
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
    try:
        raise SystemExit(main())
    finally:
        # Best-effort cleanup of Python references. The process exits immediately
        # afterward; no pasted key or message is deliberately written to disk.
        for variable in ("private_key_text", "payload", "key"):
            globals().pop(variable, None)


