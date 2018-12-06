FROM debian:8 as builder

ARG REPO=TheCircleFoundation/conceal-core
ENV REPO=${REPO}

# Unneeded in build stage, but avoids hook errors
ARG BUILD_DATE
ARG VCS_REF

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
      curl \
      gdb \
      libreadline-dev \
      python-dev \
      libpthread-stubs0-dev \
      gcc \
      g++\
      git \
      libc6-dev \
      cmake \
      libboost-all-dev 


RUN \
    TAG=$(curl -L --silent "https://api.github.com/repos/$REPO/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")') && \
    echo git clone --branch $TAG https://github.com/$REPO /src && \
    git clone --branch $TAG https://github.com/$REPO /src && \
    cd /src && \
    mkdir build && \
    cd build && \
    export CXXFLAGS="-w -std=gnu++11" && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-fassociative-math" -DCMAKE_CXX_FLAGS="-fassociative-math" -DSTATIC=true -DDO_TESTS=OFF .. && \
    make -j$(nproc)

####### 2nd stage
FROM debian:8-slim

# Now we DO need these, for the auto-labeling of the image
ARG BUILD_DATE
ARG VCS_REF

# Good docker practice, plus we get microbadger badges
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/funkypenguin/conceal-core.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="2.2-r1"

ENTRYPOINT ["/usr/local/bin/conceald"]

COPY --from=builder /src/build/src/* /usr/local/bin/ 

CMD ["--no-console","--rpc-bind-ip","0.0.0.0","--rpc-bind-port","16000","--p2p-bind-port","15000"]
