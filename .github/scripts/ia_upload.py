#!/usr/bin/env python3
import os
import sys
import time

import internetarchive

VERSION = os.environ["VERSION"]
ISO_NAME = os.environ["ISO_NAME"]
BUILD_DATE = os.environ["BUILD_DATE"]
IA_ACCESS_KEY = os.environ["IA_ACCESS_KEY"]
IA_SECRET_KEY = os.environ["IA_SECRET_KEY"]

ITEM = internetarchive.get_item(f"mados-{VERSION}")
ISO_PATH = f"out/{ISO_NAME}"
ISO_SIZE = os.path.getsize(ISO_PATH)
ISO_SIZE_MB = ISO_SIZE / (1024 * 1024)

print(f"Uploading {ISO_NAME} ({ISO_SIZE_MB:.1f} MB) to Internet Archive as 'mados-{VERSION}'")
print("Delete existing files: YES (file will be replaced)")
print("Checksum verification: YES")
print("---")

START_TIME = time.time()

response = ITEM.upload(
    ISO_PATH,
    metadata={
        "title": f"madOS {VERSION}",
        "creator": "madoslinux",
        "date": BUILD_DATE,
        "description": f"madOS {VERSION} - AI-Orchestrated Arch Linux. Optimized for 1.9GB RAM with Intel Atom support.",
        "subject": "madOS;Arch Linux;Linux distribution;Sway;X11",
        "collection": "opensource",
        "license": "CC0-1.0",
    },
    access_key=IA_ACCESS_KEY,
    secret_key=IA_SECRET_KEY,
    checksum=True,
    delete=True,
    verbose=True,
)

ELAPSED = time.time() - START_TIME
SPEED_MBPS = ISO_SIZE_MB / ELAPSED if ELAPSED > 0 else 0

print("---")
if response:
    print(f"Upload completed successfully in {ELAPSED:.1f}s ({SPEED_MBPS:.1f} MB/s)")
    IA_URL = f"https://archive.org/download/mados-{VERSION}/{ISO_NAME}"
    print(f"URL: {IA_URL}")
else:
    print(f"Upload failed: {response}")
    sys.exit(1)
