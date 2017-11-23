#!/usr/bin/env bash

# uncomment if debugging:
#set -o xtrace

set -o errexit
set -o nounset
set -o pipefail

function run () {

OPENCV_VERSION='3.3.1'
PYTHON_VERSION='3.6.3'
NPROC=$(sysctl -n hw.ncpu)

pyenv global system || true

if [ "$(which python)" != "/usr/bin/python" ]; then
    echo Script must be run using Mac OS X default Python interpreter
    exit 1
fi

echo "OpenCV, Python 3.6.3, pyenv Installation Script"
echo "Author: Adam Gradzki (adam@mm.st)"

echo "Performing brew package installation"
# check if brew package manager is installed
if [ "$(which brew)" != "/usr/local/bin/brew" ]; then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Brew is installed. Cleaning up, updating, and upgrading."
brew cleanup
brew update
brew upgrade

echo "Installing Python3 dependencies with Brew"
eval $(brew deps python3 | python -c "import sys; print 'brew install ' + ' '.join(x.strip() for x in sys.stdin.readlines())")
echo "Installing OpenCV dependencies with Brew"
eval $(brew deps opencv | python -c "import sys; print 'brew install ' + ' '.join(x.strip() for x in sys.stdin.readlines())")

echo "Installing pyenv and pyenv virtualenv plugin"
brew install pyenv pyenv-virtualenv

echo "Checking for Python ${PYTHON_VERSION}"
_CMD="import sys; [sys.exit(0) for l in sys.stdin.readlines() if l[2:].startswith('${PYTHON_VERSION}')]; sys.exit(1)"
pyenv versions | python -c "${_CMD}" && rc=$? || rc=$?


if [ ${rc} -eq 0 ]; then
    echo "Found an existing Python ${PYTHON_VERSION}"
else
    echo "Building Python ${PYTHON_VERSION} from source"
    CFLAGS="-I$(brew --prefix readline)/include -I$(brew --prefix openssl)/include -march=native" \
    LDFLAGS="-L$(brew --prefix readline)/lib    -L$(brew --prefix openssl)/lib" \
    CONFIGURE_OPTS="--enable-shared --enable-optimizations --with-computed-gotos" \
    MAKE_OPTS="-j ${NPROC}" \
    pyenv install ${PYTHON_VERSION} --verbose
fi

echo "Creating OpenCV virtualenv"
pyenv virtualenv ${PYTHON_VERSION} opencv --verbose || true

pyenv global opencv
python3 --version

pip3 install -U setuptools
pip3 install -U pip
pip3 install -U wheel
pip3 install -U cython
pip3 install -U numpy

find /opt/src -maxdepth 1 -type d -iname "opencv*" -exec rm -rf "{}" \;
find /opt/ -maxdepth 1 -type d -iname "opencv*" -exec rm -rf "{}" \;

sudo mkdir -p /opt/src
sudo chown $(whoami) /opt
sudo chmod 777 /opt
sudo chown $(whoami) /opt/src
sudo chmod 777 /opt/src
cd /opt/src
if [[ ! -r "opencv_${OPENCV_VERSION}.zip" ]]; then
    echo "Cannot find opencv_${OPENCV_VERSION}.zip. Downloading..."
    curl -L https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip -o opencv_${OPENCV_VERSION}.zip
fi
if [[ ! -r "opencv_contrib_${OPENCV_VERSION}.zip" ]]; then
    echo "Cannot find opencv_contrib_${OPENCV_VERSION}.zip. Downloading..."
    curl -L https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip -o opencv_contrib_${OPENCV_VERSION}.zip
fi
unzip opencv_${OPENCV_VERSION}.zip
unzip opencv_contrib_${OPENCV_VERSION}.zip
mv -v opencv-${OPENCV_VERSION} /opt/src/opencv_${OPENCV_VERSION}_python_${PYTHON_VERSION}
mv -v opencv_contrib-${OPENCV_VERSION} /opt/src/opencv_contrib_${OPENCV_VERSION}_python_${PYTHON_VERSION}
cd /opt/src/opencv_${OPENCV_VERSION}_python_${PYTHON_VERSION}
mkdir release
cd release

CFLAGS='-march=native -O2 -pipe' \
CXXFLAGS='-march=native -O2 -pipe' \
cmake \
-D CMAKE_INSTALL_PREFIX=/opt/opencv_${OPENCV_VERSION}_python_${PYTHON_VERSION} \
-D OPENCV_EXTRA_MODULES_PATH=/opt/src/opencv_contrib_${OPENCV_VERSION}_python_${PYTHON_VERSION}/modules \
-D ENABLE_FAST_MATH=1 \
-D BUILD_OPENCV_PYTHON2=OFF \
-D BUILD_OPENCV_PYTHON3=ON \
-D BUILD_OPENCV_JAVA=OFF \
-D BUILD_PERF_TESTS=OFF \
-D CMAKE_BUILD_TYPE=RELEASE \
-D PYTHON3_LIBRARY=$(python3 -c "import os.path; from distutils.sysconfig import get_config_var; print(os.path.join(get_config_var('LIBDIR'), get_config_var('LDLIBRARY')))") \
-D PYTHON3_EXECUTABLE=$(which python3) \
-D PYTHON3_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
-D PYTHON3_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") ..
make install -j ${NPROC}

}

run

