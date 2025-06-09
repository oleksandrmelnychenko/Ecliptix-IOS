#!/bin/bash

# Exit on error
set -e

# Paths
PROJECT_ROOT="/Users/oleksandr/Desktop/Projects/Ecliptix-iOS/Ecliptix-iOS"
PROTO_SRC="${PROJECT_ROOT}/Domain/Protos"
PROTO_OUT="/tmp/generated"
FINAL_OUT="${PROJECT_ROOT}/Domain/GeneratedProtos"

# Create directories
mkdir -p "${PROTO_OUT}"
mkdir -p "${FINAL_OUT}"

# Generate .swift files from .proto
/opt/homebrew/bin/protoc \
  --proto_path="${PROTO_SRC}" \
  --plugin=/opt/homebrew/bin/protoc-gen-swift \
  --plugin=/opt/homebrew/bin/protoc-gen-grpc-swift \
  --swift_opt=Visibility=Public \
  --swift_out="${PROTO_OUT}" \
  --grpc-swift_opt=Visibility=Public \
  --grpc-swift_out="${PROTO_OUT}" \
  "${PROTO_SRC}"/*.proto

# Move .swift files to the project folder
mv "${PROTO_OUT}"/*.swift "${FINAL_OUT}"

# Clean up temporary files
rm -rf "${PROTO_OUT}"

echo "Protocols successfully generated in: ${FINAL_OUT}"
