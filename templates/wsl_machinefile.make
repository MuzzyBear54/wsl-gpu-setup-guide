# Smilei WSL2 machine file (template)
# Save as: scripts/compile_tools/machine/wsl_pascal
# Adjust ARCH_HOST/ARCH_DEVICE for your GPU:
#   Pascal GTX 1060:   cc61 / sm_61
#   Ada/Lovelace 40xx: cc89 / sm_89

SMILEICXX = mpicxx
GPU_COMPILER = nvcc

# Paths (pinned to CUDA 11.8 under NVHPC)
H5_DIR    = $(HDF5_ROOT_DIR)
CUDA_ROOT = /opt/nvidia/hpc_sdk/Linux_x86_64/24.11/cuda/11.8
MPI_ROOT  = /opt/nvidia/hpc_sdk/Linux_x86_64/24.11/comm_libs/11.8/hpcx/hpcx-2.14/ompi
MATH_ROOT = /opt/nvidia/hpc_sdk/Linux_x86_64/24.11/math_libs/11.8/targets/x86_64-linux

# Architecture flags
ARCH_HOST   = cc61
ARCH_DEVICE = sm_61

# Compiler flags
CXXFLAGS += -O3 -std=c++14 -Minfo=accel \
  -acc -gpu=$(ARCH_HOST) -gpu=cuda11.8 \
  -I$(H5_DIR)/include \
  -I$(MATH_ROOT)/include \
  -I$(CUDA_ROOT)/include \
  -I$(MPI_ROOT)/include

GPU_COMPILER_FLAGS += -O3 -std=c++14 -arch=$(ARCH_DEVICE) --expt-relaxed-constexpr \
  -I$(H5_DIR)/include \
  -I$(MPI_ROOT)/include \
  -I$(CUDA_ROOT)/include

LDFLAGS += -acc -gpu=$(ARCH_HOST) -gpu=cuda11.8 \
  -L$(H5_DIR)/lib -lhdf5 -lhdf5_cpp \
  -L$(MATH_ROOT)/lib \
  -L$(CUDA_ROOT)/lib64 \
  -lcudart -lcurand
