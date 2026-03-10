# Évaluation d'Impact des Container Network Interfaces (CNI) sur la QoS Kubernetes

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.28-blue?logo=kubernetes)](https://kubernetes.io/)
[![CNI](https://img.shields.io/badge/Network-eBPF%20%7C%20VXLAN-green)](https://github.com/containernetworking/cni)

## 📌 Présentation
Cette étude technique compare les performances de quatre plugins réseau (CNI) majeurs : **Cilium, Calico, Kube-OVN et Flannel**. L'objectif est de quantifier l'impact des différentes architectures (eBPF vs VXLAN/Overlay) sur le débit, la latence et la stabilité opérationnelle dans un cluster multi-nœuds.

## 🚀 Résultats Clés
* **Cilium (eBPF) :** Leader avec **2.28 Gbps** et **0 retransmission**. Latence minimale (~3ms) grâce au bypass d'iptables.
* **Calico (VXLAN) :** Stable mais limité à **377 Mbps** en raison de l'overhead d'encapsulation et d'un **MTU de 1480**.
* **Kube-OVN :** Pollution du noyau constatée, entraînant **32% de perte de paquets UDP** et une latence extrême (jusqu'à 98ms).
* **Flannel :** Instable en environnement multi-nœuds, fréquents **CrashLoopBackOff** et MTU réduit (1450).

---

## 📊 Matrice Comparative de Performance

| CNI | Architecture | Débit (TCP) | Retransmissions | Latence Moy. | MTU |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Cilium** | **eBPF Native** | **2.28 Gbps** | **0** | **3.0 ms** | 1500 |
| **Calico** | VXLAN/BGP | 377 Mbps | 169 | 4.36 ms | 1480 |
| **Kube-OVN** | OVS/OVN | 3.5 Mbps | Élevées | 36.0 ms | 1400 |
| **Flannel** | VXLAN | *Échec* | - | - | 1450 |

---

## 🛠️ Méthodologie & Environnement
Le benchmark a été réalisé sur un cluster de 3 nœuds (Ubuntu 22.04, K8s v1.28) :
* **Contrôle :** 1 Master (2 vCPU, 4GB RAM).
* **Workers :** 2 Nœuds (2 vCPU, 4GB RAM).
* **Outils :** `iperf3` (débit/jitter), `ping` (latence/MTU) et `ab` (performance applicative HTTP).

## 📁 Structure du Dépôt
* `report/` : Rapport technique complet au format PDF.
* `configs/` : Fichiers YAML utilisés pour le déploiement des CNI.
* `results/` : Captures d'écran et logs bruts des tests iperf3/ping.

## 💡 Synthèse Stratégique
1.  **Charges Critiques :** Privilégier **Cilium** pour sa performance brute et son efficacité eBPF.
2.  **Standardisation :** Utiliser **Calico** pour sa maturité et ses politiques réseau éprouvées.
3.  **Avertissement :** Éviter **Flannel** en production pour des besoins de haute performance ou de stabilité multi-nœuds.

---
**Auteur :** Sidali Mezaourou  
**Domaine :** Cloud Networking & Infrastructure Orchestration  
**Date :** Mars 2026
