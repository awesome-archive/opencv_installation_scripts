# Python 3.x, OpenCV 3.x, macOS & Linux Installation Scripts

This script WILL use pyenv and build everything from scratch if necessary.

Deactivate your exiting Pythons or you will run into big trouble unless you know exactly
what you are doing.

IMPORTANT! Allocate 1 GB combined RAM and swap at the minimum to compile OpenCV or your compiler and machine will explode and catch on fire!

The macOS script is up-to-date!

The Amazon Linux script could use some clean ups.

Ubuntu scripts are outdated but easily adapted and should still work fine.

## How do I use multiple virtual environments?

Let's assume you are using Python 3.6.x and you want to use OpenCV in another virtual environment. The default build puts it in the "opencv" virtual environment.

The script defaults installation to `~/.pyenv/versions/${PYTHON_VERSION}/lib/python3.6/site-packages/cv2*` for Python 3.6.x

If you want to use a different virtual environment, create it:
    
    pyenv virtualenv 3.6.3 MY_VIRTUAL_ENVIRONMENT_NAME_GOES_HERE

Change to it:

    pyenv global MY_VIRTUAL_ENVIRONMENT_NAME_GOES_HERE

Install the same version of numpy you used to build OpenCV. I am assuming you built OpenCV recently, so the newest numpy is still ABI compatible. This is a big assumption! Be aware.

    pip3 install -U pip setuptools wheel numpy

Make that symbolic link!

    ln -s "$HOME/.pyenv/versions/${PYTHON_VERSION}/lib/python3.6/site-packages/cv2.cpython-36m-darwin.so" \
          "$HOME/.pyenv/versions/${MY_VIRTUAL_ENVIRONMENT_NAME}/lib/python3.6/site-packages/cv2.cpython-36m-darwin.so"

