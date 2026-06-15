#!/usr/bin/env bash
# 电脑/WSL 重启后一键恢复：观测栈 + huatuo + Prometheus 抓取修复
# 用法:
#   cd /mnt/c/Users/13249/Desktop/files/github/huatuo/.homework
#   sed -i 's/\r$//' restart-after-reboot.sh
#   sudo bash restart-after-reboot.sh

set -eu

REPO="/mnt/c/Users/13249/Desktop/files/github/huatuo"
HT="/tmp/huatuo-bamai"
UNIT=huatuo-hw

echo "[1/4] Docker 观测栈 (ES / Prometheus / Grafana)..."
cd "$REPO"
docker compose -f build/docker/docker-compose.yml -f .homework/docker-compose.wsl-ports.yml up -d elasticsearch prometheus grafana

echo "[2/4] 准备 huatuo-bamai（若 /tmp 下无二进制则从镜像提取）..."
if [ ! -x "$HT/bin/huatuo-bamai" ]; then
  docker rm -f ht-extract 2>/dev/null || true
  docker create --name ht-extract huatuo/huatuo-bamai:latest
  rm -rf "$HT"
  docker cp ht-extract:/home/huatuo-bamai "$HT"
  docker rm ht-extract
fi

echo "[3/4] 启动 huatuo-hw (systemd)..."
systemctl stop "$UNIT" 2>/dev/null || true
systemd-run --unit="$UNIT" --property=KillMode=process \
  "$HT/bin/huatuo-bamai" \
  --region example \
  --config-dir "$HT/conf" \
  --bpf-dir "$HT/bpf" \
  --tools-bin-dir "$HT/bin" \
  --config huatuo-bamai.conf \
  --disable-storage
sleep 12
systemctl is-active "$UNIT"

echo "[4/4] 修复 Prometheus 抓取 + 验证..."
sed -i 's/\r$//' "$REPO/.homework/fix-grafana-data.sh"
bash "$REPO/.homework/fix-grafana-data.sh"

echo ""
echo "=== 完成 ==="
WSL_IP="$(hostname -I | awk '{print $1}')"
echo "Metrics:  http://${WSL_IP}:19704/metrics"
echo "Prometheus: http://${WSL_IP}:9090/targets"
echo "Grafana:    http://${WSL_IP}:3000  (admin/admin)"
echo "大盘: Huatuo 状态 - 宿主机视图 | region=example | host=$(hostname)"
