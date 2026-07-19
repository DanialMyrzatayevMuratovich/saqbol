#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python -m grpc_tools.protoc \
    -I proto/ml/v1 \
    --python_out=app/generated \
    --grpc_python_out=app/generated \
    proto/ml/v1/ml.proto

sed -i.bak 's/^import ml_pb2/from . import ml_pb2/' app/generated/ml_pb2_grpc.py
rm -f app/generated/ml_pb2_grpc.py.bak
touch app/generated/__init__.py

echo "generated app/generated/ml_pb2.py and ml_pb2_grpc.py"
