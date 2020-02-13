# Protocol Buffers + Docker
A lightweight `protoc` Docker image, with all dependencies built-in, to generate code in multiple languages.

## Purpose

`gogoproto` annotations in proto files help make internal domain model types more efficient in golang, but using these proto files to generate code in other languages requires to include these dependencies anyway. The `Dockerfile` in this repo compiles all dependencies into the image, for easy code generation in multiple languages.

## Contents

`Dockerfile` configured with dependencies specific to the [Jaeger](github.com/jaegertracing/jaeger) project. 

## What's included in the image
- https://github.com/ckaznocha/protoc-gen-lint
- https://github.com/danielvladco/go-proto-gql
- https://github.com/dart-lang/protobuf
- https://github.com/envoyproxy/protoc-gen-validate
- https://github.com/gogo/protobuf
- https://github.com/golang/protobuf
- https://github.com/google/protobuf
- https://github.com/grpc-ecosystem/grpc-gateway
- https://github.com/grpc/grpc
- https://github.com/grpc/grpc-java

## Supported languages
- C#
- C++
- Dart
- Go
- Java / JavaNano (Android)
- JavaScript
- Objective-C
- PHP
- Python
- Ruby

## Usage
```
$ docker run --rm -v<some-path>:<some-path> -w<some-path> jaegertracing/protobuf [OPTION] PROTO_FILES
```

For help try:
```
$ docker run --rm jaegertracing/protobuf --help
```

### To generate language specific code

1. Make sure you have the `model.proto` file present in `${PWD}`

2. Use any of the language specific options -
```
  --cpp_out=OUT_DIR           Generate C++ header and source.
  --csharp_out=OUT_DIR        Generate C# source file.
  --java_out=OUT_DIR          Generate Java source file.
  --js_out=OUT_DIR            Generate JavaScript source.
  --objc_out=OUT_DIR          Generate Objective C header and source.
  --php_out=OUT_DIR           Generate PHP source file.
  --python_out=OUT_DIR        Generate Python source file.
  --ruby_out=OUT_DIR          Generate Ruby source file.
```

Example for Java:
```
docker run --rm -v${PWD}:{PWD} -w${PWD} jaegertracing/protobuf:latest --proto_path=${PWD} \
    --java_out=${PWD} -I/usr/include/github.com/gogo/protobuf ${PWD}/model.proto
```

CLI options:
- `--proto_path`: The path where protoc should search for proto files
- `--java_out`  : Generate Java code in the provided path
