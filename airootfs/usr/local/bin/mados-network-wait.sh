#!/usr/bin/env bash
# Wait for network interface to be up
for i in {1..30}; do
    if ip link show | grep -q "UP" && ip addr show | grep -q "inet "; then
        exit 0
    fi
    sleep 1
done
exit 1
