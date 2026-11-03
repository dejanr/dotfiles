# Homelab research: lightweight NixOS, Kubernetes, and ZFS

Status: exploratory; no deployment or storage migration decided.

Initial research: 2026-11-03. Upstream defaults can change; pin versions before implementing.

## Goal

Explore a small, reproducible homelab with NixOS underneath Kubernetes pods, optionally using ZFS for persistent-volume snapshots and clones. Optimize for understandable operations and recovery, not the lowest possible idle-memory number.

In this model NixOS manages the hosts; pods can run ordinary OCI images. Running a complete NixOS system inside every pod is not required.

Starting point: [Shrinking NixOS RAM footprint and resource requirements to the bare minimum][article]. The author reports approximately 96 MB idle memory and rebuilds within a 512 MB KVM guest. These are measurements of that particular stripped-down VPS, **not measurements of Kubernetes or ZFS**, and have not been reproduced here.

## Working recommendation

Start with **one NixOS host running K3s directly**, ordinary container images, and a separate ZFS data pool if suitable disks are available. Try OpenEBS Local PV ZFS for Kubernetes-managed snapshots and clones. Keep the runtime on ext4 initially to separate container-runtime questions from persistent-storage questions.

This is a proposed experiment, not a settled architecture. If automatic recovery of stateful workloads on another host is a requirement, settle the shared/replicated-storage design first: local ZFS alone does not provide it. [3][4]

## Existing repository context

- [`hosts/m910q/configuration.nix`](../hosts/m910q/configuration.nix) already describes four hosts in an Incus cluster. Its storage pool uses the `dir` driver, not ZFS.
- [`hosts/m910q/disk-config.nix`](../hosts/m910q/disk-config.nix) allocates the remaining NVMe space to ext4 root. Adding a ZFS pool requires a spare disk or an explicitly planned migration; there is no declared free data partition.
- [`hosts/framework/hardware-configuration.nix`](../hosts/framework/hardware-configuration.nix) provides an existing ZFS example. Host-specific desktop/kernel choices should not become homelab defaults.
- [`modules/nixos/default.nix`](../modules/nixos/default.nix) adds shared packages, fonts, services, and user settings. A minimal role must account for these inherited defaults rather than assuming a clean server baseline.
- No K3s/Kubernetes configuration was found in `hosts/` or `modules/nixos/` during this pass.
- Future reusable system configuration belongs under `modules/nixos/`, following [`modules/template.nix`](../modules/template.nix), with small host-specific enables. This folder holds research, not active configuration.

The checked flake pins nixpkgs to `dc5d91f840324650bac8c379428c7037a416959a`. Its existing K3s module supports server/agent roles, standalone SQLite, and embedded-etcd initialization. Use that integration instead of an imperative installation script. [1]

## Architecture questions

| Option | Why consider it | Main trade-off / question |
| --- | --- | --- |
| K3s directly on NixOS | Fewest layers; direct access to host-managed ZFS | Does it replace Incus on selected hosts or coexist with it? |
| NixOS VMs inside the existing Incus cluster | Keeps the current virtualization boundary | Extra guest overhead; decide whether storage belongs to the outer host or the guest |
| K3s inside Incus system containers | Potentially less guest overhead than VMs | Research nesting, cgroups, networking, privileges, and CSI mount propagation before choosing it |
| ZFS-backed network storage via CSI | Separates compute from a storage host | A reachable volume is not the same as an HA storage service; storage-server failure remains a design concern |

Democratic CSI supports both node-local ZFS drivers and generic ZFS-backed NFS/iSCSI drivers, so it is a useful alternative to investigate if storage is centralized. Its local drivers remain node-local even when they advertise `ReadWriteMany`. [4]

Do not let Incus and Kubernetes independently manage the same datasets or volumes. Storage ownership should be explicit.

## What to take from the low-memory article

**Worth measuring first:**

- Remove unnecessary desktop services, documentation, and default packages from the server profile.
- Compare idle host memory separately from K3s, CSI components, ZFS cache, and application workloads.
- Evaluate/build generations on a larger machine and deploy them to the hosts, rather than making tiny hosts perform every rebuild.
- Consider socket-activated SSH if connection patterns justify it, while retaining reliable time synchronization and recovery access.

**Do not copy blindly:**

- The custom pruned module tree and hardware blacklists target a specific KVM guest. Bare-metal storage controllers, networking, ZFS, and container networking need a different set of modules.
- Disabling audit, watchdogs, PSI, kernel checks, or time-sync daemons trades away capabilities for small savings. Keep normal defaults until measurements justify a change.
- THP and allocator/GC tuning are workload- and version-specific experiments, not baseline Kubernetes requirements.
- The article's zram setup is swap. Linux kubelet normally refuses to start with swap enabled. Explicit `failSwapOn: false` and a chosen swap policy are needed if retaining it; `NoSwap` can still allow host processes, but not pods, to use swap. Verify against the selected K3s/Kubernetes version. [5]

K3s documents a **2-core / 2 GB server minimum** and a **1-core / 512 MB agent minimum**, excluding application workloads. ZFS and the storage driver need additional headroom. A 512 MB VPS result is therefore not a useful combined-stack sizing target. [2]

For an initial combined server/storage experiment, provision several GB above the server minimum if available. This is a conservative starting suggestion, not a measured requirement.

## ZFS and pods: distinguish three different things

### 1. NixOS generations

Declarative system configuration and generation rollback concern the host software/configuration. They do not restore a database or its PVC contents. Keep system rollback and data recovery as separate procedures.

### 2. Container-runtime snapshotters

Containerd snapshotters manage image layers and container root filesystems. They are not the Kubernetes persistent-volume snapshot API. The pinned nixpkgs K3s storage guide documents a ZFS snapshotter using `--snapshotter=zfs` and a dataset mounted at `/var/lib/rancher/k3s/agent/containerd/io.containerd.snapshotter.v1.zfs`. [6]

Possible later experiments:

- Use that ZFS runtime integration, checking package support, mount ordering, cleanup, and reboot behavior.
- Investigate [nix-snapshotter][nix-snapshotter] for images that reference Nix store paths and binary caches. This is an image-distribution/runtime integration, **not a replacement for ZFS PVC snapshots**. Verify compatibility with the pinned K3s package before adding it.

For the first experiment, retain an ext4-backed runtime path and use ZFS only for persistent application data. This avoids needing to validate both integrations simultaneously; it is not a claim that ZFS cannot back the runtime.

### 3. Persistent volumes and CSI snapshots

The useful application-facing path is:

```text
pod -> PVC -> StorageClass -> ZFS CSI driver -> dataset or zvol
                   |
                   +-> VolumeSnapshot -> new PVC -> restored/cloned workload
```

OpenEBS Local PV ZFS supports snapshots and creating a new PVC from a snapshot. Its documented clone remains on the original node and within the same ZFS pool. This is suitable for fast local recovery or disposable copies, not automatic cross-host failover. [3]

Kubernetes requires snapshot CRDs, a snapshot controller, and a CSI driver with snapshot support. The inspected OpenEBS chart enables snapshot CRDs and a bundled snapshot controller by default; reconcile ownership with any existing cluster-level installation rather than blindly installing another one. [7][8]

A CSI snapshot captures volume data, not pod RAM or the complete running application. Treat live database snapshots as crash-consistent unless the database's documented backup/quiescing procedure establishes stronger guarantees. Separate volumes also need an explicit consistency strategy.

Prefer restoring into a **new PVC** and verifying it before switching the workload. Do not roll back a mounted, actively written database dataset underneath a pod.

## NixOS/ZFS integration checks

- **Host tooling:** OpenEBS's chart explicitly supports `zfs.bin: /run/current-system/sw/bin/zfs`; its wrapper executes the command inside the host root. Confirm the binary exists there and survives rebuilds without embedding a stale store path. This is a documented integration point, not a deployment verified here. [8]
- **CSI mount paths:** check the actual kubelet root, socket locations, host mounts, and mount propagation against the selected chart and K3s configuration. Do not assume generic Kubernetes paths match every distribution. [8]
- **Kernel compatibility:** choose a kernel supported by the selected OpenZFS package and verify upgrades before rollout. Avoid inheriting a desktop's custom kernel settings.
- **Memory:** budget for ARC alongside pods. OpenZFS exposes `zfs_arc_max`, but that caps ARC, not all ZFS/kernel memory. Tune from observations rather than assuming a universal RAM-per-TB rule or fixed default percentage. [9]
- **Capacity:** include retained snapshots and clone dependencies in capacity/retention design. A snapshot on the same pool is not protection against losing that pool.
- **Ownership/security:** CSI needs powerful access to host storage. Keep it administrator-managed; ordinary application pods should receive PVCs, not `/dev/zfs` or host ZFS-management access.

## Recovery and availability

There are three separate backup domains:

1. **Desired configuration:** this repository plus pinned inputs, manifests/chart values, and a recoverable secrets process.
2. **Cluster state:** K3s datastore backups **and the server token**. K3s documents that the token is necessary to decrypt confidential datastore data during restoration. [10]
3. **Application data:** independent copies, using an appropriate database backup method or ZFS send/receive workflow, with retention and a restore exercise. [11]

Local snapshots are a recovery convenience, not an independent backup. ZFS send/receive transfers data, but does not by itself update Kubernetes PV topology or orchestrate workload failover. [3][11]

A single K3s server defaults to SQLite. Embedded-etcd HA uses at least three server nodes; that protects the control plane, **not node-local application volumes**. Avoid adding etcd complexity before deciding whether control-plane HA is actually needed. [1][12]

## Research backlog

- [ ] Inventory candidate hosts: RAM, CPU, disk devices/capacity, NICs, power consumption, and current Incus workloads. Do not infer physical inventory from host names.
- [ ] Decide whether Incus stays, and whether Kubernetes runs directly on hosts or in guests.
- [ ] List initial workloads and classify their storage needs: disposable, single-node persistent, shared filesystem, or automatic cross-host recovery.
- [ ] Decide acceptable downtime/data loss, backup destination, and whether a separate storage host is available.
- [ ] Compare OpenEBS Local PV ZFS against Democratic CSI for the chosen topology; pin driver/chart versions and inspect rendered privileges/resources.
- [ ] Design a non-destructive disk layout. The existing m910q declaration consumes the NVMe for ext4 root.
- [ ] Measure four stages: minimal NixOS; plus K3s; plus ZFS/CSI; plus representative workloads. Include memory pressure, ARC, rebuild/upgrade peaks, I/O, and idle watts.
- [ ] Verify create PVC -> write data -> snapshot -> modify data -> restore into new PVC -> verify original contents. Repeat after reboot and a NixOS rebuild.
- [ ] Exercise loss of a node: confirm local-volume workloads stay unavailable rather than assuming Kubernetes can move their data.
- [ ] Restore cluster state and application data from independent backups onto a replacement host, including CSI metadata/topology handling.
- [ ] Review firewall/CNI requirements and coordinate host upgrades/reboots. The current m910q settings disable the firewall and allow unattended rebooting; neither should be inherited without review.
- [ ] Only then explore runtime ZFS snapshots, nix-snapshotter, more aggressive RAM trimming, or multi-server HA.

## Sources

The forum supplies the motivation and its author's measurements; upstream documentation/source supplies the integration facts. No runtime experiments have been performed yet.

[article]: https://lowendspirit.com/discussion/11543/shrinking-nixos-ram-footprint-and-resource-requirements-to-the-bare-minimum
[nix-snapshotter]: https://github.com/pdtpartners/nix-snapshotter/blob/main/README.md

1. [Pinned NixOS K3s module](https://github.com/NixOS/nixpkgs/blob/dc5d91f840324650bac8c379428c7037a416959a/nixos/modules/services/cluster/rancher/k3s.nix).
2. [K3s requirements](https://docs.k3s.io/installation/requirements), including workload exclusions and networking requirements.
3. OpenEBS Local PV ZFS: [snapshots](https://openebs.io/docs/user-guides/local-storage-user-guide/local-pv-zfs/advanced-operations/zfs-snapshot) and [clones](https://openebs.io/docs/user-guides/local-storage-user-guide/local-pv-zfs/advanced-operations/zfs-clone).
4. [Democratic CSI drivers and prerequisites](https://github.com/democratic-csi/democratic-csi/blob/master/README.md), especially `zfs-local-{dataset,zvol}` and generic network-storage drivers.
5. [Kubernetes swap memory management](https://kubernetes.io/docs/concepts/cluster-administration/swap-memory-management/).
6. [Pinned nixpkgs K3s storage examples](https://github.com/NixOS/nixpkgs/blob/dc5d91f840324650bac8c379428c7037a416959a/pkgs/applications/networking/cluster/k3s/docs/examples/STORAGE.md).
7. [Kubernetes volume snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/).
8. OpenEBS Local PV ZFS chart: [values](https://github.com/openebs/zfs-localpv/blob/develop/deploy/helm/charts/values.yaml) and [host ZFS command wrapper](https://github.com/openebs/zfs-localpv/blob/develop/deploy/helm/charts/templates/configmap.yaml). These are moving development sources; recheck the selected release.
9. [OpenZFS module parameters](https://openzfs.github.io/openzfs-docs/man/master/4/zfs.4.html), especially `zfs_arc_max`; defaults are version-dependent.
10. [K3s backup and restore](https://docs.k3s.io/datastore/backup-restore).
11. OpenZFS manuals: [zfs-send](https://openzfs.github.io/openzfs-docs/man/master/8/zfs-send.8.html) and [zfs-receive](https://openzfs.github.io/openzfs-docs/man/master/8/zfs-receive.8.html).
12. [K3s embedded-etcd HA](https://docs.k3s.io/datastore/ha-embedded).
