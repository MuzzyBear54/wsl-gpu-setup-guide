# Installing CUDA-accelerated Smilei in WSL2 (Ubuntu 22.04)

This document is written for **Windows 10/11 + WSL2 + Ubuntu 22.04**, targeting:
- **GTX 1060/any 10 series (Pascal)** and
- **RTX 4070 Ti/any 40 series (Ada/Lovelace)**

It should generalize to similar GPUs with minor changes.

---

## Why this is non-trivial in WSL2

WSL2 behaves differently than a native Linux install in a few ways that matter for HPC:
- GPU access is projected from Windows drivers — installing Linux drivers inside WSL usually breaks things.
- Networking + environment variables can be different enough that MPI codes sometimes fail to infer “local rank”.
- Memory locking limits can prevent GPU execution unless explicitly unlocked.

This guide consolidates a “known good” path that avoids those traps.

---

## Part 1 — Windows prerequisites (do not skip)

### 1) BIOS virtualization
Reboot into BIOS and ensure:
- **Intel VT-x** and **VT-d** are enabled.

### 2) NVIDIA driver (Windows-side)
Install the standard Windows NVIDIA driver (Game Ready / Studio — either is fine).

> Do **not** install NVIDIA Linux drivers inside Ubuntu/WSL.

### 3) Install/Update WSL2
Open **PowerShell as Administrator**:

```powershell
wsl --update
wsl --install -d Ubuntu-22.04
```

Reboot if prompted.

### 4) Verify you’re on WSL2
In PowerShell:

```powershell
wsl --list --verbose
```

You should see `VERSION` = `2`.

If it shows `1`:

```powershell
wsl --set-version Ubuntu-22.04 2
```

---

## Part 2 — Toolchain (NVIDIA HPC SDK)

We install NVIDIA HPC SDK but **force CUDA 11.8** for stability on Pascal under WSL2.

### 1) Prep Ubuntu packages

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git wget python3-dev python3-pip libz-dev pkg-config python-is-python3
```

### 2) Install NVIDIA HPC SDK (24.11)

```bash
cd /tmp
wget https://developer.download.nvidia.com/hpc-sdk/24.11/nvhpc_2024_2411_Linux_x86_64_cuda_multi.tar.gz
tar xpzf nvhpc_2024_2411_Linux_x86_64_cuda_multi.tar.gz
cd nvhpc_2024_2411_Linux_x86_64_cuda_multi
sudo ./install
```

During prompts:
- Install directory: press Enter (default)
- CUDA Driver: YES
- Type: 1 — Single system install

### 3) Configure environment

Append to `~/.bashrc`:

```bash
# NVIDIA HPC SDK SETUP (pin CUDA 11.8)
export NVARCH=Linux_x86_64
export NVHPC_VERSION=24.11
export NVHPC_ROOT=/opt/nvidia/hpc_sdk

export NVCOMPILERS=$NVHPC_ROOT/$NVARCH/$NVHPC_VERSION/compilers
export NVHPC_MPI=$NVHPC_ROOT/$NVARCH/$NVHPC_VERSION/comm_libs/mpi

export PATH=$NVCOMPILERS/bin:$NVHPC_MPI/bin:$PATH
export LD_LIBRARY_PATH=$NVCOMPILERS/lib:$NVHPC_MPI/lib:$LD_LIBRARY_PATH
export MANPATH=$MANPATH:$NVCOMPILERS/man

# Force CUDA 11.8 paths
export CUDA_HOME=$NVHPC_ROOT/$NVARCH/$NVHPC_VERSION/cuda/11.8
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Critical runtime library paths
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/nvidia/hpc_sdk/Linux_x86_64/24.11/math_libs/11.8/targets/x86_64-linux/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/nvidia/hpc_sdk/Linux_x86_64/24.11/cuda/11.8/lib64
export LD_LIBRARY_PATH=/usr/lib/wsl/lib:$LD_LIBRARY_PATH

# HDF5 install location
export HDF5_ROOT=$HOME/software/hdf5_nvhpc
export HDF5_ROOT_DIR=$HDF5_ROOT
export PATH=$HDF5_ROOT/bin:$PATH
export LD_LIBRARY_PATH=$HDF5_ROOT/lib:$LD_LIBRARY_PATH

# Unlock memlock before running GPU code (WSL2 limitation)
alias unlock_memory='sudo prlimit --pid $$ --memlock=unlimited:unlimited'
```

Apply:

```bash
source ~/.bashrc
```

---

## Part 3 — Build dependencies (HDF5 + Python stack)

### 1) Build HDF5 from source

```bash
cd ~
wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.14/hdf5-1.14.3/src/hdf5-1.14.3.tar.gz
tar xzf hdf5-1.14.3.tar.gz
cd hdf5-1.14.3

export CC=mpicc
export CXX=mpicxx
export FC=mpifort

./configure --prefix=$HOME/software/hdf5_nvhpc \
  --enable-parallel --enable-shared --enable-cxx \
  --enable-unsupported --disable-fortran \
  --with-default-api-version=v114

make -j 6
make install
```

### 2) Python packages

```bash
export HDF5_MPI="ON"
export HDF5_DIR=$HDF5_ROOT
export CC=mpicc
export CFLAGS="-noswitcherror"

pip install --upgrade pip setuptools wheel
pip install --no-binary=h5py h5py pint matplotlib numpy scipy
```

---

## Part 4 — Compile Smilei (including WSL2 fix)

### 1) Get Smilei

```bash
cd ~
git clone https://github.com/SmileiPIC/Smilei.git
cd Smilei
```

### 2) Patch source (WSL2 MPI local rank issue)

In WSL2, Smilei may fail with:
> “impossible to determine local rank”

Edit `src/Smilei.cpp`, find that error branch, and replace the `else` body with:

```cpp
// Force Rank 0 for WSL2 single-GPU runs
local_rank = 0;
acc_set_device_num(local_rank, acc_get_device_type());
```

This is appropriate when you run with `mpirun -np 1`.

### 3) Create a machine file

Create `scripts/compile_tools/machine/wsl_pascal` and copy the template from:
- `templates/wsl_machinefile.make`

Set arch flags:
- Pascal: `cc61` / `sm_61`
- Ada/Lovelace: `cc89` / `sm_89`

### 4) Compile

```bash
make -j 4 machine="wsl_pascal" config="gpu_nvidia"
```

---

## Part 5 — Running (memlock is the gotcha)

In a fresh terminal:

```bash
unlock_memory
ulimit -l
```

It should print `unlimited`.

Then run:

```bash
mpirun -np 1 ./smilei your_script.py
```
