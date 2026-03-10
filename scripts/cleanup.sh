#!/bin/bash
# cleanup.sh - Nettoyage des traces CNI pour tests multi-environnements
# Auteur: Sidali Mezaourou

echo "--- Début du nettoyage des interfaces et configurations CNI ---"

# 1. Arrêt de kubelet
sudo systemctl stop kubelet

# 2. Suppression des interfaces réseaux résiduelles (Flannel, Calico, OVN)
sudo ip link delete cni0 2>/dev/null
sudo ip link delete flannel.1 2>/dev/null
sudo ip link delete ovn-nb 2>/dev/null
sudo ip link delete cali596bcf58a91 2>/dev/null # Exemple d'interface veth Calico

# 3. Nettoyage des répertoires de configuration
sudo rm -rf /etc/cni/net.d/*
sudo rm -rf /var/lib/cni/*

# 4. Redémarrage du réseau et de kubelet
sudo systemctl restart networking
sudo systemctl start kubelet

echo "--- Système prêt pour le déploiement d'un nouveau CNI ---"
