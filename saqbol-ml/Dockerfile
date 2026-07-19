FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY proto ./proto
COPY app ./app
COPY training ./training
COPY data ./data

RUN python -m grpc_tools.protoc \
        -I proto/ml/v1 \
        --python_out=app/generated \
        --grpc_python_out=app/generated \
        proto/ml/v1/ml.proto \
    && sed -i 's/^import ml_pb2/from . import ml_pb2/' app/generated/ml_pb2_grpc.py \
    && touch app/generated/__init__.py

RUN python training/train_baseline.py

EXPOSE 8000 9090
CMD ["python", "-m", "app.server"]
