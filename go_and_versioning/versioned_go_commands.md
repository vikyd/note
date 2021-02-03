# Versioned Go Commands

原文：https://research.swtch.com/vgo-cmd

作者：[Russ Cox](https://swtch.com/~rsc/)

翻译时间：2020-01-20

# Go 语言的版本管理命令

（[Go 与版本管理](https://research.swtch.com/vgo)，第 7 部分）

发表时间：2018-02-23 周五 [PDF](hhttps://research.swtch.com/vgo-cmd.pdf)

# 目录

<!--ts-->
<!--te-->

# 正文

为 go 命令添加模块版本管理功能意味着什么？这篇 [综述](https://github.com/vikyd/note/blob/master/go_and_versioning/go_add_package_versioning.md) 介绍了版本管理的整个框架，后面的文章是对每个点的细化介绍：[import 兼容性规则](https://github.com/vikyd/note/blob/master/go_and_versioning/semantic_import_versioning.md)、[最小版本选择](https://github.com/vikyd/note/blob/master/go_and_versioning/minimal_version_selection.md)、[定义 Go 语言的模块](https://github.com/vikyd/note/blob/master/go_and_versioning/defining_go_modules.md) 等。这些文章可有助于理解 Go 语言的版本管理机制，而本文则主要介绍版本管理对 go 命令的影响，及其原因。

以下是主要的变化：

- 所有命令（`go build`、`go run` 等）：若本地没下载过，则都会自动从网上下载 import 所指向的依赖包源码
- `go get` 命令：仅用于修改依赖包的版本（译注：如升级、降级、获取最新版本等）
- `go list` 命令：用于访问模块信息
- `go release` 命令（新）：在打 tag 发布版本时，自动帮助模块作者做一些工作，如检查 API 兼容性。
  - > 译注：截至 Go 1.13.6，依然 [未实现 `go release` 命令](https://github.com/golang/go/issues/26420)
- `all` 模式：被重新定义为与模块相关的一切（译注：而非之前的整个 GOPATH）
- 开发者应在 GOPATH 外存放自己的项目源码

所有这些变化，都已在 vgo 中实现。

让一个构建系统精确地工作是很难的。Go 1.10 引入了新的构建缓存，让 go 命令的含义发生变化，这些变化其实是一个重要且难以抉择的决定。这次，版本控制的引入也是一个类似的艰难决策。在解释这些决定之前，我想先介绍一些我最近发现的一个有用指导原则。我将其称为隔离原则：

> 一个构建的结果应只依赖于其输入，也即源码文件，且永远不能依赖上次构建命令遗留的隐式副作用。

> 也就是说，不管系统最近发生了什么事，一个命令应只做该做的事，且始终一致（每次都就像在一个只含相关输入源文件的干净系统中那样隔离）。

为了说明此原则的好处，我想先讲一个古老的构建故事，之后再解释隔离原则的具体作用。

# 一个古老的构建故事

很久很久以前，那时编译器和计算机都还很慢，开发者需要用脚本来重头构建整个程序。但有时开发者只修改了一个源文件，为节省编译时间，只重新编译被修改过的源文件，然后再连接整个程序（因全量重新编译很耗时）。这种手动增量构建的方式速度快，但易出错：若你忘记编译某个已修改的源文件，则连接时会依然使用旧 obj 文件，导致最终的可执行程序有 bug。最痛苦的是，你可能需要花很多时间检查那个已修改过的源码来定位 bug，而问题是那个源码文件其实已是正确的，出问题的只是编译过程。

[Stu Feldman 曾解释过](https://www.princeton.edu/~hos/mike/transcripts/feldman.htm)（译注：[Stuart Feldman](https://zh.wikipedia.org/wiki/%E6%96%AF%E5%9C%96%E4%BA%9E%E7%89%B9%C2%B7%E8%B2%BB%E7%88%BE%E5%BE%B7%E6%9B%BC) 是 [make](https://zh.wikipedia.org/wiki/Make) 的作者）上述情况与他当年的情况很像，他在 1970 年代曾耗费几个月时间调试只有几千行的 Ratfor（译注：[Rational Fortran](https://en.wikipedia.org/wiki/Ratfor) 的缩写） 程序解决类似问题：

> 我通常在下午六点左右回家吃晚饭。在下班前，我会在后台开始重新编译整个程序，等我开车回到家，并吃完晚饭，编译才基本结束。之所以有这个习惯，是因为教训，我曾因为忘记编译修改过的文件，一直调试一个本已正确源码，这是很典型的失误。

移植到现代 C 语言工具后（替代了 Ratfor），Feldman 在开始大型程序工作时，都会首先重头将其编译一次：

```sh
$ rm -f *.o && cc *.c && ld *.o
```

这种构建遵循了隔离原则：不管目录中曾运行过什么，只要是以相同的源文件作为输入，则会产生同样的结果。

但随后 Feldman 会对某些文件进行修改，并只重编译修改过的文件，以节省编译时间：

```sh
$ cc r2.c r3.c r5.c && ld *.o
```

这种增量式的构建就没有遵循隔离原则。编译结果的正确性依赖于 Feldman 能否记住曾修改过哪些文件，然鹅人总是易忘的。但由于只编译修改过的文件的速度比全量重新编译快得多，所以大家都喜欢这种方式，不得已时才会像 Feldman 那样每天 `吃晚饭时进行构建` 来纠正错误。

Feldman 还说：

> 然后有一天，[Steve Johnson](https://en.wikipedia.org/wiki/Stephen_C._Johnson) 以惯常的方式冲进我办公室，他大致是这样说的：“nnd，我居然又花了整个上午来调试一个没有错误的程序。你们没碰到这样的情况吗？...”

这就是 Stu Feldman 如何发明 `make` 这个工具的故事。

`make` 的一个主要进步是：提供快速的增量构建，且同时遵循隔离原则。隔离很重要，因为在隔离原则中，构建得到了适当的抽象：只受源码影响，不应受任何其他条件影响。作为一个开发者，你按需修改源码即可，而无需关心类似 obj 文件那样的中间细节。

但是，隔离原则也不是绝对的，它总会有一个区域，我将其称之为：抽象的区域。当你踏出此区域，你就会回到那种依赖于人工记忆的状态。对于 `make` 来说，其抽象区域对应的是一个目录。若需处理由多个目录的库组成的程序，则传统的 `make` 无能为力。1970 年代，大部分的 Unix 程序都只对应一个目录，所以 `make` 不提供支持多目录隔离构建的功能也无大碍。

# Go 语言的构建和隔离原则

在 go 命令设计上的 bug 修复历史，实质是不断迎合开发者的预期、扩展抽象区域的一系列步骤。

go 命令的其中一个进步是可正确处理分布在多个目录的源码，扩展了 `make` 没做到的区域。Go 的程序几乎总是分布在多个目录中，而使用 `make` 的时，在另一个目录使用某个软件包时，经常会忘了应预先安装该软件包。我们太熟悉 `调试正确程序的经典错误` 了。但是，即使修复了那样的问题，仍有很多方法会跳出 go 命令的抽象区域，导致意外的结果。

举一个例子，假设你的 GOPATH 中有多个目录的源码文件，若你在某个目录中进行构建，则会默认其他目录中的包（存在的话）已是最新的，若不存在则对其进行重新构建。若使用 godep，则会打破隔离原则，导致项目出现没完没了的诡异问题，因为 godep 使用了第 2 个 GOPATH 来模拟 vendor 目录。我们已在 Go 1.5 中修复了此问题。

另一个例子，即使直到最近，命令行的 flag 参数都不在隔离原则的抽象区域内。若你在标准的 Go 1.9 中运行下面命令：

```sh
$ go build hello.go
$ go install -a -gcflags=-N std
$ go build hello.go
```

第 2 个 `go build` 命令会得到与第 1 个 `go build` 不一样的结果。第 1 个 `hello` 会连接优化后的 Go 运行时和标准库，而第 2 个 `hello` 则会连接未优化的。由于这种参数设置违反了隔离原则，导致大家基本都用 `go build -a`（总是重新构建一切）来实现语义隔离。我们在 Go 1.10 中修复了这种问题。

上述两种情况中，go 命令都是 `按照设计工作`。这有点像使用其他构建系统时，要把这些细节记住脑子里，所以我们认为不将其抽象出来是合理的。实际上，当年我设计此行为时，也认为这是一个功能：

```sh
$ go install -a -gcflags=-N std
$ go build hello.go
```

上述命令可让你构建出一个，除标准库外其他包都会被优化的 `hello`，我自己有时也会这样用。但是，总的来说，Go 的开发者不同意，因为他们既不预计、也不想在脑子里记住那些细节。对于我来说，隔离原则很有用，因为它可以提供一个参考标准，帮我避开其他能力较弱的构建系统遗漏下来的精神污染：每个命令应只有一种含义，不管之前曾有过什么样的命令。

若要实现隔离原则，则有些命令可能需变得更复杂，相当于一个命令当两个命令使用。例如，若遵循隔离原则，你该如何构建出一个除标准库外其他包都会被优化的 `hello`？在 Go 1.10 中我们是这样回答：为 `-gcflags` 参数扩展出一个可选模式，用于控制哪些包该受影响。所以具体答案是：`go build -gcflags=std=-N hello.go`。

隔离原则还意味着，那些曾依赖上下文的命令，需增加与上下文无关的使用方式。好的通用规则应顺应开发者最熟悉方式：

```sh
$ go build -gcflags=-N hello.go
$ rm -rf $GOROOT/pkg
$ go build -gcflags=-N hello.go
```

在 Go 1.9 中，第 1 个 `go build` 命令会构建出一个含 `优化后的标准库` + `未优化的其他包` 的 `hello`。第 2 个 `go build` 命令会找到未优化过的标准库，所以它会重新构建整个标准库，并且 `-gcflags` 参数会在构建时对所有包生效，所以结果构建出一个含 `未优化的标准库` + `未优化的其他包` 的 `hello`。而在 Go 1.10 中，我们必须从上述两种含义中选一种作为该命令的真正含义。

我们最初的想法是，对于不包含 `std=` 模式的 `-gcflags=-N`，则此参数对构建中的所有包有效，也即构建得到的结果是：含 `未优化的标准库` + `未优化的其他包` 的 `hello`。但大部分开发者希望 `-gcflags=-N` 只表示对 `go build` 命令中出现的包或文件进行优化，其他的都不优化，因为当你删除的不只是 `$GOROOT/pkg` 时，大部分情况就是这么用的。我们决定按大部分开发者的预期来定义不含任何额外模式（译注：如 `std=` 就是一种模式）时的行为：该 flag 值仅影响 `go build` 命令中出现的包或文件。在 Go 1.10 中，若在构建 `hello.go` 时包含 `-gcflags=-N`，则永远得到这样的构建结果：含 `优化后的标准库` + `未优化的 hello 包` 的 `hello`。即使 `GOROOT/pkg` 已被删除，也会立即重新构建标准库。若你想得到一个完全不经优化的结果时，应这样：`-gcflags=all=-N`。

在向 go 命令添加版本管理功能时，隔离原则同样有助于理清楚各种设计上的疑惑。类似 flag 参数中的决策，其他的命令也需要变得更能干。所有曾经有多重含义的命令，现在都应被削减为只有 1 种含义。

# 自动下载依赖

隔离原则目前最重要的实现是：类似 `go build`、`go install`、`go test` 等命令会按需下载对应版本的依赖包（若未下载或缓存的话）。

假设我有一个新安装的 Go 1.10，并写了一个 hello.go：

```go
package main

import (
	"fmt"
	"rsc.io/quote"
)

func main() {
	fmt.Println(quote.Hello())
}
```

这样运行会失败：

```sh
$ go run hello.go
hello.go:5: import "rsc.io/quote": import not found
$
```

这样会成功：

```sh
$ go get rsc.io/quote
$ go run hello.go
Hello, world.
$
```

我来解释一下。经过 8 年时间对 `goinstall` 和 `go get` 的使用和调整，上述行为貌似没错：`go get` 负责下载 `rsc.io/quote`，并应在 `go run` 之前运行。但我也可解释前面小结中 flag 例子的优化行为。但直至几个月前，这些想法都似乎没什么问题。但后来我思考了一下，我还是认为 go 命令应按需自动下载所需的依赖包版本。我思想发生改变有以下几个原因。

原因 1，隔离原则。我在 go 命令中所犯的其他设计错误都违反了隔离原则，这一事实强烈表明
`go run` 前额外的 `go get` 也是一个错误设计。

原因 2，我发现自动下载依赖包到本地缓存很有帮助，开发者根本无需关心这些事。缓存丢失不应导致运行失败。

原因 3，应避免依赖人的记忆。目前的 go 命令需要开发者记住哪些包已下载或未下载，类似于之前的 go 命令需开发者记住最近安装包时用过哪些编译 flag。随着程序的增大，以及随着即将引入的版本管理功能，开发者需承受的记忆负担会越来越大，即使 go 命令已能跟踪同样的信息。例如，我认为以下方式对于开发者来说并不友好：

```sh
$ git clone https://github.com/rsc/hello
$ cd hello
$ go build
go: rsc.io/sampler(v1.3.1) not installed
$ go get
go: installing rsc.io/sampler(v1.3.1)
$ go build
$
```

既然 go 命令都已经知道还需哪些东西了，为什么还要用户去下载？

原因 4，已有其他构建系统做到这一点了。当你拿到一个基于 Rust 语言的项目源码并进行构建时，`cargo build` 命令会自动下载所需的依赖包，然后进行构建，无需用户做任何选择。

原因 5：自动下载依赖可允许按需延迟下载。对较大的程序，有些依赖根本无需下载。例如，著名的日志包 `github.com/sirupsen/logrus` 依赖了 `golang.org/x/sys`，但仅在 Solaris 系统上使用时才需要这个包。logrus 将某个版本的 `x/sys` 包记录到 go.mod 中作为依赖。当 vgo 在项目中看见 logrus 时，vgo 会寻找 go.mod，并根据所用到的 import 的版本（译注：[不同系统可能对应不同 import](https://stackoverflow.com/a/25162021/2752670)）决定是否使用 `x/sys`。但是，用户不在 Solaris 系统上构建时，则他们都不会用到 `x/sys`，所以完全无需下载 `x/sys`。在依赖图（dependency graph）变得越来越大时，这种优化越显重要。

我知道肯定会有开发者不希望在构建时自动下载依赖包。所以，我们可能会提供基于环境变量禁用自动下载行为的选择，但是，默认应总是自动下载。

# 修改模块版本（go get）

不带 `-u` 参数的普通 `go get` 命令违反了隔离原则，必须被修正。目前：

- 若 GOPATH 为空，`go get rsc.io/quote` 会下载并构建最新版本的 `rsc.io/quote` 及其依赖包（如 `rsc.io/sampler`）。
- 若 GOPATH 中存在 `rsc.io/quote`（之前的 `go get` 命令下载的），则再次运行 `go get` 命令时，会使用 GOPATH 中已存在的旧包。
- 若 GOPATH 中存在 `rsc.io/sampler`，但没有 `rsc.io/quote`，则 `go get` 会下载最新的 `rsc.io/quote`，但会基于 GOPATH 中的旧 `rsc.io/sampler` 进行构建。

综合来看，`go get` 依赖了 GOPATH 的状态，也即违反了隔离原则，我们需要解决此问题。由于目前的 `go get` 命令至少包含 3 层含义，因此我们在定义新行为时有一定的选择自由。目前，`vgo get` 命令会自动下载指定名称的最新版依赖模块，同时，对于依赖了该模块的其他模块都可能相应被更新，更新时遵循 [最小版本选择原则](https://github.com/vikyd/note/blob/master/go_and_versioning/minimal_version_selection.md)。例如，`vgo get rsc.io/quote` 总会下载最新版本的 `rsc.io/quote`，并根据下载到的 `rsc.io/quote` 所指定的 `rsc.io/sampler` 版本进行构建。

vgo 允许在命令行中指定模块版本：

```sh
$ vgo get rsc.io/quote@latest  # default
$ vgo get rsc.io/quote@v1.3.0
$ vgo get rsc.io/quote@'<v1.6' # finds v1.5.2
```

所有这些命令，都会根据不同版本 `rsc.io/quote` 中 go.mod，分别下载（缓存中不存的话）对应的 `rsc.io/sampler` 版本。这些命令都会修改当前模块的 go.mod 文件中的 `rsc.io/sampler` 为对应的版本，也即会影响后续其他命令的结果。但这种影响是是通过显式的文件表达出来的，而非隐式的缓存状态，用户本来就会经常查看、编辑 go.mod，所以没问题。注意，若 `vgo get` 命令中所请求的模块版本比 go.mod 中对应的版本低，则 vgo 会检测是否有依赖该模块的其他模块，若有则会根据 [最小版本选择原则](https://github.com/vikyd/note/blob/master/go_and_versioning/minimal_version_selection.md) 进行降级。

与普通的 `go get` 相反，`go get -u` 命令会无视 GOPATH 源码缓存的状态：它会下载指定模块的最新版本，及其对应的所有依赖模块。由于 `go get -u` 已遵循隔离原则，我们应保持同样的行为：`vgo get -u` 会升级指定模块的最新版本，及其对应的所有依赖模块。

最近几天冒出一个想法，引入一个介于 `vgo get`（只下载所指定的版本） 和 `vgo get -u`（总是下载最新的版本）之间的折中方式。若我们相信模块作者对 patch 级别（译注：例如可认为是 v1.2.3 中的 `3`）的版本发布很谨慎，并仅将 patch 级别版本用于重要的安全修复，则可以提供一个类似 `vgo get -p` 的命令，用于只更新 patch 级别的版本。例如，若 `rsc.io/quote` 依赖了 `rsc.io/sampler` v1.3.0，但此时 v1.3.1 和 v1.4.0 也已发布。则 `vgo get -p rsc.io/quote` 只会将 `rsc.io/sampler` 更新到 v1.3.1 而非 v1.4.0。如果你觉得这个命令有用，请告诉我们。

当然，所有的 `vgo get` 命令都会将依赖模块的增、删、改写到 go.mod 文件中。从某种意义上讲，我们通过显式引入 go.mod 文件替代之前的隐式状态（依赖整个 GOPATH 的状态），让这些命令遵循了隔离原则。

# 模块信息（go list）

在修改正在使用的模块版本为其他版本之前，我们需要提供获取当前使用版本信息的方式。`go list` 命令本身已经能输出一些有用信息：

```sh
$ go list -f {{.Dir}} rsc.io/quote
/Users/rsc/src/rsc.io/quote
$ go list -f {{context.ReleaseTags}}
[go1.1 go1.2 go1.3 go1.4 go1.5 go1.6 go1.7 go1.8 go1.9 go1.10]
$
```

对于模块信息，也应可按类似的模板输出，并且我们应提供一些常用操作的简短命令，如：列出当前模块的所有依赖等。vgo 原型已能提供依赖模块中的包的正确信息。例如：

```sh
$ vgo list -f {{.Dir}} rsc.io/quote
/Users/rsc/src/v/rsc.io/quote@v1.5.2
$
```

还有一些简短版的命令。

首先，`vgo list -t` 可列出一个模块的所有可用 tag 版本：

```sh
$ vgo list -t rsc.io/quote
rsc.io/quote
	v1.0.0
	v1.1.0
	v1.2.0
	v1.2.1
	v1.3.0
	v1.4.0
	v1.5.0
	v1.5.1
	v1.5.2
$
```

其次，`vgo list -m` 可列出当前模块名，及其依赖模块：

```sh
$ vgo list -m
MODULE                VERSION
github.com/you/hello  -
golang.org/x/text     v0.0.0-20170915032832-14c0d48ead0c
rsc.io/quote          v1.5.2
rsc.io/sampler        v1.3.0
$
```

最后，`vgo list -m -u` 可增加一列显示每个模块的最新版本：

```sh
$ vgo list -m -u
MODULE                VERSION                             LATEST
github.com/you/hello  -                                   -
golang.org/x/text     v0.0.0-20170915032832-14c0d48ead0c  v0.0.0-20180208041248-4e4a3210bb54
rsc.io/quote          v1.5.2 (2018-02-14 10:44)           -
rsc.io/sampler        v1.3.0 (2018-02-13 14:05)           v1.99.99 (2018-02-13 17:20)
$
```

从长远来看，这些简短版命令的输出信息应更通用，其他程序才能以其他形式获取。目前，这些输出只是特殊情况。

# 准备新的模块版本（go release）

我们希望鼓励作者用以 tag 方式发布他们的模块版本，所以我们应将发布动作设计得更简单。我们想添加一个新的命令 `go release` 来处理所有依赖人记忆的工作。例如，可能是：

- 对比之前的版本，根据类型变化检查其向后兼容性。我们在开发 Go 标准库时就会这么检查，很有用。
- 推荐二选一：发布为 patch 版本，或是发布为次要版本（minor release）（可能是因为引入了新 API，或改了很多行代码）。也可只推荐发布为次要版本，除非作者主动要求发布为 patch 版本，此时 `go get -p` 才有用。
- 扫描模块中的所有源码，包括那些非正常构建的源码（译注：如你在 win 开发 go 时，也可能有些只适用于 linux 的源码），以保证 go.mod 中的需求能满足所有 import 使用。回忆之前下载一节中的例子，这种检查可确保 logrus 的 go.mod 中包含 `x/sys`。

若后面发现更多关于发布版本的最佳实践，我们会将其添加到 `go release` 中，作者就可只需一个步骤，即能检查他们的模块是否已可发布。

# 模式匹配

大部分的 go 命令支持指定一些包名作为参数，并可使用一些模式，如：

- `rsc.io/...`：指所以以 `rsc.io` 作为 import 路径前缀的包
- `./...`：指当前目录及子目录的所有包
- `all`：指所有包

在新的模块机制中，我们需要让这些模式也符合需求。

最初，这些模式不会对 vendor 目录特殊处理，所以若已存在 `github.com/you/hello/vendor/rsc.io/quote`，则 `go test github.com/you/hello/...` 会匹配到它，并对其测试。在 hello 源码根目录使用 `go test ./...` 时同理。

赞同者的观点是：将 vendor 目录与项目源码同等对待，可避免特殊处理，而且既对项目代码进行测试，也对依赖包的代码进行测试，实际会很有用。

反对者的观点是：开发者只关心他们的项目代码，认为依赖包的代码没有变化，且在使用前应已被另外测试过。

在 Go 1.9，我们已将 `...` 改为不匹配 vendor 目录，所以 `go test github.com/you/hello/...` 不会测试 vendor 中的依赖包。vgo 延续这种设定，即不匹配 vendor 目录，因为 vendor 目录机制将被废弃。也即是说，vgo 没有修改 `...` 的含义，因为其含义早已在 Go 1.8 升级到 Go 1.9 时修改了。

再来看看 `all` 模式。当年我们刚开始开发 go 命令，那时还没有 `goinstall` 和 `go get`，当时很经常需要构建或测试 `所有包`。而今，`所有包` 的概念不太重要了：大部分开发者在 GOPATH 中工作，并会使用很多别人的包，包括很多下载的包、忘记干什么用的包。我认为现在几乎没人这样用 `go install all` 或 `go test all`：匹配了太多不相关的包。问题的根源在于 `go test all` 违反了隔离原则：它依赖了之前的命令所产生的 GOPATH 隐式状态，所以也就没人再去这么做了。vgo 原型中，我们已将 `all` 重新定义为单一且一致的含义：指当前模块的所有包，以及代码中 import 所依赖的包。

`all` 的新含义代表了开发者的需求：只精确测试指定包的内容及其依赖，以检查某些依赖包组合一起时能否正常工作，并完全不管模块中的其他包。例如，在这篇 [概述](https://research.swtch.com/vgo1) 文章中，我们的 hello 程序只 import 了 `rsc.io/quote`，没有 import 任何其他包，也没有 import 有 bug 的包 `rsc.io/quote/buggy`。在 hello 模块中执行 `go test all`，既会测试模块中的所有包，也会测试 `rsc.io/quote`。但不会测试 `rsc.io/quote/buggy`，因为模块并未用到此包，甚至间接用到也不会测试，因为不相关。这样的 `all` 才恢复了可复现性，并在 Go 1.10 中可与测试缓存结合，`go test all` 终于再次变得有用了。

# 别再把项目代码放 GOPATH 里

若相同 import 路径的包有不同的版本，则没必要将这些不同版本的包塞到同一个目录中。如果我需同时对 v1.3 和 v1.4 进行修复 bug，该怎么办？很明显，只有把不同版本放到不同目录才行。实际上，这种情况完全不能在 GOPATH 中进行（译注：因为 GOPATH 不区分包的版本）。

GOPATH 做了 3 件事：

- 定义了依赖的版本（现在由 go.mod 干这事）
- 存放了这些依赖的源码（现在将存放到独立的缓存中）
- 提供了一种推导出目录的 import 路径的方法（现在移除了目录前缀 `$GOPATH/src`）

只要能找到一种推导当前目录的 import 路径的机制，我们就可以让开发者摆脱 GOPATH。此机制就是 go.mod 文件中的 `module` 指令。例如，假设我有一个名为 buggy 的目录，其上级目录中的 go.mod 文件包含以下内容：

```
module "rsc.io/quote"
```

则 buggy 目录的 import 路径必须是：`rsc.io/quote/buggy`。

正如这篇 [综述文章](https://github.com/vikyd/note/blob/master/go_and_versioning/go_add_package_versioning.md) 所介绍的，现在的 vgo 原型允许把项目代码放在 GOPATH 之外。实际上，在从 go.mod 获取依赖包信息时，vgo 也会从当前目录或子目录的 import 注释中获取相关信息（译注：[参考](https://golang.org/cmd/go/#hdr-Import_path_checking)）。例如，下面例子可让 upspin 包能在不引入 go.mod 文件时正常工作：

```sh
$ cd $HOME
$ git clone https://github.com/upspin/upspin
$ cd upspin
$ vgo test -short ./...
```

vgo 命令会从 import 注释中推导出：此模块名为 `upspin.io`，并且会从 Gopkg.lock 文件中推导出：所需的依赖版本。

# 下一步？

本文是我关于 vgo 设计和原型的初版系列文章的最后一篇。还有很多想说的，但这些文章合计已达 67 页，应足够大家看一周了。

我原计划在今天发表一篇 FAQ，在周一提交 Go 提案，但下周一之后我会离开一段时间。为了避免在正式讨论提案的最初 4 天我不在，所以想了下还是等我回来后再提交 Go 提案。请继续在邮件列表或本系列文章中发表评论、提出你的问题，并体验下 vgo 原型。

感谢一直以来你们感兴趣并提供反馈。对于我来说，大家共同协作很重要，能让开发者更易于迁移到新的模块版本管理机制。

**更新**：2018 年 03 月 20 号：正式的 Go 提案已发出：https://golang.org/issue/24301 ，并且里面的第 2 个评论就是 FAQ。
