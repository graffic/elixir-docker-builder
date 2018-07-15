FROM arm32v7/ubuntu:bionic
#FROM ubuntu:bionic
ENV LANG=C.UTF-8 \
    ERLANG_VER=21.0.3 \
    ELIXIR_VER=1.6.6
    
RUN apt-get update && \
    apt install -y curl autoconf gcc make unixodbc-dev ncurses-dev libssl-dev && \
    # Download, build and install Erlang
    curl -LO https://github.com/erlang/otp/archive/OTP-${ERLANG_VER}.tar.gz && \
    tar xzf OTP-${ERLANG_VER}.tar.gz && \
    cd otp-OTP-${ERLANG_VER} && \
    ./otp_build autoconf && \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --mandir=/usr/share/man \
        --localstatedir=/var \
        # wx needs a GUI
        --without-wx \
        # observer depends on wx
        --without-observer \
        # orber needs a c++ compiler
        --without-orber \
        # jinterface needs java
        --without-jinterface \
        # debugger depends on wx
        --without-debugger \
        # et depends on wx
        --without-et && \
    make clean && make && make install && \
    cd .. && \
    rm -rf otp-OTP-${ERLANG_VER} OTP-${ERLANG_VER}.tar.gz && \
    # Download, build and install Elixir
    curl -Lo elixir-${ELIXIR_VER}.tar.gz https://github.com/elixir-lang/elixir/archive/v${ELIXIR_VER}.tar.gz && \
    tar xzf elixir-${ELIXIR_VER}.tar.gz && \
    cd elixir-${ELIXIR_VER} && \
    make && \
    make PREFIX=/usr install && \
    cd .. && \
    rm -rf elixir-${ELIXIR_VER} elixir-${ELIXIR_VER}.tar.gz && \
    # Remove qemu-arm
    rm -f /usr/bin/qemu-arm-static
