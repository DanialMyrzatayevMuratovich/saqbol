.PHONY: up down run tidy build proto

up:
	docker compose up -d

down:
	docker compose down

tidy:
	go mod tidy

run:
	go run ./cmd/api

build:
	go build -o bin/api ./cmd/api

proto:
	protoc --go_out=. --go-grpc_out=. proto/ml/v1/ml.proto
