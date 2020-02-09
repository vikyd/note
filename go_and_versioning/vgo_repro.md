# Reproducible, Verifiable, Verified Builds
原文：https://research.swtch.com/vgo-repro

作者：[Russ Cox](https://swtch.com/~rsc/)

翻译时间：2019-11-17

# 可复现、可验证、可证明的构建
（[Go 与版本](https://research.swtch.com/vgo)，第 5 部分）

发表时间：2018-02-21 周三 [PDF](https://research.swtch.com/vgo-repro.pdf)


# 正文
Go 开发者们和相关工具若使用统一的包版本描述方式，就可简化工具链中添加对可复现、可验证、可证明的构建支持。实际上，vgo 原型已包含这些基础要点。

为了避免歧义，我们在本文约定以下含义：

- 可复现的构建（reproducible build）：是指重复操作时，可产生一致的构建结果
- 可验证的构建（verifiable build）：是指记录了足够的信息来精确进行重复的构建
- 可证明的构建（verified build）：是只可检查构建时是否使用了预期中的源码

Vgo 默认具有可复现构建结果的能力。构建得到的二进制文件是可验证的，因为 Vgo 在二进制文件中记录了构建时所使用的精确源码版本。也可以配置这样一个验证仓库，当用户重新构建你的源码时，他们可通过此仓库验证他们的构建是否与你的一致。无论从何处获取到这些依赖，都可以使用密码学上的哈希值来进行验证。


# 可复现的构建
不管怎样，我们至少希望当你构建我的源码时，构建系统能使用完全一致的代码来构建。[最小版本选择（Minimal version selection）](https://research.swtch.com/vgo-mvs) 机制默认具有这种能力。只需 `go.mod` 文件就已足够唯一描述构建所使用的依赖模块版本，并且即使依赖模块出现新的版本时，也能保持稳定的构建。这就与大部分其他包管理器不一样了，因为它们通常会自动使用新版本的依赖包，需要一些额外的限制才能维持可复现的构建。我在另一篇名为 `最小版本选择` 的文章中详细介绍了这个方面，但本文不会细说，只提一些简短的要点。

具体来说，我们可以从现有的包管理工具开始，譬如 Rust 语言的 Cargo。我认为 Cargo 算是目前众多包管理工具里最具代表性的例子了，里面有很多值得借鉴的地方。如果我们能为 Go 做出一个类似 Cargo 那么好用的包管理工具，那也算不错了。但我想知道的是，对于版本选择，不同的默认值是否还会有更好的效果。

Cargo 喜欢使用最大版本，下面将具体介绍。我写本文时，crates.io 上 [toml](https://crates.io/crates/toml) 的最新版本是 0.4.5。它依赖 [serde](https://crates.io/crates/serde)，版本为 1.0 或更新。如果你新建一个项目并添加了 `toml` 0.4.1 或更新版本作为依赖。这时摆在 Cargo 面前有几种选择。根据 Cargo 的限制，0.4.1、0.4.2、0.4.3、0.4.4、0.4.5 都可以作为项目的真正依赖。在 Cargo 看来，这几个版本都是同等的意思，并会选择 [最新的适合版本](https://research.swtch.com/cargo-newest.html)，也即 0.4.5。同样的，`serde` 的 1.0.0 至 1.0.27 均是可接受的版本，Cargo 依然会选择 1.0.27。若后面还有更新的依赖版本，则 Cargo 会继续选择更新的版本。如果今晚 `serde` 发布了新版 1.0.28，并且第二天我将 `toml` 0.4.5 添加到项目中，我得到的将会是 1.0.28 而非 1.0.27。讲到这里，Cargo 的所有构建都是不可重现的。对此 Cargo 的应对办法（完全合理）是在主清单文件 `Cargo.toml` 之外再增加一个新文件 `Cargo.lock`，用于记录依赖包的精确版本。这个 lock 文件以后都不会再更新，一旦此文件被写入，你的构建将一直停留在 `serde` 1.0.27，即使 1.0.28 发布了也不会改变。

相反，最小版本选择喜欢最小的允许版本，也即项目中 `go.mod` 文件里所指定的精确版本。在此情况下，即使依赖包发布了新版本也不会改变。假设 vgo 也面临前面与 Cargo 例子中同样的选项时，vgo 会选择 `toml` 0.4.1（你的项目所依赖的）和 `serde` 1.0（`toml` 所依赖的）。这些选择都是稳定的，而且无需 lock 文件。这就是我所说的：vgo 的构建默认是可重现的。



# 可验证的构建
Go 语言构建的二进制文件一直都包含着一个字符串，这个字符串就是构建时所使用的 Go 版本。去年，我写了一个工具 `rsc.io/goversion`，用于从指定可执行文件或文件树中找出所包含 Go 的版本信息。譬如，在我的 Ubuntu Linux 笔记本上，我可执行下面命令来查找本机系统工具哪些是基于 Go 开发的：

```sh
$ go get -u rsc.io/goversion
$ goversion /usr/bin
/usr/bin/containerd go1.8.3
/usr/bin/containerd-shim go1.8.3
/usr/bin/ctr go1.8.3
/usr/bin/go go1.8.3
/usr/bin/gofmt go1.8.3
/usr/bin/kbfsfuse go1.8.3
/usr/bin/kbnm go1.8.3
/usr/bin/keybase go1.8.3
/usr/bin/snap go1.8.3
/usr/bin/snapctl go1.8.3
$ 
```

现在的 vgo 原型已经能理解模块的版本了，它将版本信息放进了最终的二进制文件中。新命令 `goversion -m` 可以将这些信息打印出来。这里有一个现成的 `hello, world` 程序 [例子](https://research.swtch.com/vgo-tour)：

```sh
$ go get -u rsc.io/goversion
$ goversion ./hello
./hello go1.10
$ goversion -m hello
./hello go1.10
	path  github.com/you/hello
	mod   github.com/you/hello  (devel)
	dep   golang.org/x/text     v0.0.0-20170915032832-14c0d48ead0c
	dep   rsc.io/quote          v1.5.2
	dep   rsc.io/sampler        v1.3.0
$ 
```

主模块（如 `github.com/you/hello`）没有版本信息，是因为这只是一份本地的副本，而不是我们下载的某个版本。一旦我们从一个有版本的模块进行构建，就可以看到其中包含所有的模块版本信息：

```sh
$ vgo build -o hello2 rsc.io/hello
vgo: resolving import "rsc.io/hello"
vgo: finding rsc.io/hello (latest)
vgo: adding rsc.io/hello v1.0.0
vgo: finding rsc.io/hello v1.0.0
vgo: finding rsc.io/quote v1.5.1
vgo: downloading rsc.io/hello v1.0.0
$ goversion -m ./hello2
./hello2 go1.10
	path  rsc.io/hello
	mod   rsc.io/hello       v1.0.0
	dep   golang.org/x/text  v0.0.0-20170915032832-14c0d48ead0c
	dep   rsc.io/quote       v1.5.2
	dep   rsc.io/sampler     v1.3.0
$ 
```

当我们将版本整合到 Go 的主工具链中时，我们将提供在运行过程中可访问二进制文件中版本模块信息的 API。如 [runtime.Version](https://golang.org/pkg/runtime/#Version) 接口提供了获取 Go 语言版本之外的模块版本信息的功能。

为了达到二进制文件的可复现性的目的，`goversion -m` 中列出的信息已经足够了：将其中的版本信息放到 `go.mod` 文件中，并利用 `path` 所在行的名字构建出目标文件。但如果构建得到的二进制文件不一致，你该如何发现到底是哪个地方导致不一致？

当 vgo 下载每个模块时，它会计算模块文件树所对应的哈希值。二进制文件中同样整合了此哈希值，就放在版本信息的旁边。`goversion -mh` 可打印出以下信息：

```sh
$ goversion -mh ./hello
hello go1.10
	path  github.com/you/hello
	mod   github.com/you/hello  (devel)
	dep   golang.org/x/text     v0.0.0-20170915032832-14c0d48ead0c  h1:qgOY6WgZOaTkIIMiVjBQcw93ERBE4m30iBm00nkL0i8=
	dep   rsc.io/quote          v1.5.2                              h1:w5fcysjrx7yqtD/aO+QwRjYZOKnaM9Uh2b40tElTs3Y=
	dep   rsc.io/sampler        v1.3.1                              h1:F0c3J2nQCdk9ODsNhU3sElnvPIxM/xV1c/qZuAeZmac=
$ goversion -mh ./hello2
hello go1.10
	path  rsc.io/hello
	mod   rsc.io/hello       v1.0.0                              h1:CDmhdOARcor1WuRUvmE46PK91ahrSoEJqiCbf7FA56U=
	dep   golang.org/x/text  v0.0.0-20170915032832-14c0d48ead0c  h1:qgOY6WgZOaTkIIMiVjBQcw93ERBE4m30iBm00nkL0i8=
	dep   rsc.io/quote       v1.5.2                              h1:w5fcysjrx7yqtD/aO+QwRjYZOKnaM9Uh2b40tElTs3Y=
	dep   rsc.io/sampler     v1.3.0                              h1:7uVkIFmeBqHfdjD+gZwtXXI+RODJ2Wc4O7MPEh/QiW4=
$ 
```

`h1`：这个前缀表示哈希值所用的算法。目前来说，只用到了 `hash 1`，也即代表 SHA-256。这里的哈希值表示模块文件树每个文件分别计算出 SHA-256 值后的综合哈希值（译注：可参考 [这个计算工具](https://github.com/vikyd/go-checksum)）。如果我们将此哈希值修改一下，此前缀所代表的算法可帮我们分辨出新、旧哈希值。

但必须指出的是，这些哈希值都是构建系统自己得出的。如果有人想给你发送了一个包含一些哈希值的二进制文件，你无法确保这些哈希值是可信的。这时就需要更进一步的验证了，而非盲信对方的信息。



# 可证明的构建
一个作者以源代码形式发布一个程序，其目的是想告诉用户他们所构建的程序都是基于想要的依赖包的精确版本。我们知道 vgo 会使用一致的依赖包版本来构建，但依然存在一个问题，譬如 v1.5.2 对应的文件树是否就真的是那些文件。如果作者突然将 v1.5.2 这个版本号指向了另一个不同的文件的话，该怎么办？又或者受到中间人攻击时，下载的信息被解译了，并被替换成一些恶意文件，又该怎么办？又或者用户突然修改了本地的 v1.5.2 模块源文件，又该怎么办？vgo 的原型也支持这些问题的验证。

最终可能不是下面描述的形式。如果你在 `go.mod` 的旁边创建一个新的文件 `go.modverify`，并在其中持续保持下载过的模块版本对应的哈希值：

```sh
$ echo >go.modverify
$ vgo build
$ tcat go.modverify  # go get rsc.io/tcat, or use cat
golang.org/x/text  v0.0.0-20170915032832-14c0d48ead0c  h1:qgOY6WgZOaTkIIMiVjBQcw93ERBE4m30iBm00nkL0i8=
rsc.io/quote       v1.5.2                              h1:w5fcysjrx7yqtD/aO+QwRjYZOKnaM9Uh2b40tElTs3Y=
rsc.io/sampler     v1.3.0                              h1:7uVkIFmeBqHfdjD+gZwtXXI+RODJ2Wc4O7MPEh/QiW4=
$ 
```

`go.modverify` 文件中保存了所有曾经下载过的模块版本的哈希值：每行都只添加，永不删除。如果我们更新 `rsc.io/sampler` 到 v1.3.1，则此文件会同时包含两个版本的哈希值：

```sh
$ vgo get rsc.io/sampler@v1.3.1
$ tcat go.modverify
golang.org/x/text  v0.0.0-20170915032832-14c0d48ead0c  h1:qgOY6WgZOaTkIIMiVjBQcw93ERBE4m30iBm00nkL0i8=
rsc.io/quote       v1.5.2                              h1:w5fcysjrx7yqtD/aO+QwRjYZOKnaM9Uh2b40tElTs3Y=
rsc.io/sampler     v1.3.0                              h1:7uVkIFmeBqHfdjD+gZwtXXI+RODJ2Wc4O7MPEh/QiW4=
rsc.io/sampler     v1.3.1                              h1:F0c3J2nQCdk9ODsNhU3sElnvPIxM/xV1c/qZuAeZmac=
$ 
```

当 `go.modverify` 文件存在时，vgo 会检查下载到的所有依赖包，与 `go.modverify` 文件中对应模块版本的哈希值进行对比。例如，如果我们将 `rsc.io/quote` 的哈希值前面的 `w` 修改为 `v`，则：

```sh
$ vgo build
vgo: verifying rsc.io/quote v1.5.2: module hash mismatch
	downloaded:   h1:w5fcysjrx7yqtD/aO+QwRjYZOKnaM9Uh2b40tElTs3Y=
	go.modverify: h1:v5fcysjrx7yqtD/aO+QwRjYZOKnaM9Uh2b40tElTs3Y=
$ 
```

或者，我们不修改上述哈希值，转而修改 `go.modverify` 中 v1.3.0 对应的哈希值。此时，再次构建应能成功，因为构建没有用到 v1.3.0，所以该行被（正确地）忽略了。但如果我们降级到 v1.3.0，则再次验证构建结果是将会提示失败：

```sh
$ vgo build
$ vgo get rsc.io/sampler@v1.3.0
vgo: verifying rsc.io/sampler v1.3.0: module hash mismatch
	downloaded:   h1:7uVkIFmeBqHfdjD+gZwtXXI+RODJ2Wc4O7MPEh/QiW4=
	go.modverify: h1:8uVkIFmeBqHfdjD+gZwtXXI+RODJ2Wc4O7MPEh/QiW4=
$ 
```

开发者若想保证他们的程序每次构建都能用到精确一致的依赖源码，可以在仓库中保存 `go.modverify` 文件。之后，其他人使用同一个仓库进行构建时，就能根据 `go.modverify` 文件对依赖的模块源码进行验证了。到此为止，我们依然只说了 `go.modverify` 会验证顶层的直接依赖。不过好在，`go.modverify` 还会保存所有间接的依赖模块哈希值，所以整个构建所依赖的模块都是可验证的。

`go.modverify` 机制可帮助我们检测不同机器之间的相同依赖源码是否一致。它会在下载完源码后计算其哈希值并进行对比。此机制还可用于检测本地依赖包的源码是否被修改过。但此机制更多是关心源码本身是否被修改过，却很少关心如何应对安全攻击。例如，由于源文件的路径是会出现在堆栈信息中，所以很常见的操作是在调试时直接查看源文件。如果你在调试时突然有意地修改了源文件，此机制应能在之后检查到文件发生了变化。`vgo verify` 命令可做到这一点：

```sh
$ go get -u golang.org/x/vgo  # fixed a bug, sorry! :-)
$ vgo verify
all modules verified
$ 
```

如果一个源文件被修改过，`vgo verify` 会提示：

```sh
$ echo >>$GOPATH/src/v/rsc.io/quote@v1.5.2/quote.go
$ vgo verify
rsc.io/quote v1.5.2: dir has been modified (/Users/rsc/src/v/rsc.io/quote@v1.5.2)
$ 
```

如果将被修改的文件恢复原状，就不会出现提示了：

```sh
$ gofmt -w $GOPATH/src/v/rsc.io/quote@v1.5.2/quote.go
$ vgo verify
all modules verified
$ 
```

如果缓存的 zip 文件在下载后被修改过，`vgo verify` 命令也会发出提示（其中细节可暂不用管）：

```sh
$ zip $GOPATH/src/v/cache/rsc.io/quote/@v/v1.5.2.zip /etc/resolv.conf
  adding: etc/resolv.conf (deflated 36%)
$ vgo verify
rsc.io/quote v1.5.2: zip has been modified (/Users/rsc/src/v/cache/rsc.io/quote/@v/v1.5.2.zip)
$ 
```

因为 vgo 会在解压后保留原始的 zip 文件，所以如果 `vgo verify` 发现其中的 zip 文件与目录树的不一致，就会打印出其中不一致的地方。



# 下一步
上述这些都已在 vgo 中实现了，你现在就可以尝试使用一下。vgo 接下来将持续接受用户的使用反馈进行改进。

本文中展示的功能只是一个开始，还远不是最终的样子。文件树的哈希值是此机制的基石。`go.modverify` 基于此来校验开发者所使用的依赖包是否一致。但此机制目前无法在新增（除非用户手动在 `go.modverify` 中添加哈希值）一个依赖包或更新依赖包到新版本时进行验证，因为此时本地没有可对比的哈希值。

如何解决上述两个问题，目前并无明确的方式。或许可以，对文件树进行某种形式的签名计算，并在更新版本时检查该签名是否与旧版本的一致。或许可以，采用 [The Update Framework (TUF)](https://theupdateframework.github.io/) 那样的机制，虽然直接使用他们的网络协议并不实际。或许可以，使用预先存储的 `go.modverify`，可以基于类似 [透明日志（Certificate Transparency）](https://www.certificate-transparency.org/) 的服务来存储这些全球共享的哈希值，或使用像 [Upspin](https://upspin.io/) 的公共身份服务器。还有很多可探索的方法，但是目前还远不能确定下来。目前，我们将首先专注于将版本控制功能成功整合到 go 命令中。
