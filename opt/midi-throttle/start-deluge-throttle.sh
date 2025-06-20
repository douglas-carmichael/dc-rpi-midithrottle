#!/bin/bash

log() {
  echo "[$(date +%H:%M:%S)] $1"
}

# === Auto-detect Deluge and VirMIDI clients ===
DELUGE_CLIENT=$(aconnect -l | grep "^client [0-9]*: 'Deluge'" | awk '{print $2}' | tr -d ':')
VIR_CLIENT=$(aconnect -l | grep "^client [0-9]*: 'Virtual Raw MIDI 0-0'" | awk '{print $2}' | tr -d ':')

# === Wait for BomeBox port to become available ===
for i in {1..10}; do
  BOMEBOX_PORT=$(aconnect -l | grep -B1 "BomeBox" | head -n1 | awk '{print $2}' | tr -d ':')

  if [[ -n "$BOMEBOX_PORT" ]]; then
    log "Detected BomeBox port: ${BOMEBOX_PORT}"
    break
  else
    log "Waiting for BomeBox port... (attempt $i)"
    sleep 1
  fi
done

if [[ -z "$BOMEBOX_PORT" ]]; then
  log "❌ BomeBox port not found. Aborting."
  exit 1
fi

# === Sanity check ===
if [[ -z "$DELUGE_CLIENT" || -z "$VIR_CLIENT" ]]; then
  log "Could not detect Deluge or VirMIDI 0-0. Aborting."
  exit 1
fi

log "Deluge client: $DELUGE_CLIENT"
log "VirMIDI 0-0 client: $VIR_CLIENT"
log "BomeBox client: $BOMEBOX_PORT"

# Clear all connections
aconnect -x

# === Core: Deluge MIDI 3 <-> VirMIDI 0-0 ===
aconnect "${DELUGE_CLIENT}:2" "${VIR_CLIENT}:0" && log "Connected Deluge MIDI 3 → VirMIDI 0-0"
aconnect "${VIR_CLIENT}:0" "${DELUGE_CLIENT}:2" && log "Connected VirMIDI 0-0 → Deluge MIDI 3"

# === Deluge MIDI 1 <-> BomeBox (with retry) ===
for i in {1..5}; do
  if aconnect "${DELUGE_CLIENT}:0" "${BOMEBOX_PORT}" && aconnect "${BOMEBOX_PORT}" "${DELUGE_CLIENT}:0"; then
    log "Connected Deluge MIDI 1 ⇄ BomeBox (attempt $i)"
    break
  else
    log "Connection attempt $i failed — retrying..."
    sleep 1
  fi
done

# === Start throttle script ===
log "Starting MIDI throttle script..."
exec /usr/bin/python3 /opt/midi-throttle/midi-throttle-latestonly.py
