#!/usr/bin/env bash
if command -v ufw &>/dev/null; then
    ufw --force enable 2>/dev/null || true
fi