ROOT_PATH := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TAG = $(shell git describe --tags --abbrev=0 HEAD)

build:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
		go build -o $(ROOT_PATH)dist/ck8s_linux_amd64 \
			-ldflags '-X main.version=${TAG}' \
			$(ROOT_PATH)cmd/ck8s
.PHONY: build

test:
	go test ./...
.PHONY: test

clean:
	rm -rf $(ROOT_PATH)dist
.PHONY: clean
