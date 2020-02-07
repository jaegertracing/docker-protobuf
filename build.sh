#!/usr/bin/env bash
docker build \
--build-arg ALPINE_VERSION="${ALPINE_VERSION:-"3.10"}" \
--build-arg GO_VERSION="${GO_VERSION:-"1.13.4"}" \
--build-arg GRPC_GATEWAY_VERSION="${GRPC_GATEWAY_VERSION:-"1.12.2"}" \
--build-arg GRPC_JAVA_VERSION="${GRPC_JAVA_VERSION:-"1.26.0"}" \
--build-arg GRPC_VERSION="${GRPC_VERSION:-"1.26.0"}" \
--build-arg PROTOC_GEN_GO_VERSION="${PROTOC_GEN_GO_VERSION:-"1.3.2"}" \
--build-arg PROTOC_GEN_GOGO_VERSION="${PROTOC_GEN_GOGO_VERSION:-"1.3.1"}" \
--build-arg PROTOC_GEN_LINT_VERSION="${PROTOC_GEN_LINT_VERSION:-"0.2.1"}" \
--build-arg UPX_VERSION="${UPX_VERSION:-"3.96"}" \
${@} .
