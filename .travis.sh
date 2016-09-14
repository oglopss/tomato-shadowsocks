# Add current directory to PATH
export PATH="$(pwd):$(pwd)/crosstool-ng:$PATH"
export PATH=$HOME/x-tools/mipsel-unknown-linux-uclibc/bin:$PATH
mkdir -p $HOME/src

# Manage the travis build
ct-ng_travis_build()
{
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
}

pcre_build()
{
cd $HOME/src
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre2-10.20.tar.gz
# wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.38.tar.gz
tar xvf pcre2-10.20.tar.gz
# tar xvf pcre-8.38.tar.gz
cd pcre*
CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./configure --host=mipsel-uclibc-linux --disable-cpp --prefix=$HOME/pcre-install
make > /dev/null 2>&1
make install > /dev/null 2>&1

}

openssl_build()
{
    cd $HOME/src
    wget https://www.openssl.org/source/openssl-1.0.2g.tar.gz
    tar xvf openssl-1.0.2g.tar.gz -C ../
    cd ../openssl*
    # git checkout tags/OpenSSL_1_0_2g
    CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./Configure no-asm shared --prefix=$HOME/openssl-install linux-mips32 &> /dev/null
    make > /dev/null 2>&1
    make install > /dev/null 2>&1

}

zlib_build()
{
    cd $HOME/src
    wget http://zlib.net/zlib-1.2.8.tar.gz
    # export PATH=$HOME/x-tools/mipsel-unknown-linux-uclibc/bin:$PATH
    tar xf zlib-1.2.8.tar.gz -C ../
    cd ../zlib-1.2.8*
    CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./configure --prefix=$HOME/zlib-install &> /dev/null
    make > /dev/null 2>&1
    make install > /dev/null 2>&1


}

err_report() {
    echo "Error on line $1"
}

trap 'err_report $LINENO' ERR

ss_build()
{

    # Build the sample
    echo In ss_build ...
    echo path: $PATH
    echo ========home=========
    ls -l $HOME
    echo ========home/build=========
    ls -l $HOME/build
    echo ========home/builds=========
    ls -l $HOME/builds    
    echo ========home/x-tools=========
    ls -l $HOME/x-tools   
    echo ========home/x-tools/mipsel-unknown-linux-uclibc=========
    ls -l $HOME/x-tools/mipsel-unknown-linux-uclibc    
    
    
    echo ========TRAVIS_BUILD_DIR=========
    ls -l $TRAVIS_BUILD_DIR

    echo ========/usr=========
    ls -l /usr
    echo ========/usr/include=========
    ls -l /usr/include    
    echo ========/usr/lib=========
    ls -l /usr/lib     
    echo ========/usr/lib64=========
    ls -l /usr/lib64     
    echo ========/usr/local=========
    ls -l /usr/local 
    echo ========pcre-config=========
    which pcre-config
    
    ls -l $HOME/x-tools/mipsel-unknown-linux-uclibc/bin
    cd $TRAVIS_BUILD_DIR/shadowsocks-libev
    if [ "$SS_VER" == "latest" ]; then
        id=$(git rev-parse HEAD)
        SS_VER=vsnapshot-${id:0:5}
    else    
        git checkout tags/$SS_VER

    fi

    
    CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./configure --disable-ssp --host=mipsel-uclibc-linux --prefix=$HOME/ss-install --with-openssl=$HOME/openssl-install --with-zlib=$HOME/zlib-install --with-pcre==$HOME/pcre-install
    make > /dev/null 
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
    # exclude ss-nat new in 2.4.7
    # mipsel-unknown-linux-uclibc-strip $HOME/ss-install/bin/*
    find $HOME/ss-install/bin -type f \( ! -iname "ss-nat" \) -execdir mipsel-unknown-linux-uclibc-strip {} \;
    
    # upx files
    printf "upx files ...\r"
    rm -rf $HOME/src/upx-*
    # wget http://upx.sourceforge.net/download/upx-3.91-amd64_linux.tar.bz2 -P $HOME/src
    # tar xf $HOME/src/upx-3.91-amd64_linux.tar.bz2 -C $HOME
    curl http://upx.sourceforge.net/download/upx-3.91-amd64_linux.tar.bz2 | tar xj -C $HOME
    cd $HOME/upx-*
    # ./upx $HOME/ss-install/bin/*
    find $HOME/ss-install/bin -type f \( ! -iname "ss-nat" \) -execdir ./upx {} \;
    cd $HOME/ss-install/bin/

    printf "compress files ...\r"
    # rm -rf
    tar -zcvf shadowsocks-libev-$SS_VER.tar.gz *
    # Return the result
    return $result
}
