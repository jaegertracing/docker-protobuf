ARG ALPINE_VERSION=3.13
ARG GO_VERSION=1.17.3
ARG GRPC_GATEWAY_VERSION=1.16.0
ARG GRPC_JAVA_VERSION=1.35.0
ARG GRPC_CSHARP_VERSION=1.35.0
ARG GRPC_VERSION=1.35.0
ARG PROTOC_GEN_GO_VERSION=1.31.0
# v1.3.2, using the version directly does not work: "tar: invalid magic"
ARG PROTOC_GEN_GOGO_VERSION=b03c65ea87cdc3521ede29f62fe3ce239267c1bc
ARG PROTOC_GEN_LINT_VERSION=0.2.1
ARG UPX_VERSION=3.96

FROM alpine:${ALPINE_VERSION}
LABEL maintainer="The Jaeger Authors"
COPY protoc-wrapper /usr/bin/protoc-wrapper
ENV LD_LIBRARY_PATH='/usr/lib:/usr/lib64:/usr/lib/local'
ENTRYPOINT ["protoc-wrapper", "-I/usr/include"]
