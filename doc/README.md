# go-multiplatform-docker

[![build](https://github.com/LeslieLeung/go-multiplatform-docker/actions/workflows/build.yml/badge.svg)](https://github.com/LeslieLeung/go-multiplatform-docker/actions/workflows/build.yml)

[English](README.md) | 简体中文

> 如果要使用 GoReleaser 进行发布，建议查看新版 [LeslieLeung/gin-application-template](https://github.com/LeslieLeung/gin-application-template)。

一个演示如何使用 GitHub Actions 将一个 Golang 项目打包成多平台的二进制文件并发布到 GitHub Releases 和 DockerHub 的例子。

## 由来

作为软件开发者，在软件发布上浪费大量重复劳动是极其没有必要的，这应该是一个高度自动化的过程。在发布软件的过程中，有以下几个痛点：

- 构建多个系统和架构的二进制文件
- 跨平台编译时，可能需要搭建适当的编译环境
- 发布过程繁琐

当然了，这些痛点或多或少已经被解决

- Golang 本身就支持跨平台的编译
- 使用 Docker 或虚拟机等
- 编写发布脚本等

然而，这样还不够"自动化"，如果使用 GitHub Actions 来自动化发布过程，就能更优雅地解决这些问题，使软件开发者更加专注于软件的开发上。

## 前提

本文假设你已经熟悉 Golang、git 和 Docker， 并对 GitHub Actions 有一定了解。

## 让我们开始吧

这篇文章共有两个目标，分别是

- 将一个 Golang 项目打包成多平台的二进制文件并发布到 GitHub Releases
- 将一个 Golang 项目打包成多平台的二进制文件并发布到 DockerHub

### 编写一个简单的 Golang 程序

我们只是为了测试在不同系统和架构上二进制文件的执行，所以一个非常简单的 Golang 程序即可。我们这里就用一个最简单的 Hello World 吧。

```go
package main

import "fmt"

func main() {
	fmt.Println("Hello, World!")
}
```

在终端中运行一下，结果如下。

```bash
> go run main.go
Hello, World!
```

看起来不错，接下来让我们把这个 Golang 程序打包成一个二进制可执行文件。

```bash
> go build -o hello main.go

```

这个命令什么输出都没有，说明运行成功了，没有错误。对于命令行来说，没有消息就是好消息。

在当前目录下，可以看到一个名为 `hello` 的可执行文件（在 Windows 中，该文件可能名为 `hello.exe`）。我们运行一下。

```bash
> ./hello
Hello, World!
```

不错，跟我们之前使用 `go run main.go` 的结果是一样的。

> ### 快速回顾：
> 使用 `go build` 命令可以将一个 Golang 程序打包成二进制可执行文件。

### 编译跨平台二进制可执行文件

还记得前面提到，在 Windows 平台上，`go build` 命令会生成一个以 `.exe` 结尾的可执行文件，这就不得不提 Golang 的跨平台编译能力。Golang 能轻松地生成不同平台上的二进制可执行文件，不需要开发者了解任何跨平台编译方面的细节。

假设我们正在使用 macOS 进行开发，如果我们需要编译一个可以在 Windows 平台上运行的二进制可执行文件，我们只需要运行

```bash
> CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o hello_windows_amd64.exe main.go

```

目录下就会生成一个 `hello_windows_amd64.exe` 文件，复制到 Windows 下运行即可。

### 编译多平台二进制可执行文件并打包发布到 GitHub Releases

在开始之前，你可以看一下本项目的 [Releases](https://github.com/LeslieLeung/go-multiplatform-docker/releases)

![](http://img.ameow.xyz/20220724180813.png)

可以看到，对于每个目标平台，都有一个对应的 `tar.gz` 或 `zip` 压缩包，及其对应的 `md5` 校验码。压缩包中含有二进制可执行文件以及 `LISENCE` 和 `README.md` 文件。

这一步的实现非常简单，已经有现成的 Actions 替我们搞定。见 [wangyoucao577/go-release-action](https://github.com/wangyoucao577/go-release-action) 。

它的用法非常简单，如下。

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

当你完成一个版本代码的编写，准备要发布时，只需要在 git 中对该提交打上版本号，如 `v0.0.2`，然后提交至 GitHub。在 `Releases` 页面，点击 `Draft a new release`，选择刚才的标签，点击最底下的 `Publish release` 按钮即可。

然后我们可以进入 `Actions` 页面，应该可以看见已经有 `workflow` 正在运行。完成后，再回到 `Releases` 页面，就可以看到打包出的文件。

> ### 快速回顾：
> 使用 GitHub Actions 可以自动化编译、打包并将二进制可执行文件发布到 Release。

### 编译多平台二进制可执行文件并打包发布到 DockerHub

前面提到过，运行一个 Golang 程序最简单的方法就是将其编译成二进制可执行文件后，直接运行。这一步甚至不需要考虑实际运行的机器上是否有 Go 环境。

因此，如果要把 Golang 程序打包进一个 Docker 镜像，只需要一个最小的 Linux 系统，把这个二进制文件打包进去即可。

知道这个以后，我们很顺其自然就可以编写出以下 Dockerfile。

```dockerfile
FROM alpine:3.15.5
COPY hello /usr/local/bin/hello
RUN chmod +x /usr/local/bin/hello
```

简单验证一下我们的想法。（注意：以下代码仅能在 Linux 下运行，在 macOS 和 Windows 上会因为编译出的二进制文件与 Docker 的运行环境不匹配而不能运行。）

```bash
> docker build -t hello .
...(输出大量的日志)
> docker run -it --rm hello
> hello
Hello, world!
```

成功了！（或者失败了，因为你没看我前面的注意）

不管到这一步你是成功还是失败，你应该已经想到，只需要编译出不同平台上的二进制可执行文件，再构建对应平台的 Docker 镜像就好了。

#### Makefile 魔法

前面讲过，我们使用带参数的 `go build` 命令就可以生成在不同平台下的二进制可执行文件。但是我们可能有多个平台和架构，这时候 `Makefile` 就派上用场了。

我们编写一个简单的 `Makefile` ，里面指定了编译不同平台和架构使用的命令。考虑到我们的 Docker 镜像只需要 `linux/amd64` 和 `linux/arm64` 两个平台，所以我们只需要编写下面的两行命令。
当然，如果你需要一个可以本地使用，能直接编译所有平台的二进制可执行文件的 makefile ，可以参考仓库中的 `Makefile` 文件。

```makefile
all: build-linux-amd64 build-linux-arm64

build-linux-amd64:
	mkdir -p build
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o build/hello_linux_amd64 main.go

build-linux-arm64:
	mkdir -p build
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o build/hello_linux_arm64 main.go
```

需要注意的是，第一条规则 `all` 为默认的规则，执行 `make` 时就执行它指定的目标。`mkdir -p build` 保证了输出目录一定存在。

如果你使用 macOS 或者 Linux 系统，可以试着运行 `make` 命令，它会在当前目录下创建一个 `build` 文件夹，并将生成的二进制可执行文件都放在里面。

#### Dockerfile 中的环境变量

前面提到过，如果你在前面的小试验中失败了，是因为 Docker 镜像中打包进了错误的二进制可执行文件。因此我们需要控制打包进镜像的二进制可执行文件的版本。

在上一步的 Makefile 中，可能你已经发现，我使用了后缀来区分不同平台和架构的二进制可执行文件，例如 `hello_linux_amd64` 。
在这一步中，我们需要让 Dockerfile 通过打包镜像的平台和架构，自动选择合适的二进制可执行文件。

我们修改一下之前的 Dockerfile， 使他变成以下的样子。

```dockerfile
FROM alpine:3.15.5
ARG TARGETOS
ARG TARGETARCH
COPY build/hello_${TARGETOS}_${TARGETARCH} /usr/local/bin/hello
RUN chmod +x /usr/local/bin/hello
```

`TARGETOS` 和 `TARGETARCH` 是自带的自动变量，但你需要使用 `ARG` 命令来说明你需要这两个变量。
在 `COPY` 命令中，可以看到我们把对应平台和架构的二进制可执行文件拷贝到了 /usr/local/bin 目录下并给了它可执行权限，因此用户直接输入 `hello` 就能运行我们的程序。

如果你在上一次小试验没有成功，现在可以重新试一下了。

#### 编写 GitHub Actions

至此，所有的障碍我们都已经解决了，剩下就是编写一个可以自动完成上面流程的 GitHub Actions。

我们不需要新建一个 Action， 只需要在之前的 Action 上新增一个作业（job）即可。

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

像前面一样发布一个新的版本，然后在 Dockerhub 上就能看到刚才构建的镜像了。可以看到有 `linux/amd64` 和 `linux/arm64` 两个平台。

![](http://img.ameow.xyz/20220724185319.png)

大功告成！

## 番外

经过 v2ex 论坛上的朋友提醒（见原帖 [关于 Golang 多平台打包发布这件事..](https://v2ex.com/t/868435) ），另外还有两种方法供参考。

- [GoReleaser](https://goreleaser.com/)：能够提供跨平台编译及打包 Docker 镜像、发布等，非常强大的工具。有免费和付费的 Pro 版本。
- [gox](https://github.com/mitchellh/gox)：能够并行编译。

由于 gox 具有并行编译的特性，这里增加一下关于 gox 的介绍。

### 使用 gox 加速发布过程

通过查看 gox 的文档可以发现， gox 的命令非常简单。我们往前面的 Makefile 中添加以下几行。

```makefile
gox-linux:
	gox -osarch="linux/amd64 linux/arm64" -output="build/hello_{{.OS}}_{{.Arch}}"

gox-all:
	gox -osarch="darwin/amd64 darwin/arm64 linux/amd64 linux/arm64 windows/amd64" -output="build/hello_{{.OS}}_{{.Arch}}"
```

此时，运行 `make gox-linux` 或 `make gox-all` 就能完成对应平台的编译了。

同时修改一下 `build.yml`。

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
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_PASSWORD }}
      - run: go install github.com/mitchellh/gox@latest # 安装 gox
      - run: make gox-linux
      - uses: docker/build-push-action@v3
        with:
          context: .
          platforms: linux/arm64,linux/amd64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
```

## 常见问题

### 权限不足，发布到 Release 失败

原因见 [链接](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#setting-the-permissions-of-the-github_token-for-your-repository)。

解决方法：在 `build.yml` 中添加以下内容。

```yaml
name: build

on:
  release:
    types: [created]
    
permissions: # 添加
  contents: write # 添加

jobs:
  build-go-binary:
    runs-on: ubuntu-latest
...
```

## 参考

[GitHub Action - Build and push Docker images](https://github.com/marketplace/actions/build-and-push-docker-images)

[GNU make](https://www.gnu.org/software/make/manual/make.html)

[Dockerfile reference](https://docs.docker.com/engine/reference/builder/#arg)

[wangyoucao577/go-release-action](https://github.com/wangyoucao577/go-release-action)
