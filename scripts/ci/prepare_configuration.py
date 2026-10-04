#!/usr/bin/env python3
"""Generate the Make.py build configuration used by CI.

Starts from the committed appstore configuration and substitutes the Telegram
API credentials supplied through the environment, so that the credentials of
the upstream app are never baked into our builds and never live in the repo.

Environment:
    TG_API_ID    API id registered at https://my.telegram.org/apps
    TG_API_HASH  API hash that belongs to TG_API_ID
"""

import argparse
import json
import os
import sys


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--base", required=True, help="configuration to start from")
    parser.add_argument("--output", required=True, help="where to write the result")
    args = parser.parse_args()

    api_id = os.environ.get("TG_API_ID", "").strip()
    api_hash = os.environ.get("TG_API_HASH", "").strip()

    missing = [name for name, value in (("TG_API_ID", api_id), ("TG_API_HASH", api_hash)) if not value]
    if missing:
        print(
            "error: missing repository secret(s): " + ", ".join(missing) + "\n"
            "Register an application at https://my.telegram.org/apps and add the values "
            "under Settings > Secrets and variables > Actions.",
            file=sys.stderr,
        )
        return 1

    if not api_id.isdigit():
        print("error: TG_API_ID must be a number", file=sys.stderr)
        return 1

    with open(args.base, encoding="utf-8") as handle:
        configuration = json.load(handle)

    configuration["api_id"] = api_id
    configuration["api_hash"] = api_hash

    with open(args.output, "w", encoding="utf-8") as handle:
        json.dump(configuration, handle, indent=4)
        handle.write("\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
