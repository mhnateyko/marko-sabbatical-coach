#!/bin/bash
# Dev server for Marko's Sabbatical Coach
# Access from iPhone: open http://<your-mac-ip>:8080/sabbatical_coach.html on same WiFi

PORT=8080
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "📱 Sabbatical Coach — Local Server"
echo "===================================="
echo ""

# Get LAN IP
LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "unknown")

echo "  Local:   http://localhost:$PORT/sabbatical_coach.html"
if [ "$LAN_IP" != "unknown" ]; then
  echo "  iPhone:  http://$LAN_IP:$PORT/sabbatical_coach.html"
  echo ""
  echo "  📲 Same WiFi required for iPhone access"
fi
echo ""
echo "  Press Ctrl+C to stop"
echo ""

cd "$DIR"
python3 -m http.server $PORT
