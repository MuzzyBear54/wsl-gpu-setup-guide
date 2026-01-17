#!/usr/bin/env bash
set -euo pipefail

echo "[check] WSL distros + version:"
wsl.exe --list --verbose 2>/dev/null || true

echo
echo "[check] Linux sees NVIDIA GPU via WSL projection:"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi || true
else
  echo "nvidia-smi not found. Verify Windows NVIDIA driver + WSL GPU support."
fi

echo
echo "[check] NVHPC compiler availability:"
if command -v nvc++ >/dev/null 2>&1; then
  nvc++ --version | head -n 2
else
  echo "nvc++ not found. Did you install NVIDIA HPC SDK and source ~/.bashrc?"
fi

echo
echo "[check] CUDA_HOME:"
echo "${CUDA_HOME:-"(not set)"}"
