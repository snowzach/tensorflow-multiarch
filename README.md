# TENSORFLOW-ON-ARM

This is my attempt to build a recent Tensorflow wheel and Docker image compatible with ARM32 and ARM64 devices. 

- Tensorflow v2.7.0

## Compiling Tensorflow Wheel
I checked out the Tensorflow source at version 2.7.0 and I had to edit the file `tensorflow/tools/ci_build/pi/build_raspberry_pi.sh` and insert on line 99 to add an ARMHF target.
```
elif [[ $1 == "ARMHF" ]]; then
  PI_COPTS="--config=elinux_armhf
  --copt=-std=gnu11
  --copt=-O3"
  WHEEL_ARCH=linux_armv7l
```
I also removed the `--config=monolithic` option from the bazel build command around line 126.
After that I was able to cross compile the `aarch64` and `armv7l` wheels with the commands:

```
$ tensorflow/tools/ci_build/ci_build.sh PI-PYTHON38 \
    tensorflow/tools/ci_build/pi/build_raspberry_pi.sh AARCH64
$ tensorflow/tools/ci_build/ci_build.sh PI-PYTHON38 \
    tensorflow/tools/ci_build/pi/build_raspberry_pi.sh ARMHF
```
After running the command there was working python whl and library in the `output-artifacts` directory.

I renamed the armhf output wheel from `tensorflow-2.7.0-cp38-none-linux_armhf.whl` to `tensorflow-2.7.0-cp38-none-linux_armv7l.whl` to ensure it matched the hardware architecture and would be installed by python.

# Tensorflow IO
Tensorflow IO is required in order to install the Tensorflow wheel. There seems to be a chicken-egg problem 
with creating a Tensorflow IO wheel. The Tensorflow Wheel won't install without TensorflowIO but TensorflowIO 
won't compile without Tensorflow installed. 

I was able to work around this by installing just the python portion of Tensorflow IO. I had to actually
run this on ARM devices to get Tensorflow IO to compile. (QEMU segfaulted)

```
$ git clone https://github.com/tensorflow/io.git
$ cd io
$ git checkout v0.23.1
$ python3 setup.py install # Install just the python code
$ python3 -m pip install tensorflow-2.7.0-cp38-none-linux_<arch>.whl # Install tensorflow wheel
```

From there I compiled Tensorflow IO with
```
$ export SETUPTOOLS_USE_DISTUTILS=stdlib # Needed to overcome some strange error with python deps
# ./configure
$ bazel build -s --verbose_failures --local_ram_resources=HOST_RAM*.4 --local_cpu_resources=2 //tensorflow_io/... //tensorflow_io_gcs_filesystem/...
$ python3 setup.py bdist_wheel --data bazel-bin
$ python3 setup.py --project tensorflow_io_gcs_filesystem bdist_wheel --data bazel-bin
```

These wheels are included in this repo as well.

## Docker Image
The Dockerfiles for `aarch64` and `armv7l` are slightly different as each had packages the other architecture didn't.

I build them with docker buildx

```
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx build --push --platform linux/arm/v7 -f Dockerfile.armv7l docker.io/snowzach/tensorflow:2.7.0-armv7l .
docker buildx build --push --platform linux/arm64/v8 --tag docker.io/snowzach/tensorflow:2.7.0-aarch64 -f Dockerfile.aarch64 .
```
