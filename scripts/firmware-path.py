# Read Cargo's JSON configuration from stdin and print TREZOR_FIRMWARE.

import json
import os
import sys

setting = json.load(sys.stdin).get("env", {}).get("TREZOR_FIRMWARE", {})

if isinstance(setting, str):
    setting = {"value": setting}

# Use an empty value when neither source defines it.
trezor_firmware = setting.get("value", "")

# The environment takes precedence unless the Cargo setting has force = true.
if not setting.get("force", False):
    trezor_firmware = os.environ.get("TREZOR_FIRMWARE", trezor_firmware)
    
print(trezor_firmware)
