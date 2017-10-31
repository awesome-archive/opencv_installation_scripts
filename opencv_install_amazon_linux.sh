#!/usr/bin/env bash
set -o errexit
set -o xtrace
set -o nounset
set -o pipefail

function run () {

NPROC=$(nproc)
EIGEN_VERSION='3.3.4'
OPENCV_VERSION='3.3.1'
PYTHON_VERSION='3.6.3'

sudo yum install -y libpng-devel libjpeg-turbo-devel jasper-devel \
    libtiff-devel libwebp-devel tbb-devel cmake openblas-devel \

find /opt/src -maxdepth 1 -type d -iname "opencv*" -exec rm -rf "{}" \;
find /opt/src -maxdepth 1 -type d -iname "eigen*" -exec rm -rf "{}" \;
find /opt/ -maxdepth 1 -type d -iname "opencv*" -exec rm -rf "{}" \;
find /opt/ -maxdepth 1 -type d -iname "eigen*" -exec rm -rf "{}" \;

if "pyenv" &> /dev/null; then
  echo "error: pyenv not installed properly"
  echo "info: install pyenv!"
  exit 1
fi

# install Python if it is not installed

if [[ `python --version` != "Python ${PYTHON_VERSION}" ]]; then
  echo "error: python installation failure"
  echo "info: check if pyenv is installed correctly"
  exit 1
fi

if [[ `which python` != "${HOME}/.pyenv/shims/python" ]]; then
  echo "error: failed to detect pyenv python"
  echo "info: check if pyenv is installed correctly"
  exit 1
fi

# step 3. install python dependencies
pip install -U pip setuptools
pip install -U wheel
pip install -U cython numpy

# step 4. build opencv
sudo mkdir -p /opt/src
sudo chown $(whoami) /opt
sudo chown $(whoami) /opt/src
cd /opt/src
# install eigen 3

if [[ ! -r "eigen_${EIGEN_VERSION}.zip" ]]; then
    echo "Cannot find eigen_${EIGEN_VERSION}.zip. Downloading..."
    curl -L "http://bitbucket.org/eigen/eigen/get/${EIGEN_VERSION}.zip" -o "eigen_${EIGEN_VERSION}.zip" 
fi

if [[ ! -r "opencv_${OPENCV_VERSION}.zip" ]]; then
    echo "Cannot find opencv_${OPENCV_VERSION}.zip. Downloading..."
    curl -L "https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip" -o "opencv_${OPENCV_VERSION}.zip"
fi
if [[ ! -r "opencv_contrib_${OPENCV_VERSION}.zip" ]]; then
    echo "Cannot find opencv_contrib_${OPENCV_VERSION}.zip. Downloading..."
    curl -L "https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip" -o "opencv_contrib_${OPENCV_VERSION}.zip"
fi

unzip eigen_${EIGEN_VERSION}.zip 
mv -v eigen-eigen* /opt/eigen_${EIGEN_VERSION}

unzip opencv_${OPENCV_VERSION}.zip 
mv -v opencv-${OPENCV_VERSION} /opt/src/opencv_${OPENCV_VERSION}_python_${PYTHON_VERSION}

unzip opencv_contrib_${OPENCV_VERSION}.zip
mv -v opencv_contrib-${OPENCV_VERSION} /opt/src/opencv_contrib_${OPENCV_VERSION}_python_${PYTHON_VERSION}

cd /opt/src/opencv_${OPENCV_VERSION}_python_${PYTHON_VERSION}
mkdir release
cd release

CFLAGS="-march=native -O2 -pipe" \
CXXFLAGS="-march=native -O2 -pipe" \
cmake \
-D CMAKE_INCLUDE_PATH="/opt/eigen_${EIGEN_VERSION}" \
-D CMAKE_INSTALL_PREFIX=/opt/opencv_${OPENCV_VERSION}_python_${PYTHON_VERSION} \
-D OPENCV_EXTRA_MODULES_PATH=/opt/src/opencv_contrib_${OPENCV_VERSION}_python_${PYTHON_VERSION}/modules \
-D BUILD_OPENCV_PYTHON2=OFF \
-D BUILD_OPENCV_PYTHON3=ON \
-D WITH_EIGEN=ON \
-D BUILD_TIFF=ON \
-D BUILD_OPENCV_JAVA=OFF \
-D BUILD_PERF_TESTS=OFF \
-D CMAKE_BUILD_TYPE=RELEASE \
-D PYTHON3_LIBRARY=$(python -c "import os.path; from distutils.sysconfig import get_config_var; print(os.path.join(get_config_var('LIBDIR'), get_config_var('LDLIBRARY')))") \
-D PYTHON3_EXECUTABLE=$(which python) \
-D PYTHON3_INCLUDE_DIR=$(python -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
-D PYTHON3_PACKAGES_PATH=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") ..
make -j${NPROC}
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

