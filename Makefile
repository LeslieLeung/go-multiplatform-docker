all: build-macos-amd64 build-macos-arm64 build-linux-amd64 build-linux-arm64 build-windows-amd64

build-macos-amd64:
	mkdir -p build
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -o build/hello_macos_amd64 main.go

build-macos-arm64:
	mkdir -p build
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -o build/hello_macos_arm64 main.go

build-linux-amd64:
	mkdir -p build
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o build/hello_linux_amd64 main.go

build-linux-arm64:
	mkdir -p build
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/hello_linux_arm64 main.go

build-windows-amd64:
	mkdir -p build
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o build/hello_windows_amd64.exe main.go

build-docker-image:
	docker buildx build --platform linux/amd64,linux/arm64 -t leslieleung/hello . --push

clean:
	rm -f build/hello_*