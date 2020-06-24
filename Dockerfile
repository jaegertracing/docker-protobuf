ARG ALPINE_VERSION=3.10
ARG GO_VERSION=1.13.4
ARG GRPC_GATEWAY_VERSION=1.12.2
ARG GRPC_JAVA_VERSION=1.26.0
ARG GRPC_CSHARP_VERSION=1.28.1
ARG GRPC_VERSION=1.26.0
ARG PROTOC_GEN_GO_VERSION=1.3.2
ARG PROTOC_GEN_GOGO_VERSION=ba06b47c162d49f2af050fb4c75bcbc86a159d5c
ARG PROTOC_GEN_LINT_VERSION=0.2.1
ARG UPX_VERSION=3.96


FROM alpine:${ALPINE_VERSION} as protoc_base
RUN apk add --no-cache build-base curl cmake autoconf libtool git zlib-dev linux-headers && \
    mkdir -p /out


FROM protoc_base as protoc_builder
ARG GRPC_VERSION
RUN apk add --no-cache automake && \
    git clone --recursive --depth=1 -b v${GRPC_VERSION} https://github.com/grpc/grpc.git /grpc && \
    ln -s /grpc/third_party/protobuf /protobuf && \
    cd /protobuf && \
    ./autogen.sh && \
    ./configure --prefix=/usr --enable-static=no && \
    make -j4 && \
    make -j4 check && \
    make -j4 install && \
    make -j4 install DESTDIR=/out && \
    cd /grpc && \
    make -j4 install-plugins prefix=/out/usr

ARG GRPC_JAVA_VERSION
RUN mkdir -p /grpc-java && \
    curl -sSL https://api.github.com/repos/grpc/grpc-java/tarball/v${GRPC_JAVA_VERSION} | tar xz --strip 1 -C /grpc-java && \
    cd /grpc-java && \
    g++ \
        -I. -I/protobuf/src \
        -I/out/usr/include \
        compiler/src/java_plugin/cpp/*.cpp \
        -L/out/usr/lib \
        -L/out/usr/lib64 \
        -lprotoc -lprotobuf -lpthread --std=c++0x -s \
        -o protoc-gen-grpc-java && \
    install -Ds protoc-gen-grpc-java /out/usr/bin/protoc-gen-grpc-java && \
    rm -Rf /grpc-java && \
    rm -Rf /grpc


FROM protoc_base AS protoc_cs_builder
ARG GRPC_CSHARP_VERSION
RUN git clone --recursive --depth=1 -b v${GRPC_CSHARP_VERSION} https://github.com/grpc/grpc.git /grpc && \
    ln -s /grpc/third_party/protobuf /protobuf && \
    mkdir -p /grpc/cmake/build && \
    cd /grpc/cmake/build && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DgRPC_BUILD_TESTS=OFF \
        -DgRPC_INSTALL=ON \
        -DCMAKE_INSTALL_PREFIX=/out/usr \
        ../.. && \
    make -j4 install && \
    rm -Rf /grpc


FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} as go_builder
RUN apk add --no-cache build-base curl git

ARG PROTOC_GEN_GO_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/golang/protobuf && \
    curl -sSL https://api.github.com/repos/golang/protobuf/tarball/v${PROTOC_GEN_GO_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/golang/protobuf &&\
    cd ${GOPATH}/src/github.com/golang/protobuf && \
    go build -ldflags '-w -s' -o /golang-protobuf-out/protoc-gen-go ./protoc-gen-go && \
    install -Ds /golang-protobuf-out/protoc-gen-go /out/usr/bin/protoc-gen-go

ARG PROTOC_GEN_GOGO_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/gogo/protobuf && \
    curl -sSL https://api.github.com/repos/gogo/protobuf/tarball/${PROTOC_GEN_GOGO_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/gogo/protobuf &&\
    cd ${GOPATH}/src/github.com/gogo/protobuf && \
    go build -ldflags '-w -s' -o /gogo-protobuf-out/protoc-gen-gogo ./protoc-gen-gogo && \
    install -Ds /gogo-protobuf-out/protoc-gen-gogo /out/usr/bin/protoc-gen-gogo && \
    mkdir -p /out/usr/include/github.com/gogo/protobuf/protobuf/google/protobuf && \
    install -D $(find ./protobuf/google/protobuf -name '*.proto') -t /out/usr/include/github.com/gogo/protobuf/protobuf/google/protobuf && \
    install -D ./gogoproto/gogo.proto /out/usr/include/github.com/gogo/protobuf/gogoproto/gogo.proto

ARG PROTOC_GEN_LINT_VERSION
RUN cd / && \
    curl -sSLO https://github.com/ckaznocha/protoc-gen-lint/releases/download/v${PROTOC_GEN_LINT_VERSION}/protoc-gen-lint_linux_amd64.zip && \
    mkdir -p /protoc-gen-lint-out && \
    cd /protoc-gen-lint-out && \
    unzip -q /protoc-gen-lint_linux_amd64.zip && \
    install -Ds /protoc-gen-lint-out/protoc-gen-lint /out/usr/bin/protoc-gen-lint

ARG GRPC_GATEWAY_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    curl -sSL https://api.github.com/repos/grpc-ecosystem/grpc-gateway/tarball/v${GRPC_GATEWAY_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    cd ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    go build -ldflags '-w -s' -o /grpc-gateway-out/protoc-gen-grpc-gateway ./protoc-gen-grpc-gateway && \
    go build -ldflags '-w -s' -o /grpc-gateway-out/protoc-gen-swagger ./protoc-gen-swagger && \
    install -Ds /grpc-gateway-out/protoc-gen-grpc-gateway /out/usr/bin/protoc-gen-grpc-gateway && \
    install -Ds /grpc-gateway-out/protoc-gen-swagger /out/usr/bin/protoc-gen-swagger && \
    mkdir -p /out/usr/include/protoc-gen-swagger/options && \
    install -D $(find ./protoc-gen-swagger/options -name '*.proto') -t /out/usr/include/protoc-gen-swagger/options && \
    mkdir -p /out/usr/include/google/api && \
    install -D $(find ./third_party/googleapis/google/api -name '*.proto') -t /out/usr/include/google/api && \
    mkdir -p /out/usr/include/google/rpc && \
    install -D $(find ./third_party/googleapis/google/rpc -name '*.proto') -t /out/usr/include/google/rpc


FROM alpine:${ALPINE_VERSION} as packer
RUN apk add --no-cache curl

ARG UPX_VERSION
RUN mkdir -p /upx && curl -sSL https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz | tar xJ --strip 1 -C /upx && \
    install -D /upx/upx /usr/local/bin/upx

# Use all output including headers and protoc from protoc_builder
COPY --from=protoc_builder /out/ /out/
# Use protoc and plugin from protoc_cs_builder
COPY --from=protoc_cs_builder /out/usr/bin/protoc-3.11.2.0 /out/usr/bin/protoc-csharp
COPY --from=protoc_cs_builder /out/usr/bin/grpc_csharp_plugin /out/usr/bin/grpc_csharp_plugin
# Integrate all output from go_builder
COPY --from=go_builder /out/ /out/

RUN upx --lzma \
        /out/usr/bin/grpc_* \
        /out/usr/bin/protoc-gen-*
RUN find /out -name "*.a" -delete -or -name "*.la" -delete


FROM alpine:${ALPINE_VERSION}
LABEL maintainer="The Jaeger Authors"
COPY --from=packer /out/ /
RUN apk add --no-cache bash libstdc++ && \
    ln -s /usr/bin/grpc_cpp_plugin /usr/bin/protoc-gen-grpc-cpp && \
    ln -s /usr/bin/grpc_csharp_plugin /usr/bin/protoc-gen-grpc-csharp && \
    ln -s /usr/bin/grpc_node_plugin /usr/bin/protoc-gen-grpc-js && \
    ln -s /usr/bin/grpc_python_plugin /usr/bin/protoc-gen-grpc-python
COPY protoc-wrapper /usr/bin/protoc-wrapper
ENTRYPOINT ["protoc-wrapper", "-I/usr/include"]
