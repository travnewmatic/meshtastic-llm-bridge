# Meshtastic-LLM Bridge — sidecar image for the Hermes pod.
#
# Talks to a Meshtastic radio either over TCP to a LAN node (set MESHTASTIC_HOST,
# e.g. 192.168.68.63) or over USB serial (set MESHTASTIC_DEVICE_PATH). In the
# Hermes pod the radio is a LAN node, so MESHTASTIC_HOST is the path that's used.
#
# Config is injected via environment variables (see README); a .env file in the
# working dir is optional and read by python-dotenv if present.
FROM python:3.13-slim

# Run as a non-root user (sidecar best practice).
RUN useradd --create-home --shell /usr/sbin/nologin bridge

WORKDIR /app

# Install dependencies first for Docker layer caching.
# meshtastic[cli] is pinned to the version whose TCP/serial API is verified;
# pypubsub is the pub/sub bus the bridge subscribes to for inbound text.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Application code + the Taiwan disaster tools (shelter data, weather, geo utils)
# that bridge.py resolves relative to its working directory.
COPY bridge.py .
COPY tools/ ./tools/

USER bridge

# The bridge connects, subscribes to inbound text, and serves LLM replies; it
# runs forever, so it is the container's main process.
CMD ["python3", "bridge.py"]
