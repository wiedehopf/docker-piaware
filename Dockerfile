FROM alpine:3.9

ENV BRANCH_PIAWARE=v3.6.3 \
    BRANCH_TCLLIB=tcllib_1_18_1 \
    VERSION_S6OVERLAY=v1.22.1.0 \
    ARCH_S6OVERLAY=amd64 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

ADD https://github.com/just-containers/s6-overlay/releases/download/${VERSION_S6OVERLAY}/s6-overlay-${ARCH_S6OVERLAY}.tar.gz /tmp/s6-overlay.tar.gz

RUN apk update && \
    apk add git \
            make \
            tcl \
            gcc \
            musl-dev \
            autoconf \
            tcl-dev \
            tclx \
            tcl-tls \
            cmake \
            libusb-dev \
            ncurses-dev \
            g++ \
            net-tools \
            python3 \
            python3-dev \
            lighttpd \
            tzdata && \
    mkdir -p /src && \
    mkdir -p /var/cache/lighttpd/compress && \
    chown lighttpd:lighttpd /var/cache/lighttpd/compress && \
    git clone git://git.osmocom.org/rtl-sdr.git /src/rtl-sdr && \
    mkdir -p /src/rtl-sdr/build && \
    cd /src/rtl-sdr/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -Wno-dev && \
    make -j -Wstringop-truncation && \
    make -j -Wstringop-truncation install && \
    cp -v /src/rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/ && \
    echo "blacklist dvb_usb_rtl28xxu" >> /etc/modprobe.d/no-rtl.conf && \
    echo "blacklist rtl2832" >> /etc/modprobe.d/no-rtl.conf && \
    echo "blacklist rtl2830" >> /etc/modprobe.d/no-rtl.conf && \
    git clone https://github.com/flightaware/tcllauncher.git /src/tcllauncher && \
    cd /src/tcllauncher && \
    autoconf && \
    ./configure --prefix=/opt/tcl && \
    make -j && \
    make -j install && \
    git clone -b ${BRANCH_TCLLIB} https://github.com/tcltk/tcllib.git /src/tcllib && \
    cd /src/tcllib && \
    autoconf && \
    ./configure && \
    make -j && \
    make -j install && \
    git clone -b ${BRANCH_PIAWARE} https://github.com/flightaware/piaware.git /src/piaware && \
    cd /src/piaware && \
    make -j && \
    make -j install && \
    cp -v /src/piaware/package/ca/*.pem /etc/ssl/ && \
    touch /etc/piaware.conf && \
    mkdir -p /run/piaware && \
    git clone https://github.com/flightaware/dump1090.git /src/dump1090 && \
    cd /src/dump1090 && \
    make -j all BLADERF=no && \
    make -j faup1090 BLADERF=no && \
    cp -v view1090 dump1090 /usr/local/bin/ && \
    cp -v faup1090 /usr/lib/piaware/helpers/ && \
    mkdir -p /run/dump1090-fa && \
    mkdir -p /usr/share/dump1090-fa/html && \
    cp -a /src/dump1090/public_html/* /usr/share/dump1090-fa/html/ && \
    git clone https://github.com/mutability/mlat-client.git /src/mlat-client && \
    cd /src/mlat-client && \
    ./setup.py install && \
    ln -s /usr/bin/fa-mlat-client /usr/lib/piaware/helpers/ && \
    apk del git \
            make \
            gcc \
            musl-dev \
            autoconf \
            tcl-dev \
            cmake \
            ncurses-dev \
            python3 && \
    tar -xzf /tmp/s6-overlay.tar.gz -C / && \
    rm -rf /var/cache/apk/* /src /tmp/*

COPY etc/ /etc/

EXPOSE 8080/tcp 30001-30005/tcp 30104/tcp

ENTRYPOINT [ "/init" ]