#!/usr/bin/python3
import mido
import time
import threading

# Port config
port_name = 'Virtual Raw MIDI 0-0:VirMIDI 0-0 16:0'
interval = 0.05  # 50ms = max 20 FPS

# Open I/O
in_port = mido.open_input(port_name)
out_port = mido.open_output(port_name)

# Shared state for the latest SysEx
latest_sysex = None
lock = threading.Lock()

def send_loop():
    global latest_sysex
    while True:
        time.sleep(interval)
        with lock:
            if latest_sysex:
                out_port.send(latest_sysex)
                latest_sysex = None

def receive_loop():
    global latest_sysex
    for msg in in_port:
        if msg.type == 'sysex':
            with lock:
                latest_sysex = msg  # Replace previous SysEx
        else:
            out_port.send(msg)  # Send non-SysEx immediately

# Launch threads
threading.Thread(target=send_loop, daemon=True).start()
threading.Thread(target=receive_loop, daemon=True).start()

print("Deluge display throttle (last-only strategy) running under systemd. Press Ctrl+C to stop manually.")
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("Shutting down.")

