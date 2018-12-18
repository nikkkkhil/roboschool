#! /bin/bash

set -x
cd $(dirname "$0")

. ./exports.sh

pip install cmake

if [ $(uname) == 'Linux' ]; then
#     QT5_BIN=qt5.6.0_centos5_2018-12-11.tar.gz
#     cd $CPP_HOUSEHOLD
#     curl -OL https://storage.googleapis.com/games-src/qt5/$QT5_BIN
#     tar -xf $QT5_BIN
#     rm -rf $QT5_BIN

#     ASSIMP_SRCDIR=$TMPDIR/assimp
#     mkdir -p $ASSIMP_SRCDIR && cd $ASSIMP_SRCDIR
#     curl https://codeload.github.com/assimp/assimp/tar.gz/v4.1.0 -o assimp-4.1.0.tar.gz
#     tar -xf assimp-4.1.0.tar.gz
#     cd assimp-4.1.0
#     cmake -DCMAKE_INSTALL_PREFIX:PATH=$CPP_HOUSEHOLD/assimp_local_install 
#     # cmake . 
#     make -j4 > $TMPDIR/assimp_make.log || tail -100 $TMPDIR/assimp_make.log
#     make install 
#     cd $ROBOSCHOOL_PATH

    BOOST_SRCDIR=$TMPDIR/boost
    mkdir -p $BOOST_SRCDIR && cd $BOOST_SRCDIR
    curl -OL https://storage.googleapis.com/games-src/boost/boost_1_58_0.tar.bz2
    tar -xf boost_1_58_0.tar.bz2
    cd boost_1_58_0

     # ./bootstrap.sh --with-python=$(which python) --with-libraries=python 
     ./bootstrap.sh --with-python=$(which python) --with-libraries=python
     ./b2 install > $TMPDIR/boost_make.log || (tail -100 $TMPDIR/boost_make.log; exit 1)
fi

if [ $(uname) == 'Darwin' ]; then
    brew install boost-python3
fi

BULLET_SRCDIR=$TMPDIR/bullet3
rm -rf $BULLET_SRCDIR
mkdir -p $BULLET_SRCDIR && cd $BULLET_SRCDIR
git clone https://github.com/olegklimov/bullet3 -b roboschool_self_collision .

mkdir build && cd build
cmake -DBUILD_SHARED_LIBS=ON -DUSE_DOUBLE_PRECISION=1 -DCMAKE_INSTALL_PREFIX:PATH=$TMPDIR/bullet_local_install -DBUILD_CPU_DEMOS=OFF -DBUILD_BULLET2_DEMOS=OFF -DBUILD_EXTRAS=OFF  -DBUILD_UNIT_TESTS=OFF -DBUILD_CLSOCKET=OFF -DBUILD_ENET=OFF -DBUILD_OPENGL3_DEMOS=OFF ..

make -j4 > $TMPDIR/bullet_make.log || (tail -100 $TMPDIR/bullet_make.log; exit 1)
make install > $TMPDIR/bullet_install.log || (tail -100 $TMPDIR/bullet_install.log; exit 1)

if [ $(uname) == 'Darwin' ]; then
    
    for lib in $(find $TMPDIR/bullet_local_install/lib -name "*.dylib"); do
        install_name_tool -id $lib $lib
        for dep in $(otool -L $lib | grep "@rpath" | awk '{print $1}'); do 
            install_name_tool -change $dep "$TMPDIR/bullet_local_install/lib/${dep##@rpath/}" $lib
        done
    done
fi
if [ $(uname) == 'Linux' ]; then
    
    for lib in $(find $TMPDIR/bullet_local_install/lib -name "*.so.2.87"); do
        patchelf --set-rpath=$TMPDIR/bullet_local_install/lib $lib
    done
fi

cd $ROBOSCHOOL_PATH
./roboschool_compile_and_graft.sh

