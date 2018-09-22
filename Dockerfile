FROM debian:8 as builder

ARG BRANCH=ccx-cli-ubuntu-v.4.1.1
ENV BRANCH=${BRANCH}

# BUILD_DATE and VCS_REF are immaterial, since this is a 2-stage build, but our build
# hook won't work unless we specify the args
ARG BUILD_DATE
ARG VCS_REF

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      gdb \
      libreadline-dev \
      python-dev \
      libpthread-stubs0-dev \
      gcc \
      g++\
      git \
      libc6-dev \
      cmake \
      libboost-all-dev && \
    git clone --branch $BRANCH https://github.com/TheCircleFoundation/conceal-core.git /opt/conceal-core && \
    cd /opt/conceal-core && \
    mkdir build && \
    cd build && \
    export CXXFLAGS="-w -std=gnu++11" && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-fassociative-math" -DCMAKE_CXX_FLAGS="-fassociative-math" -DSTATIC=true -DDO_TESTS=OFF .. && \
    make -j$(nproc)

FROM debian:8-slim

# Zedwallet needs libreadline 
RUN apt-get update && \
    apt-get install -y \
      libreadline-dev \
     && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/bin
COPY --from=builder /opt/conceal-core/build/src/conceald .
COPY --from=builder /opt/conceal-core/build/src/walletd .
COPY --from=builder /opt/conceal-core/build/src/concealwallet .
COPY --from=builder /opt/conceal-core/build/src/concealminer .
RUN mkdir -p /var/lib/conceald
WORKDIR /var/lib/conceald
ENTRYPOINT ["/usr/local/bin/conceald"]
CMD ["--no-console","--data-dir","/var/lib/conceald","--rpc-bind-ip","0.0.0.0","--rpc-bind-port","11898","--p2p-bind-port","11899"]
