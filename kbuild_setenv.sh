#!/bin/bash

BUILD_DIR=~/work/build

# Check if script is sourced
if [[ $0 = $BASH_SOURCE ]]; then
    echo "This script needs to be sourced"
    exit 1
fi

if [[ ! $1 ]]; then
    echo "Please specify a target"
    return 1
fi
target=$1

if [[ $2 ]]; then
    software=$2
else
    software=`cat README | awk 'NR == 1 {print $1}'`
    software=${software,,} # convert to lower case
    case $software in
        linux|barebox) ;;
        *)
            echo "Please specify a software name (probably u-boot...)"
            return 1;
    esac
fi

version=`grep '^VERSION =' Makefile | awk '{print $3}'`
patchlevel=`grep '^PATCHLEVEL =' Makefile | awk '{print $3}'`
if [[ $patchlevel ]]; then version+=.$patchlevel; fi
sublevel=`grep '^SUBLEVEL =' Makefile | awk '{print $3}'`
if [[ $sublevel ]]; then version+=.$sublevel; fi
extraversion=`grep '^EXTRAVERSION =' Makefile | awk '{print $3}'`
version+=$extraversion

# Linux kernel environment variables
case $target in
    cubox-i)
        export ARCH=arm
        export CROSS_COMPILE=arm-cortexa9_neon-linux-gnueabihf-
        export LOADADDR=10008000
        ;;
    beagle-x15)
        export ARCH=arm
        export CROSS_COMPILE=arm-cortex_a15-linux-gnueabihf-
        export LOADADDR=82000000
	;;
    am335x|beaglebone)
        export ARCH=arm
        export CROSS_COMPILE=arm-cortex_a8-linux-gnueabi-
        export LOADADDR=82000000
        ;;
    *)
        echo "Unknown target $target, aborting"
        return 1
esac

export MAKEFLAGS="-j $(nproc)"
export KBUILD_OUTPUT=$BUILD_DIR/$software-$version/$target
export INSTALL_MOD_PATH=.

mkdir -p $KBUILD_OUTPUT

function make_modules_tgz {
    make modules
    make modules_install
    kernel_version=`cat $KBUILD_OUTPUT/include/config/kernel.release`
    rm -f $KBUILD_OUTPUT/modules-$kernel_version.tar.gz
    tar czf $KBUILD_OUTPUT/modules-$kernel_version.tar.gz -C $KBUILD_OUTPUT lib/modules/$kernel_version --owner=0 --group=0
}

if [[ $software != linux* ]]; then unset make_modules_tgz; fi
