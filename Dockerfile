ARG ALPINE_VERSION
ARG DART_VERSION
ARG GO_VERSION
ARG RUST_VERSION
ARG SWIFT_VERSION

FROM alpine:${ALPINE_VERSION} as protoc_builder
RUN apk add --no-cache build-base curl automake autoconf libtool git zlib-dev linux-headers cmake ninja

RUN mkdir -p /out

ARG GRPC_VERSION
RUN git clone --recursive --depth=1 -b v${GRPC_VERSION} https://github.com/grpc/grpc.git /grpc && \
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

ARG PROTOBUF_C_VERSION
RUN mkdir -p /protobuf-c && \
    curl -sSL https://api.github.com/repos/protobuf-c/protobuf-c/tarball/v${PROTOBUF_C_VERSION} | tar xz --strip 1 -C /protobuf-c && \
    cd /protobuf-c && \
    export LD_LIBRARY_PATH=/usr/lib:/usr/lib64 && \
    export PKG_CONFIG_PATH=/usr/lib64/pkgconfig && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make && make install DESTDIR=/out

ARG GRPC_JAVA_VERSION
RUN mkdir -p /grpc-java && \
    curl -sSL https://api.github.com/repos/grpc/grpc-java/tarball/v${GRPC_JAVA_VERSION} | tar xz --strip 1 -C /grpc-java && \
    cd /grpc-java && \
    g++ \
        -I. -I/usr/include \
        compiler/src/java_plugin/cpp/*.cpp \
        -L/usr/lib64 \
        -lprotoc -lprotobuf -lpthread --std=c++0x -s \
        -o protoc-gen-grpc-java && \
    install -Ds protoc-gen-grpc-java /out/usr/bin/protoc-gen-grpc-java

FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} as go_builder
RUN apk add --no-cache build-base curl git

ARG PROTOC_GEN_DOC_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    curl -sSL https://api.github.com/repos/pseudomuto/protoc-gen-doc/tarball/v${PROTOC_GEN_DOC_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    cd ${GOPATH}/src/github.com/pseudomuto/protoc-gen-doc && \
    go build -ldflags '-w -s' -o /protoc-gen-doc-out/protoc-gen-doc ./cmd/protoc-gen-doc && \
    install -Ds /protoc-gen-doc-out/protoc-gen-doc /out/usr/bin/protoc-gen-doc

ARG PROTOC_GEN_FIELDMASK_VERSION
RUN mkdir -p ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-fieldmask && \
    curl -sSL https://api.github.com/repos/TheThingsIndustries/protoc-gen-fieldmask/tarball/v${PROTOC_GEN_FIELDMASK_VERSION} | tar xz --strip 1 -C ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-fieldmask && \
    cd ${GOPATH}/src/github.com/TheThingsIndustries/protoc-gen-fieldmask && \
    go build -ldflags '-w -s' -o /protoc-gen-fieldmask-out/protoc-gen-fieldmask . && \
    install -Ds /protoc-gen-fieldmask-out/protoc-gen-fieldmask /out/usr/bin/protoc-gen-fieldmask

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


FROM rust:${RUST_VERSION}-slim as rust_builder
RUN apt-get update && apt-get install -y musl-tools curl
RUN rustup target add x86_64-unknown-linux-musl
ENV RUSTFLAGS='-C linker=musl-gcc'

ARG RUST_PROTOBUF_VERSION
RUN mkdir -p /rust-protobuf && \
    curl -sSL https://api.github.com/repos/stepancheg/rust-protobuf/tarball/v${RUST_PROTOBUF_VERSION} | tar xz --strip 1 -C /rust-protobuf && \
    cd /rust-protobuf/protobuf-codegen && cargo build --target=x86_64-unknown-linux-musl --release && \
    install -Ds /rust-protobuf/target/x86_64-unknown-linux-musl/release/protoc-gen-rust /out/usr/bin/protoc-gen-rust

ARG GRPC_RUST_VERSION
RUN mkdir -p /grpc-rust && curl -sSL https://api.github.com/repos/stepancheg/grpc-rust/tarball/v${GRPC_RUST_VERSION} | tar xz --strip 1 -C /grpc-rust && \
    cd /grpc-rust/grpc-compiler && cargo build --target=x86_64-unknown-linux-musl --release && \
    install -Ds /grpc-rust/target/x86_64-unknown-linux-musl/release/protoc-gen-rust-grpc /out/usr/bin/protoc-gen-rust-grpc


FROM swift:${SWIFT_VERSION} as swift_builder
RUN apt-get update && \
    apt-get install -y unzip patchelf libnghttp2-dev curl libssl-dev zlib1g-dev

ARG GRPC_SWIFT_VERSION
RUN mkdir -p /grpc-swift && \
    curl -sSL https://api.github.com/repos/grpc/grpc-swift/tarball/${GRPC_SWIFT_VERSION} | tar xz --strip 1 -C /grpc-swift && \
    cd /grpc-swift && make && \
    install -Ds /grpc-swift/protoc-gen-swift /protoc-gen-swift/protoc-gen-swift && \
    install -Ds /grpc-swift/protoc-gen-swiftgrpc /protoc-gen-swift/protoc-gen-swiftgrpc && \
    cp /lib64/ld-linux-x86-64.so.2 \
        $(ldd /protoc-gen-swift/protoc-gen-swift /protoc-gen-swift/protoc-gen-swiftgrpc | awk '{print $3}' | grep /lib | sort | uniq) \
        /protoc-gen-swift/ && \
    find /protoc-gen-swift/ -name 'lib*.so*' -exec patchelf --set-rpath /protoc-gen-swift {} \; && \
    for p in protoc-gen-swift protoc-gen-swiftgrpc; do \
        patchelf --set-interpreter /protoc-gen-swift/ld-linux-x86-64.so.2 /protoc-gen-swift/${p}; \
    done

FROM google/dart:${DART_VERSION} as dart_builder
RUN apt-get update && apt-get install -y musl-tools curl

ARG DART_PROTOBUF_VERSION
RUN mkdir -p /dart-protobuf && \
    curl -sSL https://api.github.com/repos/dart-lang/protobuf/tarball/protobuf-${DART_PROTOBUF_VERSION} | tar xz --strip 1 -C /dart-protobuf && \
    cd /dart-protobuf/protoc_plugin && pub install && dart2native --verbose bin/protoc_plugin.dart -o protoc_plugin && \
    install -D /dart-protobuf/protoc_plugin/protoc_plugin /out/usr/bin/protoc-gen-dart

FROM alpine:${ALPINE_VERSION} as packer
RUN apk add --no-cache curl

ARG UPX_VERSION
RUN mkdir -p /upx && curl -sSL https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz | tar xJ --strip 1 -C /upx && \
    install -D /upx/upx /usr/local/bin/upx

COPY --from=protoc_builder /out/ /out/
COPY --from=go_builder /out/ /out/
COPY --from=rust_builder /out/ /out/
COPY --from=swift_builder /protoc-gen-swift /out/protoc-gen-swift
COPY --from=dart_builder /out/ /out/
RUN upx --lzma $(find /out/usr/bin/ \
        -type f -name 'grpc_*' \
        -not -name 'grpc_csharp_plugin' \
        -not -name 'grpc_node_plugin' \
        -not -name 'grpc_php_plugin' \
        -not -name 'grpc_ruby_plugin' \
        -not -name 'grpc_python_plugin' \
        -or -name 'protoc-gen-*' \
        -not -name 'protoc-gen-dart' \
    )
RUN find /out -name "*.a" -delete -or -name "*.la" -delete

FROM alpine:${ALPINE_VERSION}
LABEL maintainer="The Jaeger Authors"
COPY --from=packer /out/ /
RUN apk add --no-cache bash libstdc++ && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-2.31-r0.apk && \
    apk add glibc-2.31-r0.apk && \
    for p in protoc-gen-swift protoc-gen-swiftgrpc; do ln -s /protoc-gen-swift/${p} /usr/bin/${p}; done && \
    ln -s /usr/bin/grpc_cpp_plugin /usr/bin/protoc-gen-grpc-cpp && \
    ln -s /usr/bin/grpc_csharp_plugin /usr/bin/protoc-gen-grpc-csharp && \
    ln -s /usr/bin/grpc_node_plugin /usr/bin/protoc-gen-grpc-js && \
    ln -s /usr/bin/grpc_python_plugin /usr/bin/protoc-gen-grpc-python
COPY protoc-wrapper /usr/bin/protoc-wrapper
ENV LD_LIBRARY_PATH='/usr/lib:/usr/lib64:/usr/lib/local'
ENTRYPOINT ["protoc-wrapper", "-I/usr/include"]
