# wsl-gpu-setup-guide

Reproducible WSL2 GPU toolchain for compiling and running CUDA-accelerated scientific codes on a Windows workstation.

This repo is written from the perspective of **scientific/HPC workloads**, where you need:
- a stable CUDA toolchain inside WSL2,
- MPI,
- HDF5 (often with parallel I/O),
- and a build that does not collapse on “WSL-specific weirdness” (memlock, networking, rank detection).

> Example target code used throughout: a GPU-enabled PIC simulation code (Smilei).  
> The setup is intentionally written to be useful beyond one codebase.

---

## What’s in this repo

- `/docs` – Step-by-step setup and troubleshooting
- `/configs` – Copy/paste env templates and “machine/config” examples
- `/patches` – Patch files for WSL2-specific edge cases (apply with `git apply`)
- `/scripts` – Tiny verification helpers (GPU visible, MPI available, env sane)

---

## Supported / tested

- Windows 10/11 + WSL2
- Ubuntu 22.04 on WSL2
- NVIDIA Windows driver with WSL2 CUDA support (GPU passthrough)
- NVIDIA HPC SDK (NVHPC) toolchain
- CUDA pinned to 11.8 when needed for stability/compatibility
- MPI + HDF5 (built from source for NVHPC compatibility)

---

## Quick start (high level)

1) Windows prereqs + GPU passthrough: `docs/01-windows-prereqs.md`  
2) Ubuntu setup + base deps: `docs/02-wsl2-ubuntu-setup.md`  
3) Install NVHPC and set environment: `docs/03-nvhpc-install.md`  
4) Build HDF5 from source: `docs/04-hdf5-build.md`  
5) Build a real code (example): `docs/05-build-example-smilei.md`  
6) Runtime gotchas (memlock / WSL pitfalls): `docs/06-runtime-gotchas.md`  
7) Troubleshooting: `docs/07-troubleshooting.md`

---

## Verify your setup

Run:

```bash
./scripts/verify_gpu.sh
./scripts/env_check.sh
./scripts/verify_mpi.sh
