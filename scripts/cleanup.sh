#!/bin/bash
# cleanup.sh — Remove residual CNI interfaces and config between benchmark runs
# Author: Sidali

echo "--- Starting CNI cleanup ---"

# 1. Stop kubelet
sudo systemctl stop kubelet

# 2. Delete residual network interfaces (Flannel, Calico, OVN)
sudo ip link delete cni0 2>/dev/null
sudo ip link delete flannel.1 2>/dev/null
sudo ip link delete ovn-nb 2>/dev/null
sudo ip link delete cali596bcf58a91 2>/dev/null  # example Calico veth interface

# 3. Wipe CNI config and state directories
sudo rm -rf /etc/cni/net.d/*
sudo rm -rf /var/lib/cni/*

# 4. Restart networking and kubelet
sudo systemctl restart networking
sudo systemctl start kubelet

echo "--- System ready for next CNI deployment ---"
