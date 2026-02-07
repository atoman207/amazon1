#!/bin/bash
# Start Cloudflare Tunnel to expose the backend API over HTTPS.
# Run this on your VPS alongside run_api.sh.
# The output will show a URL like https://xyz-abc.trycloudflare.com
# Use https://YOUR_TUNNEL_URL/api as VITE_API_BASE in Vercel.

echo "Starting Cloudflare Tunnel for http://localhost:8000"
echo "Copy the HTTPS URL from the output and use it as VITE_API_BASE in Vercel."
echo ""

exec cloudflared tunnel --url http://localhost:8000
