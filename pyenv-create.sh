#!/usr/bin/env bash

#echo "usage: ./${0##*/} <env-name>"

STARTING_DIR=`pwd`

export ENV_NAME=$1

if [[ -z "${ENV_NAME}" ]]; then
    ENV_NAME='pyslam'
fi

ENVS_PATH=~/.python/venvs  # path where to group virtual environments 
ENV_PATH=$ENVS_PATH/$ENV_NAME        # path of the virtual environment we are creating 

# ====================================================
# import the utils 
. bash_utils.sh 

# ====================================================

version=$(lsb_release -a 2>&1)  # ubuntu version 


sudo apt update 
sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev unzip
sudo apt-get install -y libavcodec-dev libavformat-dev libavutil-dev libpostproc-dev libswscale-dev ffmpeg 
sudo apt-get install -y libgtk2.0-dev 
sudo apt-get install -y libglew-dev
sudo apt-get install -y libsuitesparse-dev

# https://github.com/pyenv/pyenv/issues/1889
export CUSTOM_CC_OPTIONS=""
if [[ $version == *"22.04"* ]] ; then
    sudo apt install -y clang
    CUSTOM_CC_OPTIONS="CC=clang " 
fi 

# install required package to create virtual environment
install_package python3-venv
. install_pyenv.sh 

# create folder for virutal environment and get into it 
make_dir $ENV_PATH
cd $ENVS_PATH

export PYSLAM_PYTHON_VERSION="3.6.9"

# actually create the virtual environment 
if [ ! -d $ENV_PATH/bin ]; then 
    print_blue creating virtual environment $ENV_NAME with python version $PYSLAM_PYTHON_VERSION
    eval "$CUSTOM_CC_OPTIONS pyenv install -v $PYSLAM_PYTHON_VERSION"
    pyenv local $PYSLAM_PYTHON_VERSION
    python3 -m venv $ENV_NAME
fi 

# activate the environment 
cd $STARTING_DIR
export PYTHONPATH=""   # clean python path => for me, remove ROS stuff 
source $ENV_PATH/bin/activate  

pip3 install --upgrade pip setuptools wheel --no-cache-dir
if [ -d ~/.cache/pip/selfcheck ]; then
    rm -r ~/.cache/pip/selfcheck/
fi 

print_blue "installing opencv"

PRE_OPTION="--pre"   # this sometimes helps because a pre-release version of the package might have a wheel available for our version of Python.
MAKEFLAGS_OPTION="-j$(nproc)" 
CMAKE_ARGS_OPTION="-DOPENCV_ENABLE_NONFREE=ON" # install nonfree modules

MAKEFLAGS="$MAKEFLAGS_OPTION" CMAKE_ARGS="$CMAKE_ARGS_OPTION" pip3 install opencv-python -vvv $PRE_OPTION
MAKEFLAGS="$MAKEFLAGS_OPTION" CMAKE_ARGS="$CMAKE_ARGS_OPTION" pip3 install opencv-contrib-python -vvv $PRE_OPTION

# install required packages 

#source install_pip3_packages.sh 
# or 
MAKEFLAGS="$MAKEFLAGS_OPTION" pip3 install -r requirements-pip3.txt -vvv

# HACK to fix opencv-contrib-python version!
#pip3 uninstall opencv-contrib-python                # better to clean it before installing the right version 
#install_pip_package opencv-contrib-python #==3.4.2.16 

# N.B.: in order to activate the virtual environment run: 
# $ source pyenv-activate.sh 
# to deactivate 
# $ deactivate 
