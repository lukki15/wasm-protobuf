FROM ubuntu:20.04

# TZ and DEBIAN_FRONTEND
ENV TZ Europe/Berlin
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y -q    && \
    apt-get install -y -q   \
    git         \
    python3     \
    curl        \
    libssl-dev  \
    pkg-config  \
    autoconf    \
    libtool     \
    unzip       \
    wget        \
    tar         \
    zlib1g-dev  \
    automake    \
    make        \
    g++         \
    unzip

ENV EMSDK_VERSION 1.39.16   
RUN git clone https://github.com/emscripten-core/emsdk.git  && \
    cd emsdk                                                && \
    ./emsdk install ${EMSDK_VERSION}                        && \
    ./emsdk activate ${EMSDK_VERSION}

ENV PROTOBUF_VERSION v3.13.0.1
ENV PROTOBUF_DIR /protobuf
ENV PROTOBUF_WASM_DIR /protobuf-wasm
ENV PROTOBUF_WASM_PATCH_DIR ${PROTOBUF_WASM_DIR}/protobuf-wasm-patch

RUN git clone https://github.com/protocolbuffers/protobuf.git ${PROTOBUF_DIR}   && \
    cd ${PROTOBUF_DIR}                                                          && \
    git checkout ${PROTOBUF_VERSION}                                            && \
    git submodule update --init --recursive                                     && \
    cp -r ${PROTOBUF_DIR} ${PROTOBUF_WASM_DIR}

RUN cd ${PROTOBUF_DIR}      && \
    ./autogen.sh            && \
    ./configure --with-zlib && \
    make -j4                && \
    make check              && \
    make install            && \
    ldconfig

COPY ./wasm-protobuf-patch ${PROTOBUF_WASM_PATCH_DIR}
RUN cd ${PROTOBUF_WASM_DIR}                         && \
    git apply ${PROTOBUF_WASM_PATCH_DIR}/*.patch    && \
    ./autogen.sh                                    
RUN [ "/bin/bash", "-c", "                                          \
        cd ${PROTOBUF_WASM_DIR}                                     && \
        source /emsdk/emsdk_env.sh                                  && \
        emconfigure ./configure --with-zlib CFLAGS=' -s USE_ZLIB=1' && \
        make -j4 XCFLAGS=' -s USE_ZLIB=1'                           && \
        emmake make check " ]

RUN cd protobuf-wasm/src/.libs/                 && \
    cp  libprotobuf-lite.so libprotobuf-lite.bc && \
    cp  libprotobuf.so libprotobuf.bc
