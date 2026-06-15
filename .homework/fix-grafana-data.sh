#!/usr/bin/env bash
# 修复 Prometheus 抓取 WSL 主机上的 huatuo，使 Grafana「宿主机视图」有曲线
# 用法（Ubuntu 终端，无需 sudo，前提是 huatuo-hw 已在跑）:
#   cd /mnt/c/Users/13249/Desktop/files/github/huatuo/.homework
#   sed -i 's/\r$//' fix-grafana-data.sh
#   bash fix-grafana-data.sh

set -eu

REPO="/mnt/c/Users/13249/Desktop/files/github/huatuo"
UNIT=huatuo-hw
HT="/tmp/huatuo-bamai"

WSL_IP="$(hostname -I | awk '{print $1}')"
HOST_NAME="$(hostname)"
PROM_CFG="$REPO/.homework/prometheus-wsl-scrape.yml"

if [ -z "$WSL_IP" ]; then
  echo "ERROR: cannot detect WSL IP"
  exit 1
fi

echo "==> WSL IP: $WSL_IP  hostname: $HOST_NAME"

if ! systemctl is-active --quiet "$UNIT" 2>/dev/null; then
  echo "ERROR: $UNIT not active. Run first: sudo bash run-experiments-wsl.sh"
  exit 1
fi

cd /tmp
if ! env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
  curl -sf --max-time 15 "http://127.0.0.1:19704/metrics" | grep -q 'huatuo_bamai_cpu_util_usr'; then
  echo "ERROR: huatuo metrics not on 127.0.0.1:19704"
  exit 1
fi
echo "==> huatuo metrics OK"

cat > "$PROM_CFG" <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]
  - job_name: huatuo
    static_configs:
      - targets: ["${WSL_IP}:19704", "host.docker.internal:19704"]
EOF

cd "$REPO"
docker compose -f build/docker/docker-compose.yml -f .homework/docker-compose.wsl-ports.yml up -d --force-recreate prometheus grafana
sleep 12

if docker exec grafana wget -qO- --timeout=5 http://prometheus:9090/-/healthy 2>/dev/null | grep -q OK; then
  echo "==> Grafana -> Prometheus 连通"
else
  echo "WARN: Grafana 无法访问 http://prometheus:9090"
fi

if docker exec prometheus wget -qO- --timeout=10 "http://${WSL_IP}:19704/metrics" | grep -q huatuo_bamai_cpu_util_usr; then
  echo "==> Prometheus 容器内探测成功: ${WSL_IP}:19704"
else
  echo "WARN: 容器内探测失败，请打开 http://${WSL_IP}:9090/targets 查看"
fi

echo ""
echo "=== 浏览器操作（用 Windows 打开）==="
echo "1. 确认抓取: http://${WSL_IP}:9090/targets  → job huatuo 为 UP"
echo "2. Grafana:   http://${WSL_IP}:3000  (admin / admin)"
echo "3. 大盘: Dashboards → 「Huatuo 状态 - 宿主机视图」（不要开「容器视图」）"
echo "4. 顶部变量: region = example , host = ${HOST_NAME}"
echo "5. 时间范围: Last 15 minutes，点 Refresh"
echo "6. Explore 可搜: huatuo_bamai_cpu_util_usr{region=\"example\"}"
echo ""
