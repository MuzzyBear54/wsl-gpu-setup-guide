# wsl-gpu-setup-guide

Professional, battle-tested notes for building **CUDA-accelerated scientific codes** inside **WSL2 (Ubuntu 22.04)** on Windows 10/11 — with a focus on **NVIDIA HPC SDK**, MPI, HDF5, and compiling **Smilei (PIC)** for **single-GPU** runs.

This guide consolidates fixes/workarounds discovered during real troubleshooting on:
- **Pascal** (e.g., GTX 1060 / `sm_61`)
- **Lovelace/Ada** (e.g., RTX 4070 Ti / `sm_89`)

> ⚠️ Note: As of the original testing, this setup does **not** cover NVIDIA **Blackwell** (RTX 50 series).

---

## What you get

- A clean WSL2 toolchain using **NVIDIA HPC SDK (nvhpc)** while **pinning CUDA 11.8** for stability on older GPUs under WSL2.
- A reproducible way to build **parallel HDF5** compatible with `nvhpc` + MPI.
- A practical fix for a common WSL2 runtime issue (MPI local-rank discovery) by patching a small section in Smilei’s source.
- A working **Smilei machine file** tailored for WSL2 and two GPU generations.

---

## Quick start (high level)

1. Windows prerequisites: WSL2 + Windows NVIDIA driver + virtualization enabled  
2. WSL2 toolchain: install NVIDIA HPC SDK (24.11) and configure environment  
3. Dependencies: build HDF5 from source with MPI + `nvhpc`  
4. Compile Smilei: apply the WSL2 patch + add a `machine/` config + `make`  
5. Run: unlock memlock and run with `mpirun -np 1`

Full instructions: **[`docs/INSTALL_SMILEI_CUDA_WSL2.md`](docs/INSTALL_SMILEI_CUDA_WSL2.md)**

---

## Repository contents

- `docs/INSTALL_SMILEI_CUDA_WSL2.md` — the full step-by-step guide (copy/paste friendly)
- `templates/wsl_machinefile.make` — machine file template (Pascal by default; switch to Ada by editing one line)
- `scripts/verify_wsl_gpu.sh` — quick sanity checks for GPU visibility and WSL2 version
