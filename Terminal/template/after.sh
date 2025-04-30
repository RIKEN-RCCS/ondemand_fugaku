#!/usr/bin/env bash

echo "$(date): Waiting for port '${PORT}' to open..."

if wait_until_port_used "0.0.0.0:${PORT}" 600; then
  echo "$(date): Discovered process listening on port '${PORT}'!"
else
  echo "$(date): Timed out waiting port ${PORT} to become open!"
  clean_up 1
fi

sleep 2
