# 几种姿势：调试 go mod、go build 命令等 Golang 自身源码（VSCode、GoLand）

断点调试（后简称 debug），是摸索代码内部机制（特别是 Golang 内部）的一种快速手段。

本文将介绍的 debug 方式：

- debug：项目源码、第三方依赖库、Go 标准库
- debug：`go` 命令的源码
  - `go build` 编译器的源码
  - `go mod` 包管理命令的源码
- debug：Golang 自身的单元测试源码
- 基于 VSCode、GoLand 的 debug

本文暂不讨论：

- 命令行调试
- 远程调试
- 基于 [GDB](https://golang.org/doc/gdb) 的调试
- 如何准备 Delve 等工具

> 曾经，想了解 `go mod` 命令的内部运作机制，若当时知道如何断点调试 `go mod`，进度应可快不少。

# 目录

<!--ts-->
   * [几种姿势：调试 go mod、go build 命令等 Golang 自身源码（VSCode、GoLand）](#几种姿势调试-go-modgo-build-命令等-golang-自身源码vscodegoland)
   * [目录](#目录)
   * [实例项目](#实例项目)
   * [实验环境](#实验环境)
   * [VSCode 调试项目源码、第三方依赖库、Go 标准库](#vscode-调试项目源码第三方依赖库go-标准库)
      * [步骤](#步骤)
      * [说明](#说明)
   * [VSCode 已打开项目源码情况下，如何再打开标准库或第三方依赖包的源码文件？](#vscode-已打开项目源码情况下如何再打开标准库或第三方依赖包的源码文件)
   * [GoLand 调试项目源码、第三方依赖库、Go 标准库](#goland-调试项目源码第三方依赖库go-标准库)
      * [步骤](#步骤-1)
      * [说明](#说明-1)
   * [VSCode 调试 go build 编译器本身](#vscode-调试-go-build-编译器本身)
      * [步骤](#步骤-2)
      * [说明](#说明-2)
   * [GoLand 调试 go build 编译器本身](#goland-调试-go-build-编译器本身)
      * [步骤](#步骤-3)
      * [说明](#说明-3)
   * [VSCode 调试 go mod 命令](#vscode-调试-go-mod-命令)
   * [GoLand 调试 go mod 命令](#goland-调试-go-mod-命令)
   * [调试 go get 命令](#调试-go-get-命令)
   * [VSCode 调试 Golang 自身单元测试源码](#vscode-调试-golang-自身单元测试源码)
      * [步骤](#步骤-4)
   * [GoLand 调试 Golang 自身单元测试源码](#goland-调试-golang-自身单元测试源码)
   * [小结](#小结)


<!--te-->

# 实例项目

本文所有调试均以此项目为例：https://github.com/vikyd/go-example

- 此项目引用了 time 标准库、uuid 第三方库，只打印基础信息，足够简单
- 此项目的 `.vscode/launch.json` 包含了 VSCode 中各类型的调试配置
- 此项目的 `.idea` 包含了 GoLand 中各类型的调试配置

本文以 `~/tpm/go-example/` 作为实验目录，以 `~/tmp/debuggo/` 作为新编译 `go` 命令的存放目录。

# 实验环境

- OS：Mac 10.15.6
- Go：1.15.2
- VSCode：1.49.1
  - [Golang 插件](https://marketplace.visualstudio.com/items?itemName=golang.Go)
- GoLand：2020.2

> Windows 的同学注意修改下 debug 配置的相关路径

# VSCode 调试项目源码、第三方依赖库、Go 标准库

本调试依赖 `.vscode/launch.json` 的 `debug: main.go` 配置。

本小节是 VSCode debug Golang 的普通步骤。

## 步骤

- VSCode 打开 [实例项目](https://github.com/vikyd/go-example)：`code ~/tmp/go-example`
- 打几个断点：
  - `main.go` → `fmt.Println(a)`
  - `main.go` → 约第 13 行 `Format` → 按 F12 跳转到 Go 标准库 `format.go` → `if max < bufSize`
  - `main.go` → 约第 14 行 `New` → 按 F12 跳转到第三方依赖库 `version4.go` → 约第 41 行 `uuid[8] = (uuid[8] & 0x3f) | 0x80`
- 开始 debug：
  - 点击 VSCode 左侧栏的 debug 按钮
  - 顶部选择 `debug: main.go`
  - 按下 F5
  - debug 已开始
- over

## 说明

- VSCode 调试 Go 标准库、第三方依赖包，其实与调试项目源码没区别，步骤一样

# VSCode 已打开项目源码情况下，如何再打开标准库或第三方依赖包的源码文件？

**方法 01：**

项目源码中按 F12 跳转到引用的源码（但若想打开非直接引用的文件就不如 GoLand 方便，见 `方法02`）

**方法 02：**

另开一个 VSCode 实例打开引用的源码（标准库：`$GOROOT/src`，第三方库：`$GOPATH/pkg/mod`），打开想要的文件，顶部文件名右键 `Copy Path`，再回到项目源码窗口 `Command + p` 粘贴打开该文件

**方法 03：**

同前面 `Copy Path`，再回到项目源码的 Terminal 窗口执行命令 `code 该文件路径` 即可打开该文件

# GoLand 调试项目源码、第三方依赖库、Go 标准库

本小节是 GoLand debug Golang 的普通步骤。

## 步骤

- GoLand 打开 [实例项目](https://github.com/vikyd/go-example)（假设项目目录是：`~/tmp/go-example`）
- 打几个断点：与上一节 VSCode 类似
- 开始 debug：
  - 顶部栏右上方的左边下拉框选择 `debug: main.go`
  - 点击下拉框右侧的 `debug` 按钮
  - debug 已开始
- over

## 说明

- `debug: main.go` 对应配置的查看与说明：
  - 顶部栏右侧的左边下拉框选择 `Edit Configurations...`
  - Run kind：`File`
  - Files：`/Users/viky/tmp/go-example/main.go`
  - Working directory：`/Users/viky/tmp/go-example`
- GoLand 调试 Go 标准库、第三方依赖包其实与调试项目源码没区别，步骤一样
- GoLand 打开标准库、第三方依赖包源码很方便，右侧窗口展开 `External Libraries` 就能看到（此功能值得 VSCode 学习）

# VSCode 调试 `go build` 编译器本身

调试 `go build` 编译器本身，是指调试 `go build` 这个命令背后编译流程的代码，如：[$GOROOT/src/cmd/go/internal/work/build.go](https://github.com/golang/go/blob/master/src/cmd/go/internal/work/build.go)。

本小节要调试的命令：`go build -v`

## 步骤

- VSCode 打开 [实例项目](https://github.com/vikyd/go-example)：`code ~/tmp/go-example`
- 打几个断点：
  - 当前窗口打开下面文件（打开方式参考前面小节）
  - `$GOROOT/src/cmd/go/main.go` → 约第 86 行 `flag.Parse()`
    - 此文件是 `go` 命令本身的主入口
  - `$GOROOT/src/cmd/go/internal/work/build.go` → `func runBuild` 内约第 351 行 `pkgs := load.PackagesForBuild(args)`
- 预先构建被 debug 的 `go` 命令二进制文件（关键！！！）
  - 创建新目录 `~/tmp/debuggo/`
  - 先进入该目录，再执行命令：`go build -gcflags="all=-N -l" -o debuggo cmd/go`
    - [`-gcflags="all=-N -l"`](https://github.com/go-delve/delve/blob/master/Documentation/usage/dlv_exec.md#synopsis) 表示 [禁用优化](https://golang.org/cmd/compile/#hdr-Command_Line)
  - 得到新的二进制文件 `~/tmp/debuggo/debuggo`
    - 这是一个包含调试信息的新 `go` 命令二进制文件
- 开始 debug：
  - 点击 VSCode 左侧栏的 debug 按钮
  - 顶部选择 `debug: go build -v`
  - 按下 F5
  - debug 已开始
- 调试结束后 `go-example/` 目录会得到：
  - 一个二进制文件 `go-example/go-example`
    - 可执行此文件：`./go-example`，得三行输出
  - 一个 `go.sum` 文件
- over

## 说明

- 本 debug 与 `go-example/main.go` 无关，此文件在这里是被编译，而非被执行
- 本 debug 对应 `.vscode/launch.json` 的 `debug: go build -v` 配置，说明：

```json
// debug $GOROOT/src/cmd/go/main.go + `go build -v` command
{
  "name": "debug: go build -v",

  "type": "go",

  "request": "launch",

  // 调试一个现成的二进制文件
  "mode": "exec",

  // 指定工作目录（go build 输出的文件会存放到此目录）
  // cwd 全称: current working directory
  "cwd": "${workspaceFolder}",

  // 被调试的 go 命令二进制文件
  // 此文件来自于前面的构建命令对 `$GOROOT/src/cmd/go` 这个 package 的构建
  // 请修改为你的二进制文件所在位置（绝对路径或下面格式引用环境变量）
  "program": "${env:HOME}/tmp/debuggo/debuggo",

  // 让更多日志输出 `DEBUG CONSOLE`，调试不成功时便于定位问题
  "trace": "log",

  // `go build -v` 命令的参数
  // 各参数需拆分为多项，而非 `build -v` 写到同一项
  "args": ["build", "-v"],
},
```

- VSCode 调试 `go build` 命令前，为什么要预先编译一个 `go` 命令的二进制文件？下面解答
  - 此时留意底部 `DEBUG CONSOLE` 窗口内容的前面部分：

```
/var/folders/0t/yzb0gynd37q_6tkyj87td4h80000gn/T/vscode-go-debug.txt
InitializeRequest
InitializeResponse
LaunchRequest
Using GOPATH: /Users/viky/go
Using GOROOT: /usr/local/go
Using PATH: /usr/local/go/bin:/Users/viky/.opam/default/bin:/usr/local/Cellar/emacs/26.1_1/bin:/Users/viky/.composer/vendor/bin:/usr/local/Cellar/php@7.3/7.3.21/bin:/Users/viky/go/bin:/Users/viky/.nvm/versions/node/v12.13.1/bin:/Users/viky/.cargo/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Frameworks/Mono.framework/Versions/Current/Commands:/Applications/Wireshark.app/Contents/MacOS:/Applications/Visual Studio Code.app/Contents/Resources/app/bin:/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home/bin:/Users/viky/soft/apache-maven-3.6.0/bin:/usr/local/mysql/bin:/Users/viky/soft/flutter/bin:/Users/viky/soft/bin:/Users/viky/soft/etcd-v3.4.9-darwin-amd64:/Users/viky/.pub-cache/bin
Current working directory: /Users/viky/tmp/debuggo
Running: /Users/viky/go/bin/dlv exec /Users/viky/tmp/debuggo/debuggo --headless=true --listen=127.0.0.1:12311 --api-version=2 --wd=/Users/viky/tmp/go-example -- build -v
API server listening at: 127.0.0.1:12311
......
```

留意其中一行：

```
Running: /Users/viky/go/bin/dlv exec /Users/viky/tmp/debuggo/debuggo --headless=true --listen=127.0.0.1:12311 --api-version=2 --wd=/Users/viky/tmp/go-example -- build -v
```

为方便理解，将此行简化为：

```sh
dlv exec goDebugBinaryFile --listen=127.0.0.1:12311 -- build -v
```

可知：VSCode 本质是基于开源的 [Delve](https://github.com/go-delve/delve) 进行 debug，`dlv` 的全部参数见 [这里](https://github.com/go-delve/delve/blob/master/Documentation/usage/dlv.md)。

# GoLand 调试 `go build` 编译器本身

前面 VSCode 已介绍被调试内容，直接上步骤。

## 步骤

- GoLand 打开 [实例项目](https://github.com/vikyd/go-example)（假设项目放在 `~/tmp/go-example`）
- 打几个断点：与上一节 VSCode 类似
  - GoLand 可双击 `shift` 键快速搜索想打开的源码文件
- 开始 debug：
  - 顶部栏右上方的左边下拉框选择 `debug: go build -v`
  - 点击下拉框右侧的 `debug` 按钮
  - debug 已开始
- over

## 说明

- 本调试与 `go-example/main.go` 无关，此文件在这里是被编译，而非被执行
- `debug: go build -v` 对应的配置查看和说明：
  - 顶部栏右侧的左边下拉框选择 `Edit Configurations...`
  - Run kind：`Package`
  - Package path：`cmd/go`
    - 对应 `$GOROOT/src/cmd/go` 目录
  - Working directory：`/Users/viky/tmp/go-example`
  - Program arguments：`build -v`
- GoLand 调试 `go build` 命令时，无需手动预先编译一个 `go` 命令文件出来，原因往下看：
  - 观察下方的 Debug 栏里 Console 窗口的内容：

```sh
GOROOT=/usr/local/go #gosetup
GOPATH=/Users/viky/go #gosetup
/usr/local/go/bin/go build -o /private/var/folders/0t/yzb0gynd37q_6tkyj87td4h80000gn/T/___debug__go_build__v -gcflags all=-N -l cmd/go #gosetup
/Applications/GoLand.app/Contents/plugins/go/lib/dlv/mac/dlv --listen=0.0.0.0:54162 --headless=true --api-version=2 --check-go-version=false --only-same-user=false exec /private/var/folders/0t/yzb0gynd37q_6tkyj87td4h80000gn/T/___debug__go_build__v -- build -v
API server listening at: [::]:54162
debugserver-@(#)PROGRAM:LLDB  PROJECT:lldb-1200.0.32
 for x86_64.
Got a connection, launched process /private/var/folders/0t/yzb0gynd37q_6tkyj87td4h80000gn/T/___debug__go_build__v (pid = 64462).
go: downloading github.com/google/uuid v1.1.2
Exiting.

Debugger finished with exit code 0

```

留意其中一行：

```sh
/usr/local/go/bin/go build -o /private/var/folders/0t/yzb0gynd37q_6tkyj87td4h80000gn/T/___debug__go_build__v -gcflags all=-N -l cmd/go #gosetup
```

为方便理解，将此行简化为：

```sh
go build -o outputFile -gcflags all=-N -l cmd/go
# 在 mac 相当于
# go build -o outputFile -gcflags="all=-N -l" cmd/go
```

可理解为：GoLand 其实也是需要预编译含调试信息的 `go` 命令二进制文件，区别在于 GoLand 帮我们做了这一步，而 VSCode 并没有自动做这一步。

再往下看一行：

```sh
/Applications/GoLand.app/Contents/plugins/go/lib/dlv/mac/dlv --listen=0.0.0.0:54162 --headless=true --api-version=2 --check-go-version=false --only-same-user=false exec /private/var/folders/0t/yzb0gynd37q_6tkyj87td4h80000gn/T/___debug__go_build__v -- build -v
```

为便于理解，将此行简化为：

```sh
dlv --listen=0.0.0.0:54162 exec goDebugBinaryFile -- build -v
```

GoLand 本质也是基于开源的 [Delve](https://github.com/go-delve/delve) 进行 debug，`dlv` 的全部参数见 [这里](https://github.com/go-delve/delve/blob/master/Documentation/usage/dlv.md)。

# VSCode 调试 `go mod` 命令

go mod 有很多命令 `go mod init`、`go mod download`、`go mod tidy` 等，更多可见 `go help mod`。

本小节介绍如何 debug 这些命令，以 `go mod tidy` 为例。

调试 `go mod tidy` 的原理、步骤与前面 debug 的 `go build -v` 命令类似。为避免重复，这里只说下此命令可打断点的大致位置。

步骤：

- 清空缓存，以便验证效果（不清空也无所谓）
  - 删除 `go-example/go.sum` 文件
  - 删除整个缓存目录 `go clean --modcache`
- debug 选择：`debug: go mod tidy -v`
- 建议打断点位置：
  - `$GOROOT/src/cmd/go/main.go` → 约第 86 行 `flag.Parse()`
  - `$GOROOT/src/cmd/go/internal/tidy.go`
    - 约第 41 行 `if len(args) > 0`
    - 约第 48 行 `modload.WriteGoMod()`
- 开始 debug
- debug 结束会发现：
  - `go-example/go.sum` 又重新出现了
  - `$GOROOT/pkg/mod` 里又重新出现了依赖包的源码（如 `$GOROOT/pkg/mod/github.com/google/uuid@v1.1.2` 目录）

# GoLand 调试 `go mod` 命令

与前面类似。

# 调试 `go get` 命令

类似于前面 `go build`、`go mod` 的调试，[示例项目](https://github.com/vikyd/go-example) 里已包含 `go get` 命令的调试配置。

建议打断点位置：

- `$GOROOT/src/cmd/go/main.go` → 约第 86 行 `flag.Parse()`
- `$GOROOT/src/cmd/go/internal/modget.go`
  - `func runGet` 函数内部约第 263 行

# VSCode 调试 Golang 自身单元测试源码

若需单独调试 Golang 自身源码的单元测试，则可单独打开 `$GOROOT/src`。

## 步骤

- 打开 Golang 自身源码：`code $GOROOT/src`
- 打开单元测试用例
  - 如：`$GOROOT/src/path/filepath/path_test.go`
- 设置断点（以 [path_test.go](https://github.com/golang/go/blob/master/src/path/path_test.go) 为例）：
  - `func TestClean(t *testing.T)` 内的这行 ` for _, test := range tests`
- debug 方式 01：点击 `func TestClean` 函数名上一行的 `debug test` 灰色小字 即开始 debug
- debug 方式 02：鼠标聚焦到 `path_test.go` 文件，按下 F5，然后选择 `Go`，即开始 debug
- over

# GoLand 调试 Golang 自身单元测试源码

暂未找到调试 Golang 自身单元测试源码的快速方法。

# 小结

说了那么多，都是为了方便 debug Golang 自身源码。

VSCode：

- 方便 debug Golang 自身源码内的单元测试
- VSCode debug 时 F5、F8 按得较爽
- GoLand 能 debug 的，VSCode 也能 debug
- 但 VSCode 的 watch 变量功能不太好用
- VSCode 需自行编译 `go` 命令才能调试 Golang 自身源码，麻烦一步
- 打开 Go 标准库、第三方库文件相对麻烦

GoLand：

- watch 变量功能好用
- GoLand 无需手动编译 `go` 命令就能调试 Golang 自身源码，较方便
- GoLand debug 的快捷键有些不适应

共同点：

- VSCode、GoLand 均是基于 [Delve](https://github.com/go-delve/delve) 调试器的界面化封装
