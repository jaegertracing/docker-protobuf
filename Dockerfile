ARG ALPINE_VERSION=3.13
ARG GO_VERSION=1.17.3
ARG GRPC_GATEWAY_VERSION=2.18.1
ARG GRPC_JAVA_VERSION=1.40.0
ARG GRPC_CSHARP_VERSION=1.40.0
ARG GRPC_VERSION=1.40.0
ARG PROTOC_GEN_GO_VERSION=1.31.0
ARG PROTOC_GEN_GO_GRPC_VERSION=1.3.0
# v1.3.2, using the version directly does not work: "tar: invalid magic"
ARG PROTOC_GEN_GOGO_VERSION=b03c65ea87cdc3521ede29f62fe3ce239267c1bc
ARG PROTOC_GEN_LINT_VERSION=0.3.0
ARG UPX_VERSION=4.2.1

FROM alpine:${ALPINE_VERSION} as protoc_base
RUN apk add --no-cache build-base curl cmake autoconf libtool git zlib-dev linux-headers && \
    mkdir -p /out

FROM protoc_base as protoc_builder
ARG GRPC_VERSION
RUN apk add --no-cache automake ninja && \
    git clone --recursive --depth=1 -b v${GRPC_VERSION} https://github.com/grpc/grpc.git /grpc && \
    ln -s /grpc/third_party/protobuf /protobuf && \
    mkdir -p /grpc/cmake/build && \
    cd /grpc/cmake/build && \
    cmake \
        -GNinja \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DgRPC_INSTALL=ON \
        -DgRPC_BUILD_TESTS=OFF \
        ../.. && \
    cmake --build . --target plugins && \
    cmake --build . --target install && \
    DESTDIR=/out cmake --build . --target install

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
        -gRPC_BUILD_GRPC_CPP_PLUGIN=OFF \
        -gRPC_BUILD_GRPC_NODE_PLUGIN=OFF \
        -gRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=OFF \
        -gRPC_BUILD_GRPC_PHP_PLUGIN=OFF \
        -gRPC_BUILD_GRPC_PYTHON_PLUGIN=OFF \
        -gRPC_BUILD_GRPC_RUBY_PLUGIN=OFF \
        -DgRPC_INSTALL=ON \
        -DCMAKE_INSTALL_PREFIX=/out/usr \
        ../.. && \
    make -j4 install && \
    rm -Rf /grpc


FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} as go_builder
RUN apk add --no-cache build-base curl git
ENV GOBIN=/out/usr/bin

ARG PROTOC_GEN_GO_VERSION
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v${PROTOC_GEN_GO_VERSION}

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
RUN go install github.com/ckaznocha/protoc-gen-lint@v${PROTOC_GEN_LINT_VERSION}

ARG GRPC_GATEWAY_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    curl -sSL https://api.github.com/repos/grpc-ecosystem/grpc-gateway/tarball/v${GRPC_GATEWAY_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    cd ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway && \
    mkdir -p /out/usr/include/protoc-gen-openapiv2/options && \
    install -D $(find ./protoc-gen-openapiv2/options -name '*.proto') -t /out/usr/include/protoc-gen-openapiv2/options && \
    go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@v${GRPC_GATEWAY_VERSION} && \
    go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v${GRPC_GATEWAY_VERSION}

ARG PROTOC_GEN_GO_GRPC_VERSION
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v${PROTOC_GEN_GO_GRPC_VERSION}

FROM alpine:${ALPINE_VERSION} as packer
RUN apk add --no-cache curl

ARG UPX_VERSION
RUN mkdir -p /upx && curl -sSL https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz | tar xJ --strip 1 -C /upx && \
    install -D /upx/upx /usr/local/bin/upx

# Use all output including headers and protoc from protoc_builder
COPY --from=protoc_builder /out/ /out/
# Use protoc and plugin from protoc_cs_builder
COPY --from=protoc_cs_builder /out/usr/bin/protoc-* /out/usr/bin/protoc-csharp
COPY --from=protoc_cs_builder /out/usr/bin/grpc_csharp_plugin /out/usr/bin/grpc_csharp_plugin
# Integrate all output from go_builder
COPY --from=go_builder /out/ /out/

RUN upx --lzma $(find /out/usr/bin/ \
        -type f -name 'grpc_*' \
        -not -name 'grpc_node_plugin' \
        -not -name 'grpc_php_plugin' \
        -not -name 'grpc_ruby_plugin' \
        -not -name 'grpc_python_plugin' \
        -or -name 'protoc-gen-*' \
    )
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
ENV LD_LIBRARY_PATH='/usr/lib:/usr/lib64:/usr/lib/local'
ENTRYPOINT ["protoc-wrapper", "-I/usr/include"]
