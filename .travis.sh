#!/usr/bin/env bash

# Add current directory to PATH
export PATH="$(pwd):$(pwd)/crosstool-ng:$PATH"
export PATH=$HOME/x-tools/mipsel-unknown-linux-uclibc/bin:$PATH

# for testing, disable after releasing
#export SS_VER=v3.0.0
#export TRAVIS_BUILD_DIR=/home/travis/builds/oglopss/tomato-shadowsocks

export OUT="> /dev/null 2>&1"

export ZLIB_VER=1.2.11
export OPENSSL_VER=1.0.2k

export PCRE_VER=8.40
export LIBSODIUM_VER=1.0.11
export MBEDTLS_VER=2.4.0
export UDNS_VER=0.4

# using the same ver as in entware 02/14/2017
# libev - 4.20-1 - A full-featured and high-performance event loop that is loosely modelled after libevent, but without its limitations and bugs.
export LIBEV_VER=4.20

mkdir -p $HOME/src

# Manage the travis build
ct-ng_travis_build()
{
    # check if toolchain is already in cache
    if [ ! -d "$HOME/x-tools/mipsel-unknown-linux-uclibc/bin" ]; then


    ct-ng $CT_SAMPLE

    # Override the log behaviour
    sed -i -e 's/^.*\(CT_LOG_ERROR\).*$/# \1 is not set/' \
        -e 's/^.*\(CT_LOG_WARN\).*$/# \1 is not set/' \
        -e 's/^.*\(CT_LOG_INFO\).*$/# \1 is not set/' \
        -e 's/^.*\(CT_LOG_EXTRA\).*$/\1=y/' \
        -e 's/^.*\(CT_LOG_ALL\).*$/# \1 is not set/' \
        -e 's/^.*\(CT_LOG_DEBUG\).*$/# \1 is not set/' \
        -e 's/^.*\(CT_LOG_LEVEL_MAX\).*$/\1="EXTRA"/' \
        -e 's/^.*\(CT_LOG_PROGRESS_BAR\).*$/# \1 is not set/' \
        -e 's/^.*\(CT_LOCAL_TARBALLS_DIR\).*$/\1="${HOME}\/src"/' \
        -e 's/^.*\(CT_SAVE_TARBALLS\).*$/\1=y/' \
        .config


    mkdir -p $TRAVIS_BUILD_DIR/config
    cd $TRAVIS_BUILD_DIR/config
    cp $TRAVIS_BUILD_DIR/uclibc.config ./
    cp $TRAVIS_BUILD_DIR/ctng.config ./.config

    # Build the sample
    ct-ng build.2 &
    local build_pid=$!

    # Start a runner task to print a "still running" line every 5 minutes
    # to avoid travis to think that the build is stuck
    {
        while true
        do
            sleep 300
            printf "Crosstool-NG is still running ...\r"
        done
    } &
    local runner_pid=$!

    # Wait for the build to finish and get the result
    wait $build_pid 2>/dev/null 
    local result=$?

    # Stop the runner task
    kill $runner_pid
    wait $runner_pid 2>/dev/null

    # Return the result
    return $result

fi
}

pcre_build()
{
    echo ========= pcre_build =========

    cd $HOME/src

    # export PCRE_VER=8.40
    wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$PCRE_VER.tar.gz
    tar xf pcre-$PCRE_VER.tar.gz
    cd pcre-$PCRE_VER

    CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./configure --host=mipsel-uclibc-linux --disable-cpp --prefix=$HOME/pcre-install

    make > /dev/null 2>&1

    rm -rf $HOME/pcre-install
    
    make install > /dev/null 2>&1


# echo ========$HOME/pcre-install=========
# ls -l $HOME/pcre-install 
# echo ========$HOME/pcre-install/include=========
# ls -l $HOME/pcre-install/include
# echo ========pcre-config  --prefix=========
# pcre-config  --prefix
}

openssl_build()
{

    echo ========= openssl_build =========
    cd $HOME/src
    wget https://www.openssl.org/source/openssl-$OPENSSL_VER.tar.gz
    tar xf openssl-$OPENSSL_VER.tar.gz -C ../
    cd ../openssl-$OPENSSL_VER
    # git checkout tags/OpenSSL_1_0_2g
    CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./Configure no-asm shared --prefix=$HOME/openssl-install linux-mips32 &> /dev/null
    make > /dev/null 2>&1
    rm -rf $HOME/openssl-install

    make install > /dev/null 2>&1

}

zlib_build()
{
    cd $HOME/src
    wget http://zlib.net/zlib-$ZLIB_VER.tar.gz
    # export PATH=$HOME/x-tools/mipsel-unknown-linux-uclibc/bin:$PATH
    tar xf zlib-$ZLIB_VER.tar.gz -C ../
    cd ../zlib-$ZLIB_VER
    CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./configure --prefix=$HOME/zlib-install &> /dev/null
    make > /dev/null 2>&1

    rm -rf $HOME/zlib-install
    make install > /dev/null 2>&1


}

# new builds for ss 3.0 or above

libsodium_build()
{

    echo ========= libsodium_build =========
    cd $TRAVIS_BUILD_DIR
    cd $HOME/src
    # export LIBSODIUM_VER=1.0.11
    # this does not work inside container
    #wget http://download.libsodium.org/libsodium/releases/libsodium-$LIBSODIUM_VER.tar.gz

    # http://stackoverflow.com/questions/30418188/how-to-force-wget-to-overwrite-an-existing-file-ignoring-timestamp
    wget --backups=1 https://github.com/jedisct1/libsodium/releases/download/$LIBSODIUM_VER/libsodium-$LIBSODIUM_VER.tar.gz


    tar xf libsodium-$LIBSODIUM_VER.tar.gz
    cd libsodium-$LIBSODIUM_VER
 
    CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib  ./configure --prefix=$HOME/libsodium-install --host=mipsel-uclibc-linux
 
    make  > /dev/null 2>&1

    rm -rf $HOME/libsodium-install
    make install  > /dev/null 2>&1

 
    # popd
    # popd

}

mbedtls_build()
{

    echo ========= mbedtls_build =========
    cd $TRAVIS_BUILD_DIR
    cd $HOME/src

    # export MBEDTLS_VER=2.4.0
    wget  --backups=1 https://tls.mbed.org/download/mbedtls-$MBEDTLS_VER-gpl.tgz
    tar xf mbedtls-$MBEDTLS_VER-gpl.tgz
    cd mbedtls-$MBEDTLS_VER

    # echo === current cflags ="$CFLAGS"=
    make clean
    
    CC="mipsel-unknown-linux-uclibc-gcc -fPIC" CXX="mipsel-unknown-linux-uclibc-g++ -fPIC" AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib make SHARED=1 # CFLAGS=-fPIC

    
    # CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib make # SHARED=1 CFLAGS=-fPIC



    # > /dev/null 2>&1
    rm -rf $HOME/mbedtls-install
 
    make install DESTDIR=$HOME/mbedtls-install > /dev/null 2>&1
 
    echo ========= mbedtls_build done =========
    ls -l $HOME/mbedtls-install/lib
    # popd
    # popd
}


udns_build()
{
    echo ========udns_build=========
    #pushd $TRAVIS_BUILD_DIR
    cd $HOME/src
    # export UDNS_VER=0.4
    wget --backups=1 http://www.corpit.ru/mjt/udns/udns-$UDNS_VER.tar.gz
    tar xf udns-$UDNS_VER.tar.gz
    cd udns-$UDNS_VER
 
    echo apply udns patch
    ls -l $TRAVIS_BUILD_DIR/udns-configure.lib.patch
    # apply patch
    patch -p1 < $TRAVIS_BUILD_DIR/udns-configure.lib.patch
    
    #cat ./configure.lib
    echo running udns configure
    
    # make clean
    
    CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./configure
    
    make clean
    
    echo ======== udns make=============
    #ls -l 
    
    make
    
    echo ======== after udns make=============
    pwd
    ls -l
    # popd
    #popd
}


libev_build()
{
    echo ========libev_build=========
    cd $TRAVIS_BUILD_DIR
    cd $HOME/src
    # git clone https://github.com/enki/libev.git

    wget --backups=1 http://dist.schmorp.de/libev/Attic/libev-$LIBEV_VER.tar.gz

    tar xf libev-$LIBEV_VER.tar.gz

    # cd libev
    cd libev-$LIBEV_VER
    
    CPPFLAGS="-I$HOME/src/udns-$UDNS_VER" LDFLAGS="-L$HOME/src/udns-$UDNS_VER" CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./configure --prefix=$HOME/libev-install --host=mipsel-uclibc-linux
    make

    rm -rf $HOME/libev-install

    make install
    # popd
}

err_report() {
    echo "Error on line $1"
}

trap 'err_report $LINENO' ERR

ss_build()
{

    # Build the sample
    echo  ======ss_build======
    echo path: $PATH
    echo ========home=========
    ls -l $HOME
    echo ========home/build=========
    ls -l $HOME/build
    echo ========home/builds=========
    ls -l $HOME/builds    
    echo ========home/x-tools=========
    ls -l $HOME/x-tools   
    # echo ========home/x-tools/mipsel-unknown-linux-uclibc=========
    # ls -l $HOME/x-tools/mipsel-unknown-linux-uclibc    
    
    
    echo ========TRAVIS_BUILD_DIR=========
    ls -l $TRAVIS_BUILD_DIR

    # echo ========/usr=========
    # ls -l /usr
    # echo ========/usr/include=========
    # ls -l /usr/include    
    # echo ========/usr/lib=========
    # ls -l /usr/lib     qwerty
    echo ========$HOME/pcre-install=========
    ls -l $HOME/pcre-install 
    # echo ========/usr/local=========
    # ls -l /usr/local 
    # echo ========pcre-config=========
    # which pcre-config
    # echo ========$HOME/pcre-install/include=========
    # ls -l $HOME/pcre-install/include   
    # echo ========$HOME/pcre-install/lib=========
    # ls -l $HOME/pcre-install/lib  

    echo ========mipsel-unknown-linux-uclibc=========
    ls -l $HOME/x-tools/mipsel-unknown-linux-uclibc

    echo ========mipsel-unknown-linux-uclibc/bin=========
    ls -l $HOME/x-tools/mipsel-unknown-linux-uclibc/bin

    echo ========$TRAVIS_BUILD_DIR=========
    echo $TRAVIS_BUILD_DIR
    ls -l $TRAVIS_BUILD_DIR
    
    # go into ss dir
    cd $TRAVIS_BUILD_DIR/shadowsocks-libev


    # pcre_config="--with-pcre=$HOME/pcre-install"

    if [ "$SS_VER" == "latest" ]; then
        id=$(git rev-parse HEAD)
        SS_VER=vsnapshot-${id: -5}
    else    

        # http://stackoverflow.com/questions/229551/string-contains-in-bash

        # if [[ $SS_VER == *"nopcre"* ]]; then
        #     pcre_config="--without-libpcre"
        # fi

        # if [[ $SS_VER == *"_"* ]]; then
        #     SS_VER=${SS_VER%_*}
        # fi


        echo ================= will checkout SS_VER ================
        echo $SS_VER

        git checkout -f tags/$SS_VER
        git clean -xfd
    fi

    # echo ================= before ss-config ================

    # echo $pcre_config

    # config_cmd="CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./configure --disable-ssp --host=mipsel-uclibc-linux --prefix=$HOME/ss-install --with-openssl=$HOME/openssl-install --with-zlib=$HOME/zlib-install $pcre_config"

    # echo "$config_cmd"

    # eval "$config_cmd"
    # echo ======== this time is real ==========

    git clean -xfd
    git submodule update --init
    git submodule update --recursive
    
    # pcre_build
    
    # always build pcre
    #if [ ! -d "$HOME/pcre-install" ]; then
        pcre_build
    #fi
        zlib_build

        # openssl_build


    SS_VER_INT=${SS_VER#v}
    SS_VER_INT=${SS_VER_INT//./}

    if [  "${SS_VER:0:5}" == "vsnap" ]; then
        SS_VER_INT=999
    fi
    
    cd $TRAVIS_BUILD_DIR/shadowsocks-libev

   # backport issue 1306
    if [ "$SS_VER_INT" -ge 263 ] && [ "$SS_VER_INT" -le 303 ]; then
        cd $TRAVIS_BUILD_DIR/shadowsocks-libev
        # git cherry-pick 5b122d4f8ce02dfea0848fe7e0fff43ccf0d69ff
        git diff 5b122d4^ 5b122d4 | git apply
        
    fi


    if [ -f "autogen.sh" ]; then
        echo running autogen
        ./autogen.sh
    fi
    



    echo ====== "$SS_VER_INT"
    
    if [ "$SS_VER_INT" -ge 263 ]; then 
    
        echo ========new build v3 =========
        #echo current dir 
        #pwd

        #pwd
        #echo current ss dir contents
        #ls -l
        
        #if [ -x "autogen.sh" ]; then
            # echo running autogen
            # ./autogen.sh
        #fi
        #echo after autogen
        #ls -l
        
         # zlib_build
         
        # build other dependencies
        # if [ ! -d "$HOME/libsodium-install" ]; then
            libsodium_build
        #else
        #fi

        #if [ ! -d "$HOME/mbedtls-install" ]; then
            mbedtls_build
        #fi

        #if [ ! -d "$HOME/src/udns-$UDNS_VER" ]; then
            udns_build
        #fi

        #if [ ! -d "$HOME/libev-install" ]; then
            libev_build
        #fi
        # echo ================ running configure for ss
        
        cd $TRAVIS_BUILD_DIR/shadowsocks-libev
    
        #ls -l
        
        echo udns check
        ls -l $HOME/src/udns-$UDNS_VER
        
        # echo --------



        if [ "$SS_VER_INT" = 263 ] || [ "$SS_VER_INT" = 999 ]; then

            echo 263 or 999 use openssl

            openssl_build
            
            cd $TRAVIS_BUILD_DIR/shadowsocks-libev

            CPPFLAGS="-I$HOME/src/udns-$UDNS_VER -I$HOME/libev-install/include -I$HOME/zlib-install/include -I$HOME/openssl-install/include " LDFLAGS="-Wl,-rpath,/jffs/lib -L$HOME/src/udns-$UDNS_VER -L$HOME/libev-install/lib -L$HOME/zlib-install/lib -L$HOME/openssl-install/lib" CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./configure --disable-ssp --prefix=$HOME/ss-install --with-pcre=$HOME/pcre-install --with-sodium=$HOME/libsodium-install --with-mbedtls=$HOME/mbedtls-install --host=mipsel-uclibc-linux

        else

            echo greater or equal to 263, use mbedtls
            CPPFLAGS="-I$HOME/src/udns-$UDNS_VER -I$HOME/libev-install/include -I$HOME/zlib-install/include" LDFLAGS="-Wl,-rpath,/jffs/lib -L$HOME/src/udns-$UDNS_VER -L$HOME/libev-install/lib -L$HOME/zlib-install/lib" CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./configure --disable-ssp --prefix=$HOME/ss-install --with-pcre=$HOME/pcre-install --with-sodium=$HOME/libsodium-install --with-mbedtls=$HOME/mbedtls-install --host=mipsel-uclibc-linux
    
        fi

        echo -=-=-==-=-=-=-=-=-=-=

    else
        # for ss < 3.0
        echo ========old ss build v2 =========
        
        #if [ ! -d "$HOME/zlib-install" ]; then
            # zlib_build
        #fi

        #if [ ! -d "$HOME/openssl-install" ]; then
            # openssl_build
        #fi

        openssl_build
#         if [ "$SS_VER" == "v2.6.3" ]; then
#             libsodium_build
#             mbedtls_build
#             udns_build
#             libev_build
#         fi
        
        cd $TRAVIS_BUILD_DIR/shadowsocks-libev

#         export CPPFLAGS="$CPPFLAGS -I$HOME/libsodium-install/include -I$HOME/src/udns-$UDNS_VER -I$HOME/openssl-install/include -I$HOME/libev-install/include"
#         export LDFLAGS="$LDFLAGS -Wl,-rpath,/opt/lib:/lib:/usr/lib -L$HOME/libsodium-install/lib -L$HOME/src/udns-$UDNS_VER -L$HOME/libev-install/lib"

        LDFLAGS="$LDFLAGS -Wl,-rpath,/jffs/lib" CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./configure --disable-ssp --host=mipsel-uclibc-linux --prefix=$HOME/ss-install --with-openssl=$HOME/openssl-install --with-zlib=$HOME/zlib-install --with-pcre=$HOME/pcre-install --with-sodium=$HOME/libsodium-install --with-mbedtls=$HOME/mbedtls-install
        
    fi

    echo ========= ss_build make ===========
    ls -l
    make #> /dev/null
    

    if [ -d "$HOME/ss-install" ]; then
        rm -rf $HOME/ss-install
    fi

    echo ========= ss_build make install ===========
    make install > /dev/null
    local result=$?
    # local build_pid=$!

    # # Start a runner task to print a "still running" line every 5 minutes
    # # to avoid travis to think that the build is stuck
    # {
    #     while true
    #     do
    #         sleep 300
    #         printf "ss is still running ...\r"
    #     done
    # } &
    # local runner_pid=$!

    # # Wait for the build to finish and get the result
    # wait $build_pid 2>/dev/null
    # local result=$?

    # # Stop the runner task
    # kill $runner_pid
    # wait $runner_pid 2>/dev/null


    # strip files
    printf "strip files ...\r"
    echo ========$path=========
    echo before: "$PATH"
    # http://stackoverflow.com/questions/13710806/string-replace-this-shell-variable
    PATH=${PATH/:.\/node_modules\/.bin}

    echo after: "$PATH"

    # exclude ss-nat new in 2.4.7
    # mipsel-unknown-linux-uclibc-strip $HOME/ss-install/bin/*
    find $HOME/ss-install/bin -type f \( ! -iname "ss-nat" \) -execdir mipsel-unknown-linux-uclibc-strip {} \;
    
    # upx files
    printf "upx files ...\r"
    rm -rf $HOME/src/upx-*
    # wget http://upx.sourceforge.net/download/upx-3.91-amd64_linux.tar.bz2 -P $HOME/src
    # tar xf $HOME/src/upx-3.91-amd64_linux.tar.bz2 -C $HOME

    # http://www.shellhacks.com/en/HowTo-Download-and-Extract-untar-TAR-Archive-with-One-Command
    curl http://upx.sourceforge.net/download/upx-3.91-amd64_linux.tar.bz2 | tar xj -C $HOME
    cd $HOME/upx-*

    echo ========$HOME/upx-*=========
    pwd
    ls -l


    # ./upx $HOME/ss-install/bin/*
    find $HOME/ss-install/bin -type f \( ! -iname "ss-nat" \) -exec ./upx {} \;
    cd $HOME/ss-install/bin/


    # copy so files
    if [ "$SS_VER_INT" -ge 263 ]; then 

        cp $HOME/mbedtls-install/lib/libmbedcrypto.so.0 .
        cp $HOME/libev-install/lib/libev.so.4 .
        cp $HOME/libsodium-install/lib/libsodium.so.18 .

        # if [ "$SS_VER_INT" -eq 263 ] || [ "$SS_VER_INT" -eq 999 ]; then
        #     cp $HOME/openssl-install/lib/libcrypto.so.1.0.0 .
        # fi


    # else
    #     cp $HOME/openssl-install/lib/libcrypto.so.1.0.0 .

    # fi


    # strip them as well
    mipsel-unknown-linux-uclibc-strip ./*so*

    echo ========final sizes =========
    ls -l --block-size=K

    printf "compress files ...\r"
    # rm -rf
    tar -zcvf shadowsocks-libev-$SS_VER.tar.gz *

    # popd

    # Return the result
    return $result
}
