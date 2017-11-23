#!/usr/bin/env bash

# uncomment if debugging:
#set -o xtrace

set -o errexit
set -o nounset
set -o pipefail

function run () {

OPENCV_VERSION='3.3.1'
PYTHON_VERSION='3.6.3'

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
pyenv versions | python -c "import sys; [sys.exit(0) for l in sys.stdin.readlines() if l.startswith('* ${PYTHON_VERSION}')]; sys.exit(1)" && rc=$? || rc=$?

if [ ${rc} -ne 0 ]; then
    echo "Building Python ${PYTHON_VERSION} from source"
    CFLAGS="-I$(brew --prefix readline)/include -I$(brew --prefix openssl)/include -march=native" \
    LDFLAGS="-L$(brew --prefix readline)/lib    -L$(brew --prefix openssl)/lib" \
    CONFIGURE_OPTS="--enable-shared --enable-optimizations --with-computed-gotos" \
    MAKE_OPTS="-j8" \
    pyenv install ${PYTHON_VERSION} --verbose
else
    echo "Found an existing Python ${PYTHON_VERSION}"
fi

echo "Attempting to set Python ${PYTHON_VERSION} as the global interpreter"
pyenv global ${PYTHON_VERSION}

echo "Creating OpenCV virtualenv"
pyenv virtualenv ${PYTHON_VERSION} opencv --verbose

exit

# step 3. install python dependencies
pip install -U pip setuptools
pip install -U wheel
pip install -U cython numpy

# step 4. build opencv
sudo mkdir -p /opt/src
sudo chown $(whoami):staff /opt
sudo chown $(whoami):staff /opt/src
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
-D BUILD_OPENCV_PYTHON2=OFF \
-D BUILD_OPENCV_PYTHON3=ON \
-D BUILD_TIFF=ON \
-D BUILD_OPENCV_JAVA=OFF \
-D BUILD_PERF_TESTS=OFF \
-D CMAKE_BUILD_TYPE=RELEASE \
-D PYTHON3_LIBRARY=$(python -c "import os.path; from distutils.sysconfig import get_config_var; print(os.path.join(get_config_var('LIBDIR'), get_config_var('LDLIBRARY')))") \
-D PYTHON3_EXECUTABLE=$(which python) \
-D PYTHON3_INCLUDE_DIR=$(python -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
-D PYTHON3_PACKAGES_PATH=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") ..
make -j8
make install
### If using 3.6.x:
### Installs to: ~/.pyenv/versions/${PYTHON_VERSION}/lib/python3.6/site-packages/cv2.cpython-36m-darwin.so

### Example installation for a virtual environment named "demo"
### If using 3.6.x:
# pyenv virtualenv 3.6.x demo
# pyenv global demo
# pip install -U pip setuptools wheel numpy
# ln -s "$HOME/.pyenv/versions/3.6.x/lib/python3.6/site-packages/cv2.cpython-36m-darwin.so" \
#     "$HOME/.pyenv/versions/demo/lib/python3.6/site-packages/cv2.cpython-36m-darwin.so"

### OPTIONAL: some housekeeping to free up space and old installations:
# rm -rf /opt/opencv3*
# rm -rf /opt/src

}

run

