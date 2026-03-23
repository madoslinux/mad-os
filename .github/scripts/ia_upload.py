#!/usr/bin/env python3
import internetarchive
import os
import sys

version = os.environ["VERSION"]
iso_name = os.environ["ISO_NAME"]
build_date = os.environ["BUILD_DATE"]
access_key = os.environ["IA_ACCESS_KEY"]
secret_key = os.environ["IA_SECRET_KEY"]

item = internetarchive.get_item(f"mados-{version}")
item.upload(
    f"out/{iso_name}",
    metadata={
        "title": f"madOS {version}",
        "creator": "madoslinux",
        "date": build_date,
        "description": f"madOS {version} - AI-Orchestrated Arch Linux. Optimized for 1.9GB RAM with Intel Atom support.",
        "subject": "madOS;Arch Linux;Linux distribution;Wayland;Sway",
        "collection": "opensource",
        "license": "CC0-1.0",
    },
    access_key=access_key,
    secret_key=secret_key,
    checksum=True,
    delete=True,
)
