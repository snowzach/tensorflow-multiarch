#!/bin/bash
# docker run -it -v /data/git/video/doodsp:/doodsp ubuntu:20.04 /bin/bash
export DEBIAN_FRONTEND=noninteractive
export LANG C.UTF-8

cd /tmp

apt-get update && apt-get install -y --no-install-recommends \
    pkg-config zip zlib1g-dev unzip wget bash-completion git curl \
    build-essential patch g++ cmake ca-certificates \
    python3 python3-dev python3-distutils python3-numpy python3-six \
    libc6-dev libstdc++6 libusb-1.0-0

export PROTOC_VERSION="3.14.0"
export BAZEL_VERSION="3.7.2"
export TF_VERSION="v2.7.0"

# Install protoc
wget https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip && \
    unzip protoc-${PROTOC_VERSION}-linux-x86_64.zip -d /usr/local && \
    rm /usr/local/readme.txt && \
    rm protoc-${PROTOC_VERSION}-linux-x86_64.zip

# Install bazel
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel_${BAZEL_VERSION}-linux-x86_64.deb && \
    dpkg -i bazel_${BAZEL_VERSION}-linux-x86_64.deb && \
    rm bazel_${BAZEL_VERSION}-linux-x86_64.deb

# Download tensorflow sources
cd /tmp && git clone https://github.com/tensorflow/tensorflow.git --branch $TF_VERSION --single-branch

# Configure
cd /tmp/tensorflow
export TF_NEED_GDR=0 TF_NEED_AWS=0 TF_NEED_GCP=0 TF_NEED_CUDA=0 TF_NEED_HDFS=0 TF_NEED_OPENCL_SYCL=0 TF_NEED_VERBS=0 TF_NEED_MPI=0 TF_NEED_MKL=0 TF_NEED_JEMALLOC=1 TF_ENABLE_XLA=0 TF_NEED_S3=0 TF_NEED_KAFKA=0 TF_NEED_IGNITE=0 TF_NEED_ROCM=0
yes '' | ./configure

# Build
export BAZEL_COPT_FLAGS="--local_ram_resources=HOST_RAM*.5 --local_cpu_resources=HOST_CPUS*.75 --copt=-O3 --copt=-fomit-frame-pointer --config=noaws --config=nohdfs"
export BAZEL_EXTRA_FLAGS="--host_linkopt=-lm"
bazel build -c opt $BAZEL_COPT_FLAGS --verbose_failures $BAZEL_EXTRA_FLAGS //tensorflow/tools/pip_package:build_pip_package
