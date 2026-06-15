#!/usr/bin/env bash
# HUATUO 实验脚本 — 在 Ubuntu 终端执行:
#   cd /mnt/c/Users/13249/Desktop/files/github/huatuo/.homework
#   sed -i 's/\r$//' run-experiments-wsl.sh
#   sudo bash run-experiments-wsl.sh

set -eu

REPO="/mnt/c/Users/13249/Desktop/files/github/huatuo"
HT="/tmp/huatuo-bamai"
UNIT=huatuo-hw

echo "[1/5] Starting observability stack (WSL port mapping + Prometheus scrape fix)..."
cd "$REPO"
docker compose -f build/docker/docker-compose.yml -f .homework/docker-compose.wsl-ports.yml up -d elasticsearch prometheus grafana

echo "[2/5] Preparing huatuo-bamai..."
if [ ! -x "$HT/bin/huatuo-bamai" ]; then
  docker rm -f ht-extract 2>/dev/null || true
  docker create --name ht-extract huatuo/huatuo-bamai:latest
  rm -rf "$HT"
  docker cp ht-extract:/home/huatuo-bamai "$HT"
  docker rm ht-extract
fi

echo "[3/5] Starting huatuo via systemd (avoid SIGHUP when shell exits)..."
systemctl stop "$UNIT" 2>/dev/null || true
systemd-run --unit="$UNIT" --property=KillMode=process \
  "$HT/bin/huatuo-bamai" \
  --region example \
  --config-dir "$HT/conf" \
  --bpf-dir "$HT/bpf" \
  --tools-bin-dir "$HT/bin" \
  --config huatuo-bamai.conf \
  --disable-storage
sleep 10
systemctl is-active "$UNIT"

echo "[4/5] Verifying OOM collector..."
# IMPORTANT: cd /tmp; disable proxy (WSL localhost proxy breaks 127.0.0.1)
cd /tmp
env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
  curl -s --max-time 30 http://127.0.0.1:19704/metrics | grep -i oom | head -10
journalctl -u "$UNIT" --no-pager | grep -a "start tracing oom" | tail -1

echo "[5/5] Verifying BPF object..."
readelf -S "$HT/bpf/oom.o" | grep -i oom

echo "Done. Service: systemctl status $UNIT"
echo "Metrics: curl -s --max-time 30 http://127.0.0.1:19704/metrics | grep -i oom"
