#!/usr/bin/env bash
set -o errexit
set -o xtrace
set -o nounset
set -o pipefail

function run () {
# step 1. install brew (http://brew.sh)
if ! type "brew" > /dev/null; then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi
brew cleanup || true
brew update || true
brew upgrade || true
brew tap homebrew/science || true
brew install protobuf eigen openjpeg tbb hdf5 tesseract libjpeg-turbo libtiff libpng pyenv-virtualenv || true

if "pyenv" > /dev/null; then
  echo "error: pyenv not installed properly"
  echo "info: install pyenv!"
  exit 1
fi

# install Python 3.6.2 if it is not installed
# env PYTHON_CONFIGURE_OPTS="--enable-shared --enable-optimizations" pyenv install 3.6.2
# pyenv global 3.6.2

if [[ `python --version` != "Python 3.6.2" ]]; then
  echo "error: python installation failure"
  echo "info: check if pyenv is installed correctly"
  exit 1
fi

if [[ `which python` != "${HOME}/.pyenv/shims/python" ]]; then
  echo "error: failed to detect pyenv python"
  echo "info: check if pyenv is installed correctly"
  exit 1
fi

rm -rf /opt/src/opencv33_py36
rm -rf /opt/src/opencv33_py36_contrib

# step 3. install numpy
pip install -U pip setuptools wheel cython numpy

# step 4. build opencv
sudo mkdir -p /opt/src
sudo chown $(whoami):staff /opt
sudo chown $(whoami):staff /opt/src
cd /opt/src
if [[ ! -r "opencv33.zip" ]]; then
    echo "Cannot find opencv33.zip. Downloading..."
    curl -L https://github.com/opencv/opencv/archive/3.3.0.zip -o opencv33.zip
fi
if [[ ! -r "opencv33contrib.zip" ]]; then
    echo "Cannot find opencv33contrib.zip. Downloading..."
    curl -L https://github.com/opencv/opencv_contrib/archive/3.3.0.zip -o opencv33contrib.zip
fi
unzip opencv33.zip
unzip opencv33contrib.zip
mv -v opencv-3.3.0 /opt/src/opencv33_py36
mv -v opencv_contrib-3.3.0 /opt/src/opencv33_py36_contrib
cd /opt/src/opencv33_py36
mkdir /opt/src/opencv33_py36/release
cd /opt/src/opencv33_py36/release
cmake \
    -D CMAKE_INSTALL_PREFIX=/opt/opencv33_py36 \
    -D OPENCV_EXTRA_MODULES_PATH=/opt/src/opencv33_py36_contrib/modules \
    -D BUILD_OPENCV_PYTHON2=OFF \
    -D BUILD_OPENCV_PYTHON3=ON \
    -D BUILD_TIFF=ON \
    -D BUILD_OPENCV_JAVA=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D PYTHON3_LIBRARY=$(python -c "import re, os.path; print(os.path.normpath(os.path.join(os.path.dirname(re.__file__), '..', 'libpython3.6m.dylib')))") \
    -D PYTHON3_EXECUTABLE=$(which python) \
    -D PYTHON3_INCLUDE_DIR=$(python -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
    -D PYTHON3_PACKAGES_PATH=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") ..
    make -j8
    make install
    # Installs to: ~/.pyenv/versions/3.6.2/lib/python3.6/site-packages/cv2.cpython-36m-darwin.so
    
    ### Example installation for a virtual environment named "demo"
    # pyenv virtualenv 3.6.2 demo
    # pyenv global demo
    # pip install -U pip setuptools wheel numpy
    # ln -s "$HOME/.pyenv/versions/3.6.1/lib/python3.6/site-packages/cv2.cpython-36m-darwin.so" \
    #     "$HOME/.pyenv/versions/demo/lib/python3.6/site-packages/cv2.cpython-36m-darwin.so"
}
run
