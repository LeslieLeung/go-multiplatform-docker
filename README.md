# go-multiplatform-docker

[![build](https://github.com/LeslieLeung/go-multiplatform-docker/actions/workflows/build.yml/badge.svg)](https://github.com/LeslieLeung/go-multiplatform-docker/actions/workflows/build.yml)

English | [简体中文](doc/README.md)

A demo on how to build go multiplatform binaries and publish to release and DockerHub with GitHub Actions.

## Why this exists?

As a software developer, it is not necessary to spend a lot of time repeating the same labor. This should be a high-level automation process. 
In the process of releasing software, there are some points that could be a pain in the ass:

- build binaries for multiple OSs and architectures
- might have to build a suitable build environment for cross-platform compiling
- complicated release procedures

Sure, some of these inconveniences have been eliminated

- Golang supports cross-platform compiling out-of-the-box
- use Docker or VM
- use scripts

However, it's not "automatic" enough. Using GitHub Actions, it can gracefully solve these problems, making developers more focus on the actual development.

## Prerequisites

This passage assumes you are familiar with Golang,git and Docker, and know a little about GitHub Actions.

## Let's begin!

There are two goals in this passage

- Build multiplatform binaries for a Golang Program and release it to GitHub Releases
- Build multiplatform binaries for a Golang Program and release it to DockerHub

### Writing a simple Golang program

The Golang program is just for testing on different OSs and architectures, so a very simple program should do the trick. We will use a Hello World here.

```go
package main

import "fmt"

func main() {
	fmt.Println("Hello, World!")
}
```

Run it in the terminal, and you will see the following.

```bash
> go run main.go
Hello, World!
```

Looking good, now let's build an executable binary.

```bash
> go build -o hello main.go

```

This command outputs nothing, means it ran successfully without any errors. In the world of command lines, no news is good news.

We shall see a `hello` executable file under current directory（In Windows, it might look like `hello.exe`）。Let's run it.

```bash
> ./hello
Hello, World!
```

Great, it has the same result as `go run main.go`.

> ### Takeaways：
> Using `go build`, you can build an executable binary for a Golang program.

### Building multiplatform binary executables

Remember that on Windows, `go build` would produce a `.exe` file? It's worth mentioning that Golang's support for multiplatform compiling ability.
 It can produce binary executables for different platforms without any extra efforts.

Assuming you are using macOS for development, you can build a binary executable for Windows with the following command

```bash
> CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o hello_windows_amd64.exe main.go

```

There would be a  `hello_windows_amd64.exe` file under current directory, copy it to a Windows machine a run it.

### Build multiplatform binaries for a Golang Program and release it to GitHub Releases

Before you start, you might have a look at this repo's [Releases](https://github.com/LeslieLeung/go-multiplatform-docker/releases)

![](http://img.ameow.xyz/20220724180813.png)

You might find for each target platform, there is a corresponding `tar.gz` or `zip` file with a `md5` checksum. Inside the compressed file, there is a binary executable file, `LISENCE` and `README.md`.

This is quite simple with GitHub Actions, an action would do all the trick. See [wangyoucao577/go-release-action](https://github.com/wangyoucao577/go-release-action) .

It's really easy to use.

```yaml
name: build

on:
  release:
    types: [created] # 表示在创建新的 Release 时触发

jobs:
  build-go-binary:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        goos: [linux, windows, darwin] # 需要打包的系统
        goarch: [amd64, arm64] # 需要打包的架构
        exclude: # 排除某些平台和架构
          - goarch: arm64
            goos: windows
    steps:
      - uses: actions/checkout@v3
      - uses: wangyoucao577/go-release-action@v1.30
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }} # 一个默认的变量，用来实现往 Release 中添加文件
          goos: ${{ matrix.goos }}
          goarch: ${{ matrix.goarch }}
          goversion: 1.18 # 可以指定编译使用的 Golang 版本
          binary_name: "hello" # 可以指定二进制文件的名称
          extra_files: LICENSE README.md # 需要包含的额外文件
```

When you finish writing a version and ready to release, all you have to do is to tag the commit, say `v0.0.2`, the push it to GitHub.
In `Releases` page, click `Draft a new release`, choose the tag, then click on `Publish release` in the bottom.

Then we can dive into `Actions` page, we should see a `workflow` running. When it's done, go back to `Releases` , and there is your release files.

> ### Takeaway：
> With GitHub Actions, you can automate compiling, packaging and releasing binary executables to Release. 

### Build multiplatform binaries for a Golang Program and release it to DockerHub

As mentioned before, the easiest way to run a Golang program is to compile it to a binary executable file, then run it.
This doesn't even need a Golang environment on the actual machine.

Therefore, if you are to pack a Golang program into a Docker image, you only need a minimal Linux system and copy the binary executable into it.

With that in mind, we should be able to write this Dockerfile.

```dockerfile
FROM alpine:3.15.5
COPY hello /usr/local/bin/hello
RUN chmod +x /usr/local/bin/hello
```

We should validate our idea. (Notice: The following code only works on Linux. On macOS and Windows it would not run for the 
compiled binary doesn't match the Docker image's target system and architecture.)

```bash
> docker build -t hello .
...(a lot of logs)
> docker run -it --rm hello
> hello
Hello, world!
```

There it goes! (Or you might fail if you didn't bother to look at the notice before.)

Success or not, you should learn that we should just compile binary executables for different platforms, and then we can build the 
corresponding Docker images.

#### Makefile Magic

As is mentioned earlier, a `go build` with arguments can produce binary executables for different platforms. But we might have various platforms and 
architectures, that's where `Makefile` comes into play.

Let's write a simple `Makefile` assigning different commands to build different platforms. Considering that we only need
`linux/amd64` and `linux/arm64` for our Docker image, we only need the following lines.
If you need a makefile that can run locally and build all the possible platforms, you can refer to the `Makefile` in this repo.

```makefile
all: build-linux-amd64 build-linux-arm64

build-linux-amd64:
	mkdir -p build
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o build/hello_linux_amd64 main.go

build-linux-arm64:
	mkdir -p build
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/hello_linux_arm64 main.go
```

It's worth mentioning that the fist rule `all` is the default rule. When you run `make`, it will run the targets it assigned.
`mkdir -p build` ensures that the output directory exists.

If you use macOS or Linux, you can try running `make`, it would create a `build` directory and put the binary executables into it.

#### Environment Variables in Dockerfile

If you failed in the former test, it is because that the wrong binary executable was packaged into the docker file. Therefore, 
our dockerfile should know which version of binary executable it should grab.

You might find in the previous Makefile, I used different suffixes for different platforms and architectures, like `hello_linux_amd64`.
Now, we should make Dockerfile grab the correct binary executable judging from its target platform and architecture.

Let's modify the former Dockerfile to make it look like this.

```dockerfile
FROM alpine:3.15.5
ARG TARGETOS
ARG TARGETARCH
COPY build/hello_${TARGETOS}_${TARGETARCH} /usr/local/bin/hello
RUN chmod +x /usr/local/bin/hello
```

`TARGETOS` and `TARGETARCH` is Automatic platform ARGs, but you have to use the `ARG` command to claim that you need them.
With `COPY`, we copied the corresponding binary executable to /usr/local/bin and gave it executes permission. So user can run our program with `hello`.

If you failed in the former test, you might try it now.

#### Writing GitHub Actions

To this point, we've cleared all the hurdles, but we still have to write a GitHub Actions workflow to automate the process.

There is no need to create a new Action, we can just add a job to the former one.

```yaml
build-docker-image:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: docker/metadata-action@v4
        id: meta
        with:
          images: leslieleung/hello
      - uses: actions/setup-go@v3
        with:
          go-version: 1.18
      - uses: docker/setup-qemu-action@v2
      - uses: docker/setup-buildx-action@v2
      - uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }} # 记得在 secrets 中添加响应的 secret
          password: ${{ secrets.DOCKERHUB_PASSWORD }}
      - run: make
      - uses: docker/build-push-action@v3
        with:
          context: .
          platforms: linux/arm64,linux/amd64 # 需要的平台
          push: true
          tags: ${{ steps.meta.outputs.tags }}
```

Release a version as mentioned before, then you can see your images on Dockerhub. You shall see `linux/amd64` and `linux/arm64`.

![](http://img.ameow.xyz/20220724185319.png)

There you go, well done!

## References

[GitHub Action - Build and push Docker images](https://github.com/marketplace/actions/build-and-push-docker-images)

[GNU make](https://www.gnu.org/software/make/manual/make.html)

[Dockerfile reference](https://docs.docker.com/engine/reference/builder/#arg)

[wangyoucao577/go-release-action](https://github.com/wangyoucao577/go-release-action)
