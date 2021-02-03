# A Tour of Versioned Go (vgo)

原文：https://research.swtch.com/vgo-tour

作者：[Russ Cox](https://swtch.com/~rsc/)

翻译时间：2020-01-17

# Go 语言的版本管理教程（vgo）

（[Go 与版本管理](https://research.swtch.com/vgo)，第 2 部分）

发表时间：2018-02-20 周二 [PDF](https://research.swtch.com/vgo-tour.pdf)

# 目录

<!--ts-->
   * [A Tour of Versioned Go (vgo)](#a-tour-of-versioned-go-vgo)
   * [Go 语言的版本管理教程（vgo）](#go-语言的版本管理教程vgo)
   * [目录](#目录)
   * [正文](#正文)
   * [实例](#实例)
      * [Hello, world](#hello-world)
      * [升级模块](#升级模块)
      * [降级模块](#降级模块)
      * [排除模块](#排除模块)
      * [替换模块](#替换模块)
      * [向后兼容性](#向后兼容性)
   * [下一步？](#下一步)


<!--te-->

# 正文

对于我来说，所谓设计，就不断构建、拆散、再构建的过程。为了写 [一个新的版本提案](https://github.com/vikyd/note/blob/master/go_and_versioning/go_add_package_versioning.md)，我创建了一个名为 vgo 的原型工具，用于验证提案的各种细节。本文将详细介绍如何一步步使用 vgo。

你现在可通过 `go get golang.org/x/vgo` 来获取 vgo。vgo 是 go 命令的一个即插即用的替代品（vgo fork 自 go）。你可用 vgo 替代 go 命令，vgo 会自动使用 \$GOROOT（Go 1.10beat1 或更新版本）所指定的标准编译器和标准库来编译程序。

根据实际使用效果的好坏，vgo 中的语义和命令也可能随之而调整。不管怎样，在未来我们依然会保持对当前 go.mod 文件格式的兼容性，你现在创建的 go.mod 文件在以后依然可使用。随着提案的进化，我们也会随时更新 vgo。

# 实例

本章节将演示 vgo 的使用细节。请按步操作，或按需做一些调整。

首先，安装 vgo：

```sh
$ go get -u golang.org/x/vgo
```

安装 vgo 时，你肯定会遇到一些 bug，因为目前的 vgo 只做了简单的测试。若发现 bug，请使用 [Go 的 bug 跟踪器](https://golang.org/issue) 来提 bug，并以 `x/vgo:` 作为 bug 的标题。谢谢！

## Hello, world

让我们开始写一个 `hello, world` 程序。在 `GOPATH/src` 外新建一个空目录，并进入该目录：

```sh
$ cd $HOME
$ mkdir hello
$ cd hello
```

新建 hello.go 文件：

```go
package main // import "github.com/you/hello"

import (
	"fmt"
	"rsc.io/quote"
)

func main() {
	fmt.Println(quote.Hello())
}
```

也可直接下载这个文件：

```sh
$ curl -sS https://swtch.com/hello.go >hello.go
```

新建一个空文件，命名为 go.mod，表示当前目录是模块的根目录。然后构建、执行程序：

```sh
$ echo >go.mod
$ vgo build
vgo: resolving import "rsc.io/quote"
vgo: finding rsc.io/quote (latest)
vgo: adding rsc.io/quote v1.5.2
vgo: finding rsc.io/quote v1.5.2
vgo: finding rsc.io/sampler v1.3.0
vgo: finding golang.org/x/text v0.0.0-20170915032832-14c0d48ead0c
vgo: downloading rsc.io/quote v1.5.2
vgo: downloading rsc.io/sampler v1.3.0
vgo: downloading golang.org/x/text v0.0.0-20170915032832-14c0d48ead0c
$ ./hello
Hello, world.
$
```

注意，此时无需执行 `vgo get` 命令。`vgo build` 命令本身会在模块源码中寻找已 import 的依赖模块，若依赖末下载，则会自动下载其最新版本，并将其添加到当前模块的需求列表中。

vgo 的任何命令都可能有一个副作用，那就是会更新 go.mod 文件的内容。在这个实例中，`vgo build` 会将以下信息写入到 go.mod 中：

```sh
$ cat go.mod
module github.com/you/hello

require rsc.io/quote v1.5.2
$
```

由于 go.mod 已包含依赖模块列表，所以再次运行 `vgo build` 时不会再打印 import 相关信息：

```sh
$ vgo build
$ ./hello
Hello, world.
$
```

即使第二天 `rsc.io/quote` 发布了新的 v1.5.3、v1.6.0，vgo 的构建依然会继续使用 v1.5.2，除非你明确去升级依赖版本（见下面）。

go.mod 文件中包含的是需求的最小集合，且不会列出子依赖列表。在本实例中，`rsc.io/quote` v1.5.2 依赖了 `rsc.io/sampler` 和 `golang.org/x/text` 的某个版本，在第 1 次 `vgo build` 时已打印这些依赖信息，所以没必要再在 go.mod 中重复列出。

当然，也可通过 `vgo list -m` 命令（译注：对应 Go 1.13 中的 `go list -m all`）来再次查看构建将用到的完整依赖列表：

```sh
$ vgo list -m
MODULE                VERSION
github.com/you/hello  -
golang.org/x/text     v0.0.0-20170915032832-14c0d48ead0c
rsc.io/quote          v1.5.2
rsc.io/sampler        v1.3.0
$
```

此时你可能会觉得奇怪，为何我们的 `hellp world` 程序用到了 `golang.org/x/text`。这是因为 `rsc.io/quote` 依赖了 `rsc.io/sampler`，而 `rsc.io/sampler` 又依赖了 `golang.org/x/text`（用于 [检测语言](https://blog.golang.org/matchlang)）：

```sh
$ LANG=fr ./hello
Bonjour le monde.
$
```

> 译注：这是打印法语版的 "hello world"

## 升级模块

由前面可知，在添加新模块到项目后，vgo 会在构建时自动选择该模块的最新版本。项目依赖了模块 `rsc.io/quote`，并且当时此模块最新版本是 v1.5.2。之后，若不 import 新的依赖，vgo 将只会使用 go.mod 中列出的依赖版本。`rsc.io/quote` 间接依赖了 `golang.org/x/text` 和 `rsc.io/sampler` 的某个版本。若在 `vgo list` 命令中添加 `-u` 参数（检查依赖包更新），则可看到依赖包有哪些新版本可用：

```sh
$ vgo list -m -u
MODULE                VERSION                             LATEST
github.com/you/hello  -                                   -
golang.org/x/text     v0.0.0-20170915032832-14c0d48ead0c  v0.3.0 (2017-12-14 08:08)
rsc.io/quote          v1.5.2 (2018-02-14 10:44)           -
rsc.io/sampler        v1.3.0 (2018-02-13 14:05)           v1.99.99 (2018-02-13 17:20)
$
```

> 译注：Go 1.13 中对应 `go list -m -u`

从上面输出可知，2 个间接依赖包都有新的版本，所以我们的 hello 程序可升级这些依赖。

首先升级 `golang.org/x/text`：

```sh
$ vgo get golang.org/x/text
vgo: finding golang.org/x/text v0.3.0
vgo: downloading golang.org/x/text v0.3.0
$ cat go.mod
module github.com/you/hello

require (
	golang.org/x/text v0.3.0
	rsc.io/quote v1.5.2
)
$
```

`vgo get` 命令会寻找该模块的最新版本，并将最新版本信息添加到当前模块的需求列表中，即更新到 go.mod 中。从此以后，构建都会使用 `text` 模块的新版本：

```sh
$ vgo list -m
MODULE                VERSION
github.com/you/hello  -
golang.org/x/text     v0.3.0
rsc.io/quote          v1.5.2
rsc.io/sampler        v1.3.0
$
```

当然，升级一个依赖包后，正常来说应回归测试一下项目的功能。升级 `text` 模块后，依赖它的模块 `rsc.io/quote` 和 `rsc.io/sampler` 还没进行测试。现在来跑一下测试：

```sh
$ vgo test all
?   	github.com/you/hello	[no test files]
?   	golang.org/x/text/internal/gen	[no test files]
ok  	golang.org/x/text/internal/tag	0.020s
?   	golang.org/x/text/internal/testtext	[no test files]
ok  	golang.org/x/text/internal/ucd	0.020s
ok  	golang.org/x/text/language	0.068s
ok  	golang.org/x/text/unicode/cldr	0.063s
ok  	rsc.io/quote	0.015s
ok  	rsc.io/sampler	0.016s
$
```

原始的 go 命令中，`all` 表示 GOPATH 中的全部包，这不是我们想要的。于是，在 vgo 中我们将 `all` 的范围缩减为：`当前模块的所有包 + 所有依赖包（含子依赖）`。v1.5.2 版本的 `rsc.io/quote` 中的一个包有 bug：

```sh
$ vgo test rsc.io/quote/...
ok  	rsc.io/quote	(cached)
--- FAIL: Test (0.00s)
	buggy_test.go:10: buggy!
FAIL
FAIL	rsc.io/quote/buggy	0.014s
(exit status 1)
$
```

除非我们的模块中 import 了这个有 bug 的包，否则此 bug 其实与我们无关，所以 `all` 也不包含这些包。不管怎样，升级 `x/text` 模块后实际也没出问题，所以此时我们可以 commit 修改后的 go.mod 了。

另一个选择是，用 `vgo get -u` 命令一次性升级构建用到的所有依赖包：

```sh
$ vgo get -u
vgo: finding golang.org/x/text latest
vgo: finding rsc.io/quote latest
vgo: finding rsc.io/sampler latest
vgo: finding rsc.io/sampler v1.99.99
vgo: finding golang.org/x/text latest
vgo: downloading rsc.io/sampler v1.99.99
$ cat go.mod
module github.com/you/hello

require (
	golang.org/x/text v0.3.0
	rsc.io/quote v1.5.2
	rsc.io/sampler v1.99.99
)
$
```

此时，`vgo get -u` 后，`text` 模块依然是升级后的版本，而 `rsc.io/sampler` 模块则已更新到了最新的版本 v1.99.99。

再跑一下测试：

```sh
$ vgo test all
?   	github.com/you/hello	[no test files]
?   	golang.org/x/text/internal/gen	[no test files]
ok  	golang.org/x/text/internal/tag	(cached)
?   	golang.org/x/text/internal/testtext	[no test files]
ok  	golang.org/x/text/internal/ucd	(cached)
ok  	golang.org/x/text/language	0.070s
ok  	golang.org/x/text/unicode/cldr	(cached)
--- FAIL: TestHello (0.00s)
	quote_test.go:19: Hello() = "99 bottles of beer on the wall, 99 bottles of beer, ...", want "Hello, world."
FAIL
FAIL	rsc.io/quote	0.014s
--- FAIL: TestHello (0.00s)
	hello_test.go:31: Hello([en-US fr]) = "99 bottles of beer on the wall, 99 bottles of beer, ...", want "Hello, world."
	hello_test.go:31: Hello([fr en-US]) = "99 bottles of beer on the wall, 99 bottles of beer, ...", want "Bonjour le monde."
FAIL
FAIL	rsc.io/sampler	0.014s
(exit status 1)
$
```

此时可见出错信息与 `rsc.io/sampler` v1.99.99 有关，果然：

```sh
$ vgo build
$ ./hello
99 bottles of beer on the wall, 99 bottles of beer, ...
$
```

`vgo get -u` 这种下载每个依赖最新版本的行为正是 `go get` 命令的默认行为（所需的包不存在于 GOPATH 时）。在一个 GOPATH 为空的系统中：

```sh
$ go get -d rsc.io/hello
$ go build -o badhello rsc.io/hello
$ ./badhello
99 bottles of beer on the wall, 99 bottles of beer, ...
$
```

此中的重要区别是：vgo 不会像上面命令那样默认下载最新版本的依赖包。vgo 还允许用户对依赖版本进行降级。

## 降级模块

若需降级一个依赖包的版本，可执行 `vgo list -t` 命令来显示可降级到的 tag 版本：

```sh
$ vgo list -t rsc.io/sampler
rsc.io/sampler
	v1.0.0
	v1.2.0
	v1.2.1
	v1.3.0
	v1.3.1
	v1.99.99
$
```

然后执行 `vgo get` 来获取某个版本，如 v1.3.1：

```sh
$ cat go.mod
module github.com/you/hello

require (
	golang.org/x/text v0.3.0
	rsc.io/quote v1.5.2
	rsc.io/sampler v1.99.99
)
$ vgo get rsc.io/sampler@v1.3.1
vgo: finding rsc.io/sampler v1.3.1
vgo: downloading rsc.io/sampler v1.3.1
$ vgo list -m
MODULE                VERSION
github.com/you/hello  -
golang.org/x/text     v0.3.0
rsc.io/quote          v1.5.2
rsc.io/sampler        v1.3.1
$ cat go.mod
module github.com/you/hello

require (
	golang.org/x/text v0.3.0
	rsc.io/quote v1.5.2
	rsc.io/sampler v1.3.1
)
$ vgo test all
?   	github.com/you/hello	[no test files]
?   	golang.org/x/text/internal/gen	[no test files]
ok  	golang.org/x/text/internal/tag	(cached)
?   	golang.org/x/text/internal/testtext	[no test files]
ok  	golang.org/x/text/internal/ucd	(cached)
ok  	golang.org/x/text/language	(cached)
ok  	golang.org/x/text/unicode/cldr	(cached)
ok  	rsc.io/quote	0.016s
ok  	rsc.io/sampler	0.015s
$
```

降级某个模块可能会牵连降级与其相关的模块，例如：

```sh
$ vgo get rsc.io/sampler@v1.2.0
vgo: finding rsc.io/sampler v1.2.0
vgo: finding rsc.io/quote v1.5.1
vgo: finding rsc.io/quote v1.5.0
vgo: finding rsc.io/quote v1.4.0
vgo: finding rsc.io/sampler v1.0.0
vgo: downloading rsc.io/sampler v1.2.0
$ vgo list -m
MODULE                VERSION
github.com/you/hello  -
golang.org/x/text     v0.3.0
rsc.io/quote          v1.4.0
rsc.io/sampler        v1.2.0
$ cat go.mod
module github.com/you/hello

require (
	golang.org/x/text v0.3.0
	rsc.io/quote v1.4.0
	rsc.io/sampler v1.2.0
)
$
```

在这个例子中，`rsc.io/quote` v1.5.0 是第一个依赖了 `rsc.io/sampler` v1.3.0 的版本；`rsc.io/quote` 更早的版本只依赖 `rsc.io/sampler` v1.0.0（或在 v1.0.0 至 v1.3.0 之间的版本）。所以降级 `rsc.io/sampler` 时也会将 `rsc.io/quote` 降级到 v1.2.0。

也可将某个依赖模块完全移除，以 `none` 作为版本号即可：

```sh
$ vgo get rsc.io/sampler@none
vgo: downloading rsc.io/quote v1.4.0
vgo: finding rsc.io/quote v1.3.0
$ vgo list -m
MODULE                VERSION
github.com/you/hello  -
golang.org/x/text     v0.3.0
rsc.io/quote          v1.3.0
$ cat go.mod
module github.com/you/hello

require (
	golang.org/x/text v0.3.0
	rsc.io/quote v1.3.0
)
$ vgo test all
vgo: downloading rsc.io/quote v1.3.0
?   	github.com/you/hello	[no test files]
ok  	rsc.io/quote	0.014s
$
```

此时若想变回到所有依赖包都是最新版本，包含 `rsc.io/sampler` v1.99.99，则可：

```sh
$ vgo get -u
vgo: finding golang.org/x/text latest
vgo: finding rsc.io/quote latest
vgo: finding rsc.io/sampler latest
vgo: finding golang.org/x/text latest
$ vgo list -m
MODULE                VERSION
github.com/you/hello  -
golang.org/x/text     v0.3.0
rsc.io/quote          v1.5.2
rsc.io/sampler        v1.99.99
$
```

## 排除模块

既然已知 hello world 程序无法使用 `rsc.io/sampler` 的 v1.99.99 版本，那么我们应有能力将此版本记在小本本里，以免日后再次误用上这个版本。可以通过在 go.mod 文件中添加一行 exclude 指令来排除这个版本：

```sh
exclude rsc.io/sampler v1.99.99
```

添加 exclude 指令后，后面的各种 vgo 命令操作中，此模块版本就像消失了一样：

```sh
$ echo 'exclude rsc.io/sampler v1.99.99' >>go.mod
$ vgo list -t rsc.io/sampler
rsc.io/sampler
	v1.0.0
	v1.2.0
	v1.2.1
	v1.3.0
	v1.3.1
	v1.99.99 # excluded
$ vgo get -u
vgo: finding golang.org/x/text latest
vgo: finding rsc.io/quote latest
vgo: finding rsc.io/sampler latest
vgo: finding rsc.io/sampler latest
vgo: finding golang.org/x/text latest
$ vgo list -m
MODULE                VERSION
github.com/you/hello  -
golang.org/x/text     v0.3.0
rsc.io/quote          v1.5.2
rsc.io/sampler        v1.3.1
$ cat go.mod
module github.com/you/hello

require (
	golang.org/x/text v0.3.0
	rsc.io/quote v1.5.2
	rsc.io/sampler v1.3.1
)

exclude "rsc.io/sampler" v1.99.99
$ vgo test all
?   	github.com/you/hello	[no test files]
?   	golang.org/x/text/internal/gen	[no test files]
ok  	golang.org/x/text/internal/tag	(cached)
?   	golang.org/x/text/internal/testtext	[no test files]
ok  	golang.org/x/text/internal/ucd	(cached)
ok  	golang.org/x/text/language	(cached)
ok  	golang.org/x/text/unicode/cldr	(cached)
ok  	rsc.io/quote	(cached)
ok  	rsc.io/sampler	(cached)
$
```

当前模块的 exclude 指令只会对当前模块有效，若当前模块被更大的项目依赖时，则当前模块的 exclude 指令不会生效。例如，`rsc.io/quote` 中的 go.mod 里的 exclude 指令在我们的 hello world 构建中就不会生效。 这样设计的原因是控制权的平衡取舍：

- 让模块作者对自己的模块构建拥有近乎绝对的控制权利
- 依赖该模块的项目不应受其控制

此时，正确的做法是联系 `rsc.io/sampler` 的作者，告诉他 v1.99.99 版本的问题，然后作者修复后应发布为 v1.99.100。不过，`rsc.io/sampler` 是本文演示用的，所以为了保留 bug，所以这里故意不修复此 bug（译注：也即不再发布比 v1.99.99 更新的版本）。

## 替换模块

当你发现某个依赖包存在一些问题后，你可能需要一种方式来替换该依赖包为其他包。假设我们想修改 `rsc.io/quote` 模块中的某些功能。可能我们想定位 `rsc.io/sampler` 的那个 bug，又或者我们想做些其他事情。则第一步应先拿到 `qoute` 模块的代码，利用 git 的命令：

```sh
$ git clone https://github.com/rsc/quote ../quote
Cloning into '../quote'...
```

然后编辑 `../quote/quote.go`，修改 Hello 函数。例如，我想将此函数的返回值从 `sampler.Hello()` 改为 `sampler.Glass()`：

```sh
$ cd ../quote
$ <edit quote.go>
$
```

修改完毕后，为了在构建中用上这个修改后的 qoute，可添加一个 replace 指令到 go.mod 文件中：

```
replace rsc.io/quote v1.5.2 => ../quote
```

然后再次构建：

```sh
$ cd ../hello
$ echo 'replace rsc.io/quote v1.5.2 => ../quote' >>go.mod
$ vgo list -m
MODULE                VERSION
github.com/you/hello  -
golang.org/x/text     v0.3.0
rsc.io/quote          v1.5.2
 => ../quote
rsc.io/sampler        v1.3.1
$ vgo build
$ ./hello
I can eat glass and it doesn't hurt me.
$
```

你可将修改后的模块重命名为其他名字。例如，你可 fork https://github.com/rsc/quote ，然后 push 到你自己的 fork 后的仓库：

```sh
$ cd ../quote
$ git commit -a -m 'my fork'
[master 6151719] my fork
 1 file changed, 1 insertion(+), 1 deletion(-)
$ git tag v0.0.0-myfork
$ git push https://github.com/you/quote v0.0.0-myfork
To https://github.com/you/quote
 * [new tag]         v0.0.0-myfork -> v0.0.0-myfork
$
```

然后你就可以直接使用这个替代品了：

```sh
$ cd ../hello
$ echo 'replace rsc.io/quote v1.5.2 => github.com/you/quote v0.0.0-myfork' >>go.mod
$ vgo list -m
vgo: finding github.com/you/quote v0.0.0-myfork
MODULE                    VERSION
github.com/you/hello      -
golang.org/x/text         v0.3.0
rsc.io/quote              v1.5.2
 => github.com/you/quote  v0.0.0-myfork
rsc.io/sampler            v1.3.1
$ vgo build
vgo: downloading github.com/you/quote v0.0.0-myfork
$ LANG=fr ./hello
Je peux manger du verre, ça ne me fait pas mal.
$
```

## 向后兼容性

即使你想在项目中使用 vgo，但你可能不想强制你的用户都立即也用上 vgo。相反，你可创建一个 vendor 目录来让仍使用 go 命令的用户能尽可能复现与你一致的构建结果（他们在 GOPATH 中构建）：

```sh
$ vgo vendor
$ mkdir -p $GOPATH/src/github.com/you
$ cp -a . $GOPATH/src/github.com/you/hello
$ go build -o vhello github.com/you/hello
$ LANG=es ./vhello
Puedo comer vidrio, no me hace daño.
$
```

我之所以说是 `尽可能`，是因为工具链所感知、构建结果中的 import 路径已经不同了。基于 vendor 机制的构建可以感知 vendor 目录的存在：

```sh
$ go tool nm hello | grep sampler.hello
 1170908 B rsc.io/sampler.hello
$ go tool nm vhello | grep sampler.hello
 11718e8 B github.com/you/hello/vendor/rsc.io/sampler.hello
$
```

除了这些 import 路径不一致外，构建得到的二进制文件应该都是一样的。为提供一个平滑的过渡转换，基于 vgo 的构建会完全忽略 vendor 目录，日后集成了模块功能的 go 命令也会忽略 vendor 目录。

# 下一步？

现在就开始试用 vgo 吧：

- 在仓库中打上 tag，即可发布为版本
- 创建 go.mod 文件
- 若发现问题，请在 [golang.org/issue](https://golang.org/issue) 中发帖，且标题以 `x/vgo:` 开头

明天我将发出更多文章。感谢！希望大家能喜欢 vgo。
