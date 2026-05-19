# Kubernetes CNI Performance Benchmark

**Comparative study of four Kubernetes CNI plugins — Cilium, Calico, Kube-OVN, and Flannel —
across 14 TCP/UDP performance metrics on a multi-node cluster.**

---

## Summary

| CNI | TCP Throughput | Retransmissions | Avg Latency | UDP Jitter | UDP Loss | MTU |
|---|---|---|---|---|---|---|
| **Cilium** | **2.28 Gbps** | **0** | **3.0 ms** | ~1 ms | — | 1500 |
| Calico | 377 Mbps | 169 | 4.36 ms | 7.45 ms | — | 1480 |
| Kube-OVN | 3.5 Mbps | High | 36 ms | 88.5 ms | 32% | 1400 |
| Flannel | Failed | — | — | — | — | 1450 |

**Bottom line:** Cilium dominates across every metric. Flannel and Kube-OVN are not
production-ready in multi-CNI environments.

---

## Why this study

Network performance in Kubernetes directly impacts QoS for distributed applications.
The choice of CNI affects:

- Effective inter-pod throughput (goodput)
- Latency and jitter for real-time workloads
- Operational stability under load

Most available benchmarks cover only Cilium vs Calico. This study adds Kube-OVN
and documents a phenomenon not covered elsewhere: **kernel pollution from multi-CNI
residual interfaces** — and how it breaks benchmark isolation.

---

## Test environment

| Node | vCPU | RAM | OS | Kubernetes |
|---|---|---|---|---|
| Master | 2 | 4 GB | Ubuntu 22.04 | v1.28 |
| Worker-1 | 2 | 4 GB | Ubuntu 22.04 | v1.28 |
| Worker-2 | 2 | 4 GB | Ubuntu 22.04 | v1.28 |

- Physical interfaces: `enp0s3` / `enp0s8`, MTU 1500
- Cluster network: `10.0.0.0/16` (Cilium, Flannel, Kube-OVN) · `192.168.0.0/16` (Calico)

---

## Methodology

| Tool | Measures | Command |
|---|---|---|
| iperf3 | Throughput, retransmissions, jitter | `iperf3 -c <IP> -t 10` |
| ping | Latency, packet loss, MTU | `ping -s <size> -c 10` |
| Apache Bench | HTTP application performance | `ab -n 200 -c 10` |

Each test repeated 5 times — results show mean and standard deviation.
Baseline: Nginx serving HTTP — **652 req/sec, 15.3ms** with no CNI overhead.

---

## Results

### Cilium — eBPF native routing

- TCP throughput: **2.28 Gbps, 0 retransmissions**
- Average latency: **~3 ms**, jitter ~1 ms
- Full MTU (1500) — no fragmentation
- iptables bypass via eBPF → direct kernel-level packet routing
- Maximum stability across all test runs

Cilium's eBPF dataplane eliminates the overhead of iptables chain traversal entirely.
The result is near line-rate throughput with latency indistinguishable from a raw socket.

### Calico — VXLAN/BGP hybrid

- TCP throughput: **377 Mbps**, 169 retransmissions
- Average latency: **4.36 ms**, jitter 7.45 ms
- MTU reduced to 1480 — software fragmentation overhead
- Stable pod lifecycle, enterprise-grade NetworkPolicy support

Calico is production-ready and operationally mature. The throughput gap vs Cilium
comes entirely from VXLAN encapsulation overhead and iptables chain processing.

### Kube-OVN — OVS/OVN overlay

- UDP throughput: **2.74–3.5 Mbps**, **32% packet loss** under load
- Average latency: **36 ms**, peaks at **98 ms** (1400-byte frames)
- Jitter: 88.5 ms — unusable for real-time workloads
- Frequent pod restarts observed throughout testing
- MTU reduced to 1400 — significant fragmentation

The primary finding: Kube-OVN leaves OVS kernel modules loaded after uninstallation.
These residual interfaces (`flannel.1`, `cni0`) pollute the kernel networking stack
and degrade performance of subsequently installed CNIs. This is not documented
in Kube-OVN's official documentation.

### Flannel — VXLAN overlay

- Pods entered `CrashLoopBackOff` — benchmark could not complete
- MTU reduced to 1450 — fragmentation confirmed
- Multi-node stability: failed

Flannel is not suitable for multi-node production environments.

---

## Key finding — kernel pollution

Switching CNIs without aggressive cleanup leaves residual kernel interfaces that
corrupt subsequent benchmark results. This study documents the forensic cleanup
procedure required for reliable multi-CNI testing:

```bash
# Required between each CNI installation
ip link delete flannel.1 2>/dev/null
ip link delete cni0 2>/dev/null
kubeadm reset --force
systemctl restart kubelet
Scripts in scripts/ automate this cleanup.

Recommendations
Use case	Recommended CNI	Reason
High-performance workloads	Cilium	2.28 Gbps, 0 retransmissions, eBPF bypass
Enterprise standardization	Calico	Mature, stable, strong NetworkPolicy
Avoid in production	Flannel	CrashLoopBackOff, reduced MTU
Requires monitoring	Kube-OVN	Kernel pollution, 32% UDP loss
Repository structure
k8s-cni-benchmark/
├── configs/        # YAML manifests for each CNI deployment
├── results/        # Raw iperf3/ping output and screenshots
├── scripts/        # Benchmark automation and cleanup scripts
└── reports/        # Full technical report (PDF)
Future work
Scale benchmark to 50+ nodes
Measure NetworkPolicy enforcement overhead per CNI
eBPF forensic analysis of per-packet routing paths
Application-level benchmarks: Redis, Kafka, MySQL
References
Cilium (2025). eBPF-based Networking, Observability, and Security
Calico (2025). Project Calico Documentation
Kube-OVN (2025). Enterprise Kubernetes Network
iPerf3 (2025). iPerf3 Documentation
