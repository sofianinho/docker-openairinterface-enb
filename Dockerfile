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
   libusb-1.0-0-dev \
   cmake \
   wget \
   pkg-config \
   libboost-all-dev \
   python \
   python-dev \
   python-cheetah \
   git \
   subversion \
   python-software-properties \
   python-mako \
   python-requests \
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
  && rm -rf /tmp/uhd*
# TODO: remove other ursp frntend than the ones needed (usrp b200 and b210)

# Dependencies for OpenAirInterface software
RUN apt-get -yq --no-install-recommends install \
  automake  \
   bison  \
   cmake-curses-gui  \
   doxygen \
   doxygen-gui \
   texlive-latex-base \
   ethtool \
   flex  \
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
   libconfig8-dev \
   libforms-bin \
   libforms-dev \
   libgcrypt11-dev \
   libgmp-dev \
   libgtk-3-dev \
   libidn2-0-dev  \
   libidn11-dev \
   libmysqlclient-dev  \
   liboctave-dev \
   libpgm-dev \
   libsctp1  \
   libsctp-dev  \
   libssl-dev  \
   libtasn1-dev  \
   libtool  \
   libusb-1.0-0-dev \
   libxml2 \
   libxml2-dev  \
   mscgen  \
   octave \
   octave-signal \
   openssh-client \
   openssh-server \
   openssl \
   xmlstarlet \
   python-pip \
   pydb \
   wvdial \
   python-numpy \
   sshpass \
   libgnutls-dev \
   nettle-dev \
   nettle-bin \
   check \
   dialog \
   dkms \
   gawk \
   libboost-all-dev \
   libpthread-stubs0-dev \
   openvpn \
   pkg-config \
   python-dev  \
   python-pexpect \
   sshfs \
   swig  \
   tshark \
   uml-utilities \
   unzip  \
   valgrind  \
   vlan      \
   ctags \
   ntpdate \
  libffi-dev \
  libxslt1-dev \
  && apt-get -y autoclean
RUN apt-get install -qy python-setuptools && apt-get -y autoclean \
  && easy_install pip==10.0.1 \
  && pip install paramiko==1.17.1 \
  && pip install pyroute2 \
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
