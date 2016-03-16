# Add current directory to PATH
export PATH="$(pwd):$(pwd)/crosstool-ng:$PATH"
# export PATH=$HOME/x-tools/mipsel-unknown-linux-uclibc/bin:$PATH
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
    cp $TRAVIS_BUILD_DIR/uclibc-0.9.33.2.config ./
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

openssl_build()
{
    cd $HOME/src
    wget https://www.openssl.org/source/openssl-1.0.2g.tar.gz
    tar xvf openssl-1.0.2g.tar.gz -C ../
    cd ../openssl*
    # git checkout tags/OpenSSL_1_0_2g
    CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./Configure no-asm shared --prefix=$HOME/openssl-install linux-mips32 &> /dev/null
    make &> /dev/null
    make install &> /dev/null

}

zlib_build()
{
    cd $HOME/src
    wget http://zlib.net/zlib-1.2.8.tar.gz
    # export PATH=$HOME/x-tools/mipsel-unknown-linux-uclibc/bin:$PATH
    tar xf zlib-1.2.8.tar.gz -C ../
    cd ../zlib-1.2.8*
    CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./configure --prefix=$HOME/zlib-install &> /dev/null
    make &> /dev/null
    make install &> /dev/null


}



ss_build()
{

    # Build the sample
    cd $TRAVIS_BUILD_DIR/shadowsocks-libev
    git checkout tags/v2.4.5
    CC=mipsel-unknown-linux-uclibc-gcc CXX=mipsel-unknown-linux-uclibc-g++ AR=mipsel-unknown-linux-uclibc-ar RANLIB=mipsel-unknown-linux-uclibc-ranlib ./configure --disable-ssp --host=mipsel-uclibc-linux --prefix=$HOME/ss-install --with-openssl=$HOME/openssl-install --host=mipsel-uclibc-linux --with-zlib=$HOME/zlib-install &> /dev/null
    make &> /dev/null
    make install &> /dev/null
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
    mipsel-unknown-linux-uclibc-strip $HOME/ss-install/bin/*
    # upx files
    printf "upx files ...\r"
    rm -rf $HOME/src/upx-*
    # wget http://upx.sourceforge.net/download/upx-3.91-amd64_linux.tar.bz2 -P $HOME/src
    # tar xf $HOME/src/upx-3.91-amd64_linux.tar.bz2 -C $HOME
    curl http://upx.sourceforge.net/download/upx-3.91-amd64_linux.tar.bz2 | tar xj -C $HOME
    cd $HOME/upx-*
    ./upx $HOME/ss-install/bin/*
    cd $HOME/ss-install/bin/

    printf "compress files ...\r"
    # rm -rf
    tar -zcvf shadowsocks-libev-2.4.5.tar.gz *
    # Return the result
    return $result
}
