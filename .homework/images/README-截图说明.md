# 截图说明（Ubuntu 终端）

当前 WSL 上 **huatuo-hw** 服务若仍在运行，可直接截图；若已停，按下方「一键命令」重新拉起。

## 电脑重启后（优先用这个）

```bash
cd /mnt/c/Users/13249/Desktop/files/github/huatuo/.homework
sed -i 's/\r$//' restart-after-reboot.sh
sudo bash restart-after-reboot.sh
```

会依次：拉起 Docker 观测栈 → 启动 `huatuo-hw` → 修复 Prometheus 抓取 → 打印 Grafana/Prometheus 地址。

## 一键命令（复制到 Ubuntu 终端）

```bash
cd /mnt/c/Users/13249/Desktop/files/github/huatuo/.homework
sed -i 's/\r$//' run-experiments-wsl.sh
sudo bash run-experiments-wsl.sh
```

或仅验证指标（**必须先 cd /tmp**，不要在 `.homework` 目录下 curl）：

```bash
cd /tmp
# 必须去掉代理，否则 curl 会卡住无输出
env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
  curl -s --max-time 30 http://127.0.0.1:19704/metrics | grep -i oom

sudo systemctl status huatuo-hw --no-pager
```

脚本跑完时 **[4/5] 已打印 oom 指标**，可直接截那一段，不必再手动 curl。

## 必截 3 张

| 文件 | 内容 |
|------|------|
| `03-cursor-chat.png` | Cursor 中阅读 OOM 源码的对话 |
| `04-cursor-code-oom.png` | `core/events/oom.go` 与 `bpf/oom.c` |
| `05-cursor-terminal-wsl.png` | 上面 `curl \| grep oom` 与 `systemctl status huatuo-hw` |
| `06-metrics-endpoint.png` | 浏览器打开 `http://<WSL_IP>:19704/metrics`（已写入报告） |
| `07-prometheus-targets.png` | Prometheus `http://<WSL_IP>:9090/targets`，huatuo 为 UP（已写入报告） |
| `08-grafana-host-metrics.png` | Grafana「Metric 大盘 - 宿主机视图」，region=example、host=zzz（已写入报告） |

## Grafana 可视化（:3000）

**为什么之前 `http://172.28.161.81:3000` 打不开？**

官方 `docker-compose` 使用 `network_mode: host`。在 **Docker Desktop + WSL** 下，Grafana 监听在 Docker 内部网络栈，**不会**出现在 WSL 的 `ss -lntp` 里，Windows 用 WSL IP 也访问不到。

**处理：** 使用本目录的端口映射覆盖文件重新拉起：

```bash
cd /mnt/c/Users/13249/Desktop/files/github/huatuo
docker compose -f build/docker/docker-compose.yml -f .homework/docker-compose.wsl-ports.yml up -d grafana prometheus elasticsearch
```

然后在 **Ubuntu 里** 确认：

```bash
ss -lntp | grep 3000    # 应能看到 *:3000
curl -s http://127.0.0.1:3000/api/health   # 应返回 200
```

浏览器访问（二选一）：

- 在 **WSL/Ubuntu 图形环境**：`http://127.0.0.1:3000`（最稳）
- 在 **Windows**：`http://172.28.161.81:3000`（`wsl hostname -I` 查 IP）

默认账号：`admin` / `admin`。

若提示用户名或密码错误（常见原因：以前启动过 Grafana，数据卷里已是旧密码），在 Ubuntu 执行：

```bash
docker exec grafana grafana cli admin reset-admin-password admin
```

然后用 **admin / admin** 登录。

若页面一直转圈 “Loading Grafana”，多等 1～2 分钟（首次装插件较慢）或刷新；仍不行则只用 **Prometheus** `http://<WSL_IP>:9090` 查指标。

### Grafana 变量旁红三角 / 大盘 No data（已修复）

**原因：** 端口映射版 compose 里 Grafana 数据源仍指向 `http://localhost:9090`，在 **Grafana 容器内部** 访问不到 Prometheus；变量查询失败就会红三角、面板 No data。Prometheus Targets 页面仍可能显示 UP（那是你在浏览器直接访问 Prometheus）。

**处理：** 重新拉起观测栈（会挂载 `http://prometheus:9090` 数据源 + 共享网络）：

```bash
cd /mnt/c/Users/13249/Desktop/files/github/huatuo
docker compose -f build/docker/docker-compose.yml -f .homework/docker-compose.wsl-ports.yml up -d --force-recreate grafana prometheus elasticsearch
```

浏览器 **Ctrl+F5** 强刷 Grafana，变量应无红三角；`host` 选 **zzz**（不要 All）。

### 让 Grafana 有曲线（已修复抓取）

Prometheus 在容器里默认抓 `localhost:19704`，抓不到 WSL 主机上的 huatuo。在 **huatuo-hw 已 active** 时执行：

```bash
cd /mnt/c/Users/13249/Desktop/files/github/huatuo/.homework
sed -i 's/\r$//' fix-grafana-data.sh
bash fix-grafana-data.sh
```

然后浏览器：

1. `http://<WSL_IP>:9090/targets` → **huatuo** 为 **UP**
2. Grafana → **Dashboards → Huatuo 状态 - 宿主机视图**（勿用「容器视图」）
3. 变量：`region` = **example**，`host` = **zzz**（`hostname` 输出）
4. 时间：**Last 15 minutes**，点 **Refresh**

图 7、图 8 已写入 `源码阅读报告.md`（Prometheus Targets + Grafana 宿主机大盘）。

---

## 用 IP 从 Windows 访问（绕过 localhost / 代理问题）

WSL 里 huatuo 监听 `*:19704`。Windows 上 **不要** 用 `127.0.0.1`（NAT 模式常不通），改用 WSL 的 IP：

```powershell
# 在 PowerShell 查 WSL IP（每次重启 WSL 后可能变化）
wsl -d Ubuntu hostname -I
# 示例：172.28.161.81

curl.exe -s --max-time 15 "http://172.28.161.81:19704/metrics" | findstr /i oom
```

浏览器打开：`http://172.28.161.81:19704/metrics`（把 IP 换成你 `hostname -I` 的第一个地址）。

### 代理 / NO_PROXY 建议（Windows）

在系统或终端环境变量里增加（把 IP 换成你的 WSL IP）：

```
NO_PROXY=127.0.0.1,localhost,172.28.161.81,172.28.160.0/20
```

或在 Ubuntu 里访问时去掉代理：

```bash
env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
  curl -s --max-time 30 http://127.0.0.1:19704/metrics | grep -i oom
```

说明：`ipconfig` 里 **vEthernet (WSL)** 的 `172.28.160.1` 是 **Windows 宿主机** 在虚拟网桥上的地址，不是 WSL 本机 IP；WSL 内服务要用 `wsl hostname -I` 得到的地址（如 `172.28.161.81`）。

## 常见错误

- **`curl` 无输出、exit=28**：未加 `--max-time`，或 huatuo 已被 SIGHUP 杀掉 → 用脚本里的 `systemd-run` 重启。
- **不要用** `curl --noproxy *` 在仓库目录执行（`*` 会展开成文件名）。
- **Windows 浏览器访问 127.0.0.1:19704 失败**：改用 WSL IP（见上）。

## 已有图片

- `02-huatuo-arch.png` — 架构图
