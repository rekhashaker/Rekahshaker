# Homelab Infrastructure

## Environment
- Proxmox VE host: 10.100.0.2 (SSH as root)
- k3s control plane: 10.100.0.103 (SSH as ubuntu, alias k3s-cp)
- k3s worker 1: 10.100.0.104 (SSH as ubuntu, alias k3s-w1)
- k3s worker 2: 10.100.0.105 (SSH as ubuntu, alias k3s-w2)
- Unraid NFS: 10.200.0.2:/mnt/user/Proxmox
- Default StorageClass: unraid-nfs (nfs.csi.k8s.io)
- k3s version: v1.34.6+k3s1

## Cluster
- Traefik disabled at install (will deploy via Helm)
- Helm 3 installed on k3s-cp
- csi-driver-nfs installed in kube-system
- kubectl configured for ubuntu user on k3s-cp

## Conventions
- Namespaces: one per app
- All manifests stored in ~/Dev/homelab/k3s/<appname>/
- Use Helm where charts exist, raw manifests otherwise
- Persistent volumes use unraid-nfs StorageClass
- Ingress via Traefik IngressRoute

## Network
- LAN: 10.100.0.0/24
- Storage VLAN: 10.200.0.0/24
- Gateway: 10.100.0.1 (OPNsense)
