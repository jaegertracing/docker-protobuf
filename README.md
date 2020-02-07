# Protocol Buffers + Docker
A lightweight `protoc` Docker image.
It started out as https://github.com/znly/docker-protobuf fork, but grew into a stand-alone project.

This repo has been configured with dependencies from the [Jaeger](github.com/jaegertracing/jaeger) project.

## What's included:
- https://github.com/ckaznocha/protoc-gen-lint
- https://github.com/gogo/protobuf
- https://github.com/golang/protobuf
- https://github.com/google/protobuf
- https://github.com/grpc-ecosystem/grpc-gateway
- https://github.com/grpc/grpc
- https://github.com/grpc/grpc-java

## Supported languages
- C#
- C++
- Go
- Java / JavaNano (Android)
- JavaScript
- Objective-C
- PHP
- Python
- Ruby

## Usage
```
$ docker run --rm -v<some-path>:<some-path> -w<some-path> thethingsindustries/protoc [OPTION] PROTO_FILES
```

For help try:
```
$ docker run --rm thethingsindustries/protoc --help
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
docker run --rm -v${PWD}:/model/proto annanay25/jaeger-docker-protobuf:latest --proto_path=/model/proto \
    --java_out=/model/proto -I/usr/include/github.com/gogo/protobuf /model/proto/model.proto
```