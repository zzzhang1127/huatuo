提供包括文档、测试、Bugfix、通用框架特性、子系统特性共 26 个 issue，根据个人情况贡献，多多益善 👀。

## 文档

| 编号 | 标题 | 代码位置 | 描述/问题/场景 |
|------|------|----------|----------------|
| 1 | 添加常见问题 | docs/faq | 添加 FAQ 文档，可通过收集仓库issue/用户群/commit msg/答疑群等常见问题总结，文档站位置：https://docs.huatuo.tech/en/latest/faq/ |
| 2 | 添加如何贡献 | docs/contribute | 添加贡献指南（已存在 `CONTRIBUTING.md`），文档站位置：https://docs.huatuo.tech/en/latest/contribute/（软连接，类似 `CHANGELOG.md`） |
| 3 | 补充收包延迟事件(net_rx_latency) 失效场景描述 | docs/key-feature | skb->tstamp 在一些内核版本里某些场景会被置0，导致产生大量延迟超40年的事件，梳理对应内核版本和具体patch，补充这些场景应该关闭本功能。文档站位置：https://docs.huatuo.tech/en/latest/key-feature/instant-observability/#3-net_rx_latency，参考：https://mp.weixin.qq.com/s/W20R4pAJauZ0MW9r4cQ9pg [存在的问题以及优化点] 部分 |
| 4 | README 添加内核 7.0 的支持 | README.md, README_CN.md | 目前列出从 v1.0 后支持的内核，还需增加从 2.2.0 后某 commit 支持 7.0 |

## 测试

| 编号 | 标题 | 代码位置 | 描述/问题/场景 |
|------|------|----------|----------------|
| 5 | 添加单元测试或case | — | 增加覆盖率，参考 make unit 步骤和输出 |

## Bugfix

| 编号 | 标题 | 代码位置 | 描述/问题/场景 |
|------|------|----------|----------------|
| 6 | io_source_map 累计字段跨 CPU 非原子更新 | bpf/iotracing.c:246-263 | fs_*_bytes、block_*_bytes、latency.cnt/sum_* 在普通 HASH map 上跨 CPU 非原子更新，存在数据竞态导致计数偏低，建议改用__sync_fetch_and_add |
| 7 | latency.max_d2c / max_q2c 字段定义但从未更新 | bpf/iotracing.c:37-43, bpf/iotracing.c:261-263 | 字段定义但 BPF 端从未更新，用户态也未输出，丢失"最差延迟"指标导致毛刺被均值平滑（用户态计算） |
| 8 | cpu_stat.go deltaHierarchyWaitSum 下溢 | core/metrics/cpu_stat.go:109 | `deltaHierarchyWaitSum = stat.hierarchyWaitSum - cpu.hierarchyWaitSum` uint64，counter reset 时下溢；`if deltaHierarchyWaitSum <= 0` 下溢后变成超大正数，条件永不成立。应该先比较再做减法 |
| 9 | cpuidle.go cgroupMgr 空指针解引用 | core/autotracing/cpuidle.go:46 | `cgroupMgr, _ = cgroups.NewManager()` 可能返回空，未做非空校验，导致后续158,174行访问cgroupMgr时发生空指针解引用 |
| 10 | netdev_dcb.go 反序列化越界 panic | core/metrics/netdev_dcb.go:84 | deserializeIEEEPfc，常量 sizeofIEEEPfc=133 也错（实际 136）。驱动返回短 DCB_ATTR_IEEE_PFC 时 `b[0:133][0]` panic，daemon 整体退出。建议：先校验 `len(b) >= unsafe.Sizeof(ieeePfc{})`，不足返回 error |

## 特性 - 通用框架

| 编号 | 标题 | 代码位置 | 描述/问题/场景 |
|------|------|----------|----------------|
| 11 | 添加 ES 证书访问功能 | internal/storage/elasticsearch | 参考 huatuo 已有 kubelet 相关证书部分代码和配置：internal/pod/container_kubelet_sync.go:105 |
| 12 | 支持 ClickHouse 存储后端 | internal/storage | 当前已有 ES，支持 ClickHouse |
| 13 | 支持 Kafka 存储后端 | internal/storage | 当前已有 ES，支持 Kafka |
| 14 | 添加 bpf 代码的 debug/print 功能 | bpf | 便于调试、定位、错误处理，通过 map 统一导出而不是简单 print，参考：https://github.com/cilium/cilium/blob/main/bpf/lib/dbg.h#L207 |
| 15 | 网络设备 DeviceList 白名单支持正则 | huatuo-bamai.conf | 当前是列表全匹配，统一支持正则 |
| 16 | 使用 golang 内置 build 信息 | `Makefile` `cmd/` | 简化 Makefile 和外部依赖，需支持当前所有golang二进制，参考：https://pkg.go.dev/runtime/debug?#ReadBuildInfo |
| 17 | 添加 healthz 接口 | — | 参考：https://kubernetes.io/docs/reference/using-api/health-checks/ |
| 18 | api 版本管理，支持 v1 | — | 支持 v1 |
| 19 | 提供官方 Helm Chart | deploy/helm/ | 现状：当前未提供 Helm Chart，K8s 部署需手动编写资源，成本较高。核心能力：DaemonSet 部署采集组件、完整 RBAC / Config 配置、values.yaml 支持自定义。集成方式：新增 deploy/helm/，提供标准 Helm Chart，新增代码：Chart.yaml、values.yaml、templates/ |

## 特性 - 内存相关

| 编号 | 标题 | 代码位置 | 描述/问题/场景 |
|------|------|----------|----------------|
| 20 | 实现容器层面的 memburst 功能 | core/autotracing/memburst.go | 当前 memburst 为宿主维度的采集，需增加容器维度采集 |
| 21 | 实现高阶内存分配失败的 bpf 钩子 | core/autotracing | 当检测到高阶内存分配失败时，采集分配者信息并采集伙伴系统的状态上报（vmstat等是否已有指标可表示） |
| 22 | 实现内存直接回收原因记录器 | core/autotracing | 当检测到直接回收发生时，记录此后一段时间内各个进程各个 cgroup 的内存分配量，排序后取前十名上报 |
| 23 | 实现内存使用归类统计 | core/metrics | 精确区分内核内存和用户内存，精确区分可回收页面和不可回收页面，分别对宿主和 cgroup 完成统计并实时上报数据 |
| 24 | OOM 事件补充"现场"内存画像 | core/events/oom.go:43, core/autotracing/memburst.go:230 | OOM 触发时同步采集内存快照，写入 OOMTracingData。当前事件只有 pid/comm/css，回答不了"谁占内存最多、是 anon 还是 file、memcg 离 limit 多近"、如何导致的 OOM。建议：收 perf event 后立即采三类数据——① Top N 进程 RssAnon/RssFile/VmSwap；② 触发 memcg 的 memory.current/max/stat/events；③ host meminfo 关键字段。复用 core/autotracing/memburst.go:230 topMemoryProcesses/readMemInfo 与 internal/cgroups/v2。oom 进程文件页 top 10 文件 |

## 特性 - CPU

| 编号 | 标题 | 代码位置 | 描述/问题/场景 |
|------|------|----------|----------------|
| 25 | 支持 cpu.stat wait_sum 计算容器争抢指标 | core/metrics/cpu_stat.go | 当前代码采用hierarchy_wait_sum - inner_wait_sum - throttle_time的方式来计算外部等待时间，hierarchy_wait_sum和inner_wait_sum都是只有滴滴内核才支持的功能，外部用户无法使用外部争抢这个很有用的功能。但是，wait_sum统计量在所有内核上只要开启kernel.sched_schedstats就会支持，而且可以比较准确的表征容器的外部等待时长。通过以下公式可以准确的计算容器的外部争抢指数：`exter_wait_rate = wait_sum / (wait_sum + cpu_usage)` |

## 特性 - 火焰图功能扩展

| 编号 | 标题 | 代码位置 | 描述/问题/场景 |
|------|------|----------|----------------|
| 26 | 支持终端火焰图查看器 | cmd/perf/parsedata.go, internal/flamegraph/tui/ | 现状：采集后仅输出 JSON，需导入 Grafana/Pyroscope 才能看火焰图。目标：参考 Flameshow，用 Go + Bubble Tea 实现终端交互式火焰图。核心交互：方向键滚动/缩放、/搜索、选中函数详情面板。集成方式：`huatuo-bamai perf --tui` flag，复用现有 FrameData 数据。新增代码：internal/flamegraph/tui/ 目录 |