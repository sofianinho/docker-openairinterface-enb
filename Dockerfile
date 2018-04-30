FROM ubuntu:16.04
LABEL maintainer="github.com/sofianinho"
LABEL frontend="ettus usrp b200/b210"

ENV DEBIAN_FRONTEND noninteractive
# Dependencies for the UHD driver for the USRP hardware
RUN apt-get update \
  && apt-get -yq dist-upgrade \
  && apt-get -yq --no-install-recommends install \
   autoconf \
   build-essential \
   cmake \
   git \
   libboost-all-dev \
   libusb-1.0-0-dev \
   pkg-config \
   python \
   python-cheetah \
   python-dev \
   python-mako \
   python-requests \
   python-software-properties \
   subversion \
   wget \
  && apt-get -y autoclean

# Fetching the uhd 3.010.001 driver for our USRP SDR card
RUN cd /tmp \
  && wget http://files.ettus.com/binaries/uhd/uhd_003.010.001.001-release/uhd-3.10.1.1.tar.gz \
  && tar xvzf uhd-3.10.1.1.tar.gz \
  && cd UHD_3.10.1.1_release \
  && mkdir build \
  && cd build \
  && cmake ../ \
  && make \
  && make install \
  && ldconfig \
  && python /usr/local/lib/uhd/utils/uhd_images_downloader.py \
  && rm -rf /tmp/uhd* \
  && cd /usr/local/share/uhd/images \
  && ls |grep -v "003.010.001.001.tag"|grep -v "bit" |grep -v "usrp_b200_fpga.bin"|grep -v "usrp_b200_fw.hex"|grep -v "usrp_b210_fpga.bin"|xargs rm -rf
# remove other ursp frntend than the ones needed (usrp b200 and b210)

# Dependencies for OpenAirInterface software
RUN apt-get -yq --no-install-recommends install \
  automake  \
   bison  \
   check \
   cmake-curses-gui  \
   ctags \
   dialog \
   dkms \
   doxygen \
   doxygen-gui \
   ethtool \
   flex  \
   gawk \
   gccxml \
   gdb  \
   graphviz \
   gtkwave \
   guile-2.0-dev  \
   iperf \
   iproute \
   iptables \
   iptables-dev \
   libatlas-base-dev \
   libatlas-dev \
   libblas-dev \
   libboost-all-dev \
   libconfig8-dev \
   libffi-dev \
   libforms-bin \
   libforms-dev \
   libgcrypt11-dev \
   libgmp-dev \
   libgnutls-dev \
   libgtk-3-dev \
   libidn11-dev \
   libidn2-0-dev  \
   libmysqlclient-dev  \
   liboctave-dev \
   libpgm-dev \
   libpthread-stubs0-dev \
   libsctp-dev  \
   libsctp1  \
   libssl-dev  \
   libtasn1-dev  \
   libtool  \
   libusb-1.0-0-dev \
   libxml2 \
   libxml2-dev  \
   libxslt1-dev \
   mscgen  \
   nettle-bin \
   nettle-dev \
   ntpdate \
   octave \
   octave-signal \
   openssh-client \
   openssh-server \
   openssl \
   openvpn \
   pkg-config \
   pydb \
   python-dev  \
   python-numpy \
   python-pexpect \
   python-pip \
   python-setuptools\
   sshfs \
   sshpass \
   swig  \
   texlive-latex-base \
   tshark \
   uml-utilities \
   unzip  \
   valgrind  \
   vlan      \
   wvdial \
   xmlstarlet \
   && apt-get -y autoclean \
  && easy_install pip==10.0.1 \
  && pip install \
    paramiko==1.17.1 \
    pyroute2 \
  && update-alternatives --set liblapack.so /usr/lib/atlas-base/atlas/liblapack.so

# ASN1 compiler with Eurecom fixes
WORKDIR /root
RUN git clone https://gitlab.eurecom.fr/oai/asn1c.git \
  && cd asn1c \
  && ./configure \
  && make -j`nproc` \
  && make install

# Fetching the develop repository
ARG OAI_BRANCH=master
RUN git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git \
  && cd openairinterface5g \
  && git checkout ${OAI_BRANCH}

# Compile
WORKDIR /root/openairinterface5g
RUN cd cmake_targets && mkdir -p lte_build_oai/build
## CmakeLists generation
WORKDIR /root/openairinterface5g/cmake_targets/lte_build_oai

ENV OPENAIR_HOME="/root/openairinterface5g"
ENV OPENAIR_DIR=${OPENAIR_HOME} \
    OPENAIR1_DIR=${OPENAIR_HOME}/openair1 \
    OPENAIR2_DIR=${OPENAIR_HOME}/openair2 \
    OPENAIR3_DIR=${OPENAIR_HOME}/openair3 \
    OPENAIR_TARGETS=${OPENAIR_HOME}/targets 

COPY ./CMakeLists.txt .

WORKDIR /root/openairinterface5g/cmake_targets/lte_build_oai/build

RUN env|grep ^OPENAIR\
  && cmake .. \
  && make -j`nproc` lte-softmodem \
  && make -j`nproc` oai_usrpdevif
#RUN make -j`nproc` params_libconfig

RUN ln -sf liboai_usrpdevif.so liboai_device.so

# Run directly the eNodeB code
ENV PATH=/root/openairinterface5g/cmake_targets/lte_build_oai/build/:$PATH
ENTRYPOINT ["lte-softmodem", "-O", "/config/enb.conf"]
