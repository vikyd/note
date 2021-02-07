# 译：Proposal：Secure the Public Go Module Ecosystem

原文：https://go.googlesource.com/proposal/+/master/design/25530-sumdb.md

# 提案：为 Go 语言的公共模块生态建立安全机制

作者：

- [Russ Cox](https://swtch.com/~rsc/)
- [Filippo Valsorda](https://filippo.io/)

最近更新：2019 年 4 月 24 日

golang.org/design/25530-sumdb

参与讨论：golang.org/issue/25530.

# 目录

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [译前名词解释](#%E8%AF%91%E5%89%8D%E5%90%8D%E8%AF%8D%E8%A7%A3%E9%87%8A)
- [摘要](#%E6%91%98%E8%A6%81)
- [背景](#%E8%83%8C%E6%99%AF)
  - [基于 `go.sum` 进行模块验证](#%E5%9F%BA%E4%BA%8E-gosum-%E8%BF%9B%E8%A1%8C%E6%A8%A1%E5%9D%97%E9%AA%8C%E8%AF%81)
  - [透明日志](#%E9%80%8F%E6%98%8E%E6%97%A5%E5%BF%97)
- [提议](#%E6%8F%90%E8%AE%AE)
  - [校验数据库（Checksum Database）](#%E6%A0%A1%E9%AA%8C%E6%95%B0%E6%8D%AE%E5%BA%93checksum-database)
  - [代理一个校验数据库](#%E4%BB%A3%E7%90%86%E4%B8%80%E4%B8%AA%E6%A0%A1%E9%AA%8C%E6%95%B0%E6%8D%AE%E5%BA%93)
  - [`go` 命令客户端](#go-%E5%91%BD%E4%BB%A4%E5%AE%A2%E6%88%B7%E7%AB%AF)
- [根本原因](#%E6%A0%B9%E6%9C%AC%E5%8E%9F%E5%9B%A0)
  - [安全](#%E5%AE%89%E5%85%A8)
  - [隐私](#%E9%9A%90%E7%A7%81)
    - [私有模块的路径](#%E7%A7%81%E6%9C%89%E6%A8%A1%E5%9D%97%E7%9A%84%E8%B7%AF%E5%BE%84)
    - [私有模块的 SHA256](#%E7%A7%81%E6%9C%89%E6%A8%A1%E5%9D%97%E7%9A%84-sha256)
    - [公共模块的使用数据](#%E5%85%AC%E5%85%B1%E6%A8%A1%E5%9D%97%E7%9A%84%E4%BD%BF%E7%94%A8%E6%95%B0%E6%8D%AE)
    - [通过代理保护隐私](#%E9%80%9A%E8%BF%87%E4%BB%A3%E7%90%86%E4%BF%9D%E6%8A%A4%E9%9A%90%E7%A7%81)
    - [通过批量下载保护隐私](#%E9%80%9A%E8%BF%87%E6%89%B9%E9%87%8F%E4%B8%8B%E8%BD%BD%E4%BF%9D%E6%8A%A4%E9%9A%90%E7%A7%81)
    - [在持续集成、持续开发（CI/CD）中的隐私](#%E5%9C%A8%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E6%8C%81%E7%BB%AD%E5%BC%80%E5%8F%91cicd%E4%B8%AD%E7%9A%84%E9%9A%90%E7%A7%81)
- [兼容性](#%E5%85%BC%E5%AE%B9%E6%80%A7)
- [实现](#%E5%AE%9E%E7%8E%B0)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 译前名词解释

- checksum database：译作校验数据库
- Golang 或 Go：本文统一称为 Go
- module：译作模块

此外，建议先看 [此文](https://github.com/vikyd/note/blob/master/translate-transparent_logs_for_skeptical_clients.md) 和 [此文](https://github.com/vikyd/note/blob/master/our_software_dependency_problem.md)。然后再看本文，否则本文可能会有很多莫名其妙的概念。

# 摘要

我们提出引入一个新的服务来为 Go 的模块生态提供安全保障。这个服务就是 Go 的 checksum database（校验数据库），它实质是一个包含了所有公开 Go 模块的 `go.sum` 文件。`go` 命令可使用此服务来填充本地的 `go.sum`，譬如 `go get -u`。此方法用于保证初次引入或更新依赖时，依赖包中的代码不会被异常修改。

Go 的校验数据库（checksum database）原起名叫 `the Go notary`（Go 的公证人），但我们后来改名了，避免与 Apple Notary 或基于 Go 写成的 CNCF Notary 项目搞混。

# 背景

当你运行 `go` `get` `rsc.io/quote@v1.5.2` 时， `go get` 会首先下载 `https://rsc.io/quote?go-get=1` 中的信息，并从中找到类似下面的 `<meta>` 标签：

```html
<meta
  name="go-import"
  content="rsc.io/quote git https://github.com/rsc/quote"
/>
```

从上面可知，代码来自 `github.com`。下一步会执行 `git clone https://github.com/rsc/quote` 从 Git 仓库拉取代码，并提取 `v1.5.2` tag 中的文件树，最终得到真正的模块内容。

曾经 `go get` 总认为它下载到的都是正确代码。但若攻击者能拦截到 `rsc.io` 或 `github.com` 的连接（或能入侵其中的系统，或入侵某个模块的作者），则 `go get` 很难注意到明天下载到的代码是否还一致。

[如何安全地使用软件依赖（dependency）存在很多挑战](https://github.com/vikyd/note/blob/master/our_software_dependency_problem.md)，我们本该在使用一个新依赖前对其进行更多检查。但对于同一个模块版本，我们今天下载到的代码与明天下载到的不一致，则一切安全检查都是无意义的。所以，我们应先验证 `下载` 的正确性。

为了到达安全下载的目的，我们将 `一个特定模块版本的下载正确性` 定义为：所有人都能下载到相同的代码。此定义可保证构建的可重现性，也使得接下来对模块的更多检查真正有意义。同时避免对应模块作者去对代码进行归档，也避免引入新的风险点（如每个作者都拥有密钥）。而且即使是模块作者自己，任何时候也不应去修改已发布版本号的代码。

为了验证特定模块版本的 `下载正确性`，我们提出将代码托管网站（如 rsc.io、github.com）从 Go 模块生态信任计算的基础中解耦出来。有了模块验证后，那些网站（译注：如 `rsc.io`、`github.com` 等）将不再可能偷偷修改指定版本的代码，顶多不再提供某些模块版本而已。Go 模块代理的介绍文档（可见于 `go help proxy`）中提到了另一种拦截模块下载的攻击方法；模块验证也可使得无需关心这些代理是否可信，详情可见于 [信任计算的基础（trusted computing base）](https://www.microsoft.com/en-us/research/publication/authentication-in-distributed-systems-theory-and-practice/)。

更多背景信息，可见于 Go 的博客文章 [Go Modules in 2019](https://blog.golang.org/modules2019)。

## 基于 `go.sum` 进行模块验证

Go 1.11 的预览版 Go 模块方案引入了 `go.sum` 文件，此文件：

- 由 `go` 命令自动维护
- 存放于模块的根目录
- 保存着模块的每个依赖的内容加密校验值

若项目模块的源码树没有变化，利用 `go.sum` 对该模块的所有依赖进行验证，这样可保证明天的代码构建结果与今天的构建结果一致。明天下载到的依赖由 `go.sum` 负责验证。

另一方面，今天新添加或更新的依赖，是无法验证其下载的正确性，因为此时 `go.sum` 并没有对应的校验记录，所以无从对比。此时 `go` 命令只能盲目的认为下载到的已是正确代码。然后，`go` 命令会自动将本次下载到的代码的校验值存进 `go.sum` 中，以保证明天可验证。问题就在于初始下载时无法验证。此模型类似于 `SSH` 的 [首次使用信任](https://en.wikipedia.org/wiki/Trust_on_first_use)，尽管已是“任何时候都信任”的改良版，但依然不够理想，因为开发者下载新模块版本的次数远多于连接到未知 SSH 服务器的次数。

我们主要关注如何验证公共模块版本下载的正确性。而且我们认为私有模块源码所在的服务器是可信任的。相反，一个开发者若想使用 `rsc.io/quote` 模块，则不应随意信任 `rsc.io`（译注：因为这是一个公共模块）。当验证所有依赖时，这样盲目信任公共模块会产生很大的问题。
我们所需的是一个可易于访问的且包含所有公共模块版本的 `go.sum` 文件。然而，不是每个可下载到的 `go.sum` 文件都是可信的，否则 `go.sum` 就是攻击者的下一个目标。

## 透明日志

[Certificate Transparency（证书透明度，由 Google 发起的项目）](https://www.certificate-transparency.org/) 项目基于一个名为 `透明日志（transparent log）` 的数据结构。透明日志托管在服务器上，可供客户端随机访问。但客户端依然可验证特定部分的日志记录确实存在于日志中，并且可验证服务器永远不删除任何日志记录。另外，第三方检查者可遍历日志，检查是否所有日志记录都是准确的。上述两个特性结合起来可让客户端使用日志的内容，并确信所使用的内容别人依然能再次检查是否有效。客户端和检查者也可互相对比所得到的内容，以验证下载到的数据是否一致。

也就是说，不应信任日志服务器能正确存储日志，也不应信任日志服务器能将正确的内容存到日志中。相反，客户端和检查者与服务器通讯时应保持怀疑，并验证每次与服务器的通讯是否正确。

关于该数据结构的详细细节可见 Russ Cox 的博客文章 [为持怀疑态度的客户端设计的透明日志（Transparent Logs for Skeptical Clients）](https://github.com/vikyd/note/blob/master/translate-transparent_logs_for_skeptical_clients.md)。若想从更高层次了解 Certificate Transparency（证书透明度）及其动机、背景，可见 Ben Laurie 在 ACM Queue 发布的文章 [证书透明度：公开、可验证、仅追加的日志（Certificate Transparency: Public, verifiable, append-only logs）](https://queue.acm.org/detail.cfm?id=2668154)。

使用透明日志检测部分信任系统的异常行为已是一个普遍的趋势，使用透明日志作为模块哈希的保障也算是顺势而为。Trillian 团队将这种行为称之为 [通用透明度（General Transparency）](https://github.com/google/trillian/#trillian-general-transparency)。

---

# 提议

我们提议基于透明日志发布一个包含所有公共 Go 模块的 `go.sum` 服务。这是一个新的服务，我们将其称之为 Go checksum database（Go 的校验数据库）。当开发者准备使用一个新的公共模块时，若其本地 `go.sum` 文件没有该模块的信息，`go` 命令将先从 Go 校验数据库服务中拉取对应信息以验证模块内容的正确性，而非不经过验证就直接信任。

## 校验数据库（Checksum Database）

Go 校验数据库是：`https://sum.golang.org/`，提供以下功能：

- `/latest`（[链接](https://sum.golang.org/latest)）：
  - 提供最新日志的已签名的树大小和哈希值
- `/lookup/M@V`（[例子](https://sum.golang.org/lookup/github.com/google/uuid@v1.1.1)）：
  - 提供某个模块版本的日志数据记录编号，接着是此数据记录的具体内容（也就 `go.sum` 文件中对应模块版本的哈希信息），接着是已签名的树根哈希。若该模块版本尚未存在于日志中，则公证人（notary）会先去拉取模块代码内容，计算其哈希值后再响应给请求者。注意，做下面几项验证前，请不要使用模块数据：
    - 验证：初次验证 vs 已签名的树根哈希
    - 验证：已签名的树根哈希值 vs 客户端中已签名的树根哈希
- `/tile/H/L/K[.p/W`：
  - 提供一个日志瓦片（[log tile](https://github.com/vikyd/note/blob/master/translate-transparent_logs_for_skeptical_clients.md#%E6%8F%90%E4%BE%9B%E7%93%A6%E7%89%87%E6%9C%8D%E5%8A%A1)）。`.p/W` 是可选的，此后缀表示只有 `W` 个哈希值的不完整日志瓦片。若不完整的瓦片不存在，则客户端必须去获取完整瓦片。叶子哈希值 `/tile/H/0/K[.p/W]` 对应的数据记录可在此处找到 `/tile/H/data/K[.p/W]`（`data` 就是四个字母 `data`，而不是其他）。
  - > 译注：一些实例：[完整瓦片](https://sum.golang.org/tile/8/0/003)、[不完整瓦片](https://sum.golang.org/tile/8/1/006.p/189) 、[前面完整瓦片对应的记录数据](https://sum.golang.org/tile/8/data/003)

客户端的日常操作会使用 `/lookup` 和 `/tile/H/L/...`。检查者会使用 `/latest` 和 `/tile/H/data/...`。还有一个特别的 `go` 命令用于从 `/latest` 获取已签名的树根哈希，并强制整合进本地缓存。

## 代理一个校验数据库

一个模块代理也可代理到校验数据库的请求。通常代理的 URL 格式是 `<proxyURL>/sumdb/databaseURL`。如果 `GOPROXY=https://proxy.site`，则最新的已签名树的地址是 `https://proxy.site/sumdb/sum.golang.org/latest`。包含完整数据库的 URL 以后可转换到新的数据库日志，如 `sum.golang.org/v2`。

在通过代理访问任何校验数据库的 URL 前，代理客户端应首先获取 `<proxyURL>/sumdb/<sumdb-name>/supported`。若得到成功的响应（HTTP 200），则表明此代理支持代理校验数据库的请求。此时，客户端应仅使用代理，不要退回到直连数据库。若 `/sumdb/<sumdb-name>/supported` 得到失败的响应（如 `not found（找不到）` HTTP 404，`gone（已不存在）` HTTP 410），则表明此代理不代理校验数据库，此时客户端应直连数据库。此外的任何其他响应结果，都将被视为数据库不可用。

一个公司的代理可能任何时候都不想客户端直连数据库（例如出于隐私考虑；详见后面 `根本原因` 一节）。可选的 `/sumdb/supported` 操作，再加上对真正数据库请求的代理，可保证使用代理的 `go` 命令绝不会直连 `sum.golang.org`。但有些简化的代理可能只想专注于提供模块内容而非提供校验数据。特别的，有些只想提供模块内容的代理可直接通过静态文件系统来提供服务，从而无需任何额外的东西。这些代理的 `/sumdb/supported` 可返回 HTTP 404 或 HTTP 410，这样客户端就可以直连数据库了。

## `go` 命令客户端

`go` 命令是数据库日志的主要使用者。`go` 命令在使用数据库时会去 [验证其日志](https://github.com/vikyd/note/blob/master/translate-transparent_logs_for_skeptical_clients.md#%E9%AA%8C%E8%AF%81%E7%93%A6%E7%89%87)，以保证每个数据记录都是在日志中存在的，并且日志没有删除任何之前的数据记录。

`go` 命令会从环境变量 `$GOSUMDB` 中找到数据库的名字以及 Go 校验数据库的公钥。此变量的默认服务器是 `sum.golang.org`。

> 译注：Go 的默认服务器 `sum.golang.org` 的公钥是 [Go 内嵌的](https://github.com/golang/go/blob/master/src/cmd/go/internal/modfetch/key.go#L8)

`go` 命令会进行一些缓存：

- 将最新的已签名的树大小、树根哈希缓存到 `$GOPATH/pkg/sumdb/<sumdb-name>/latest`
- 将查找结果缓存到 `$GOPATH/pkg/mod/download/cache/sumdb/<sumdb-name>/lookup/path@version`
- 将瓦片缓存到 `$GOPATH/pkg/mod/download/cache/sumdb/<sumdb-name>/tile/H/L/K[.W]`

也即，`https://<sumdb-URL>` 将被缓存到 `$GOPATH/pkg/mod/download/cache/sumdb/<sumdb-URL>`。`go clean -modcache` 命令可删除缓存中的查找结果、瓦片，但不会删除最新的已签名的树根哈希，因为这个哈希值可用于发现时间线中的不一致。没有 `go` 命令可删除最近查询到的树大小值和树根哈希，只能通过手动执行此命令删除 `rm -rf $GOPATH/pkg`。若 `go` 命令一旦发现已签名的树大小值、树根哈希有不一致，会在标准输出中报严重错误，并且构建失败。

`go` 命令必须配置为：在校验数据库中查找公共模块，不查找闭源模块。这样对于那些可能包含私有 import 路径的项目特别有用，不然私有的 import 路径可能会通过 `/lookup` 泄露到外网。为支持上述配置，Go 引入了一些新的环境变量（若想更容易的管理这些变量，可见 Go 1.13 开发分支中的 [go env -w proposal](https://golang.org/design/30411-env)）。

- `GOPROXY=https://proxy.site/path`：
  - 如前所述，用于配置 Go 模块的代理地址
- `GONOPROXY=prefix1,prefix2,prefix3`：
  - 配置无需代理的模块路径前缀，支持 glob 模式。例如：
    ```sh
    GONOPROXY=*.corp.google.com,rsc.io/private
    ```
    此设置将不代理这些模块 `foo.corp.google.com`、`foo.corp.google.com/bar`、`rsc.io/private`、`rsc.io/private/bar`，但依然代理 `rsc.io/privateer`（匹配模式是基于路径前缀，而不是字符串前缀）
- `GOSUMDB=<sumdb-key>`：
  - 用于设置要使用的 Go 校验数据库，`<sumdb-key>` 是 [package note](https://godoc.org/golang.org/x/mod/sumdb/note#hdr-Verifying_Notes) 中定义的验证 key。
- `GONOSUMDB=prefix1,prefix2,prefix3`：
  - 配置无需去校验数据库查找的模块路径前缀，同样支持 glob 匹配。
    - 我们希望公司内的环境中可以通过内部代理获取所有公共及私有模块。`GONOSUMDB` 用于指定不去校验数据库查找内部模块，但依然去查找验证公共模块。因此，`GONOSUMDB` 不代表 `GONOPROXY`。
    - 我们还认为有些用户可能想直连模块源码，同时还能对开源模块或数据库的代理进行验证。`GONOPROXY` 允许对此进行设置，所以 `GONOPROXY` 也并不代表 `GONOSUMDB`。
    - > 译注：设置了 `GONOSUMDB` 的模块并不代表该模块无需代理；反之，设置了 `GONOPROXY` 的模块也不代表该模块无需校验

数据库若不能不响应 `go.sum` 中的某个模块版本的信息，这是一个严重问题；任何私有模块都应在 `$GONOSUMDB` 中明确列出（否则攻击者可能会拦截到数据库的通讯，并伪装所有模块版本都有响应）。可通过 `GONOSUMDB=*` 来完全禁用数据库。`go get -insecure` 命令也允许在数据库查找失败或查找错误后继续使用模块，但会报告不安全问题。

---

# 根本原因

在前面的 `背景` 一节已说明了为什么要验证模块的下载。需注意的是，我们除了想验证从代码服务器得到的模块，也想验证从代理得到的模块。

有两个值得讨论的话题：

- 整个 Go 生态只有 1 个数据库服务器
- 私有数据库服务器的实现方式

## 安全

Google 的 Go 团队负责发布运行 Go 验证数据库，类似 `godoc.org`、`golang.org` 那样作为 Go 生态系统的一部分。此服务的安全性很重要，我们已对此数据库的安全性已经设计了一段时间，有必要在此说下，目前的设计是怎样演变而来的。

最简单的方案（也是我们从未认真考虑的方案）就是设立一个可信的服务器，此服务器为每个模块版本颁发一个签名证书。此方案的缺点是：有问题的服务器可签发出有问题的模块版本证书，但使用者却难以发现其中问题。

> 译注：签发证书即：用服务器的私钥对模块信息进行签名，使用者用公开的公钥对签名内容进行验证，确认该模块内容确实如此

解决上述问题的办法之一是增加服务器的数量。例如，有个 N=3 或 N=5 个组织分别发布了自己的服务器，用户收集所有这些服务器的证书。当 (N+1)/2 个服务器中（译注：即过半数服务器）的证书一致，则认为该模块版本是有效可信的。此方法又有 2 个缺点：使用成本更高、且无检测真正攻击的方法。由于替换源码所得的回报可能会很高（译注：即做坏事的收益很高），所以可能会有人不择手段地对超过 (N+1)/2 的服务器进行攻击，并对证书做些不可告人的目的的事。因此，我们将重点转移到了对攻击的检测上。

若在被攻击前使用验证数据库来记录 `go.sum` 的条目到 [透明日志（transparent log）](https://github.com/vikyd/note/blob/master/translate-transparent_logs_for_skeptical_clients.md)，则：

- 若被篡改过的 `go.sum` 条蜜被存储进真正的日志，则检测者可发现此问题
- 若被篡改过的 `go.sum` 条目被存储在一个被攻击过的副本服务器，则此服务器必须一直提供有问题的副本给受害使用者，并且只提供给该使用者。否则，`go` 命令的一致性检查将会严重报错，并能提供足够密码学证据来证明该服务器被篡改过。

生态系统由不同组织机构维护的多个代理组成，这使得 `副本日志（forked log）` 的攻击成功率更低：攻击者既要篡改数据库，还要篡改每个受害者可能使用的代理服务器，并只让受害者访问被篡改的副本日志，而不能让非受害者访问（译注：否则非受害者会立即发现有问题）。

使用透明日志作为瓦片（tile）的服务方式既可有助于缓存和代理，又可更难被辨认出谁是受害者。当使用证书透明度（Certificate Transparency）响应证据的接口时，这些证据包含足够识别受害者的信息。举例来说，只向受害者提供偶数的日志大小，而给非受害者提供奇数的日志大小，并调整其他相应的验证信息。但获取到完整的瓦片后，里面并没有关于缓存日志大小的任何信息，这就更难只对受害者提供修改过的瓦片。

我们希望各组织机构在 Go 社区分别维护的代理同时也扮演检查者的角色，在日常的操作中复核 Go 验证数据库的日志条目。(另一个有用的地方是：可让数据库作为一个通知服务，告诉模块作者他们的模块出现了新版本)

> 译注：可能这个新版本不是作者发布的，而是攻击者发布的

如前所述，那些想篡改他们自己的模块的人（译注：这些人就是攻击者）需要同时篡改多个组织机构。但这些组织机构本身是可使用 Google 的验证数据库，并可通过不同组织的代理访问验证数据库。

> 译注：这说明很难篡改成功

概括一下此方法，增强对副本攻击检测的常用方式是增加群众的力量，如此一来，不同用户可以知道他们是否正在查看不一致的日志。实际上，代理协议已经支持此功能，所以任何代理数据库的代理都是群众的一员。如果我们增加 `go fetch-latest-checksum-log-from-goproxy`（很明显这不是最终的名字），并且

```sh
GOPROXY=https://other.proxy/ go fetch-latest-checksum-log-from-goproxy
```

能成功运行，则客户端及其他代理将见到一致的日志。

与最开始那种没有透明日志的单一验证数据库相比，使用透明日志的方法、支持数据库代理、增加群众监督，可大大增强对攻击的检测。这样回头一看，通过增加公证人复杂度得到的收效也就相对不大了。在未来，说不定 Go 生态还可以支持多个数据库，但就现在而言，在起步阶段我们优先选择了单数据库这样更简单的方案（且依然足够安全）。

## 隐私

向 Go 验证数据库验证一个新的依赖，需要向其发送模块路径、模块版本号。

数据库服务器理应发布一份类似 [Google 公共 DNS 隐私政策（Google Public DNS Privacy Policy）](https://developers.google.com/speed/public-dns/privacy) 的明确隐私政策声明，并且声明中说明应日志访问数据的存储时间（译注：如最长保留 48 小时等）。目前，此文件正在制定中。但此份声明也仅关心数据库所接收到的数据。数据库协议和使用的设计旨在最简化 `go` 命令的发送请求。

目前有 2 个主要的隐私担心：

- 向数据库暴露了私有模块的路径
- 向数据库暴露了对公共模块的使用数据统计信息

### 私有模块的路径

第一个主要的隐私问题是：误配置的 `go` 命令可能会将私有模块的路径文本（例如 `secret-machine.rsc.io/private/secret-plan`）发向数据库。数据库在处理模块时会先对 `secret-machine.rsc.io` 进行一次 DNS 查找，如果找到了，再向完整 URL 请求数据。但即使数据库在 DNS 查找失败时不去处理该模块，这些模块路径也在网络上走了一圈。

> 译注：数据在 DNS 查找的传输过程本身也可能泄密

有时还不容易察觉已误配置。正因如此，所以若数据库不能返回一个模块的信息时，将停止下载，并且 `go` 命令也会因而停止。这就保证了所有公共模块都是经过验证的，并且所有误配置都可被发现（可通过设置 `$GONOSUMDB` 来避免私有模块访问数据库），从而实现最终成功编译项目。通过此方法，可最小化因误配置而导致的数据库查询。一旦误配置了，也能立即发现和修复。

另一个避免在未来泄露私有模块路径的方法是提供更多配置 `GONOSUMDB` 的选项，尽管目前还不清楚这些选项长什么样子。其中一种方法可以是：在模块源码的根目录存储 `$GONOSUMDB` 和 `$GOPROXY`。但话又说话来，配置内容可能会因 checkout 不同版本的模块源码而变。此时，无论是手动还是使用类似 `git bisect` 的工具都可能会导致测试旧版本时产生奇怪的行为。

（基于环境变量的一个好处之一是：大部分公司的电脑已预设了对应的环境变量）

### 私有模块的 SHA256

另一个减少泄露隐私数据的方法是：使用可选的查找方法 `/lookup/SHA256(module)@version`，也即只发送模块路径的 SHA256，而不是发送模块路径本身。如果数据库本身已知道该模块路径，则它肯定能算出对应的 SHA256，从而可以根据客户端发过来的 SHA256 反推导出模块路径，从而进行模块数据查找，甚至拉取该模块的新版本。不过，若是误配置的 `go` 命令发送了一个私有模块的 SHA256，不会造成太多信息泄露。

但是，SHA256 方式确实需要在第一次使用公用模块时将模块路径发送到数据库，以便数据库可以更新其 SHA256 的反向索引。此操作我们暂将其称之为 `go notify <modulepath>`，在整个 Go 生态系统中一个模块路径只需执行此操作一次。大部分情况下，更多是模块作者去做这个操作，可能作为 `go release` 命令的其中一个步骤。或者模块的第一个用户做此操作（此时用户第一次使用该模块，应会十分谨慎）。

一个修改版的 SHA256 方案是只发送删减版的哈希值，即一个由 [K 匿名算法（K-anonymity）](https://en.wikipedia.org/wiki/K-anonymity) 产生的值。但此方法会造成明显的成本上升：如果数据库根据删减版的哈希值识别出了一个 K 公共模块，它还得去所有 K 的指定版本 tag 查找最终的值，之后才返回响应。更高的代价并未带来更多好处。（攻击者可以生成很多与著名模块碰撞的删减版哈希值，从而使请求变慢）

SHA256 + `go notify` 的模式并非本提议的一部分，我们目前考虑采用完整哈希值，而非删减版的哈希值。

### 公共模块的使用数据

第二个主要的隐私问题是，即使开发人员只使用公共模块，但只要从数据库请求新的 `go.sum` 行，也会暴露他们的模块使用偏好信息。

请记住 `go` 命令只会在添加新行到 `go.sum` 时才会去与数据库通讯。在日常的开发过程中，若 `go.sum` 已是最新，则从不会与数据库通讯。也即是说，只有在添加新依赖或修改已有模块的版本时才会与数据库通讯。这将有效减少向数据库发送使用的信息。

需注意的是，即使是 `go get -u` 命令，也不会向数据库查找所有依赖的数据，它只会请求有更新版本的依赖。

`go` 命令还会缓存数据库的查找结果（重新对比缓存的瓦片进行验证），所以一台计算机更新被一个被 N 个模块依赖的包时，也只会进行 1 次数据库查询，而非 N 次，进一步降低了暴露模块使用数据。

降低使用数据的泄露，还有一种办法是前面提到的 K 匿名（K-anonymity）删减版哈希值，不过依然会有效率问题。即使是 K 匿名 模块路径的下载信息，由于不同模块的流行度不一样，所以也可能会被猜测出客户端属于哪种典型类型，若结合版本信息，则更容易猜中了。删减版的哈希值在这里同样事倍功半的问题。

综上所述，使用代理及批量下载，才是不泄露私有或共有模块路径使用信息的完整方案。

### 通过代理保护隐私

针对数据库中的隐私问题，完整的方案是让开发者仅通过代理去访问数据库，例如本地的 `Athens` 实例或 `JFrog` 实例。前提是这些代理支持 Go 验证数据库的代理和缓存。

一个代理应提供一些关于模块隐私的设置模式，以保证即使是误配置的 `go` 命令也从不会跑到代理的外部去。数据库的接口本身已包含可缓存的设计，所以代理可以避免向数据库请求超过 1 次。不过新版本的模块还是需要向数据库请求的。

我们估计 Go 生态系统中将会出现很多可用的第三方代理。Go 校验数据库的其中一个设计目的就是允许使用任意代理下载模块，且不会损失任何安全性。开发者可使用他们喜欢的代理，或自行搭建代理。

### 通过批量下载保护隐私

代理可下载整个校验数据库，以避免每次渐进缓存导致的少量隐私信息泄露。我们估计 Go 生态系统约有 300 万个模块版本。若一个模块版本的信息为 200 字，则整个校验数据库中的 100 万个模块版本共约 20GB。下载完整的数据库，并在之后增量更新（因为是追加，所以很容易），可让宽带的交换数据完全匿名。本地代理可以完全应付所有的客户端请求，所以不会有任何私有模块路径或公共模块使用数据的泄露。此方法的代价是，假如客户端只需很小一部分的模块版本，也需下载整个数据库。（从今天来看，即使只需 100 个依赖，但却仍需从数据库下载 30000 倍的依赖信息，而且随着 Go 生态系统的增长，还会有更多开销）

不过，对于一个公司代理来说，下载整个数据库是一个不错的选择。

### 在持续集成、持续开发（CI/CD）中的隐私

在 CI/CD 中使用数据库时会有一些隐私问题。我们的希望是 CI/CD 永远不要与数据库通讯。

首先，通常的做法是，你只有在本地构建构建完毕（甚至测试完毕）后才推送到 CI/CD 系统。在本地的任何修改构建都会更新 `go.mod`，所以推送到 CI/CD 系统的 `go.sum` 是最新的。所以只会在添加内容到 `go.sum` 时与数据库通信。

其次，支持模块的 CI/CD 系统应已使用 `-mod=readonly` 参数。若 `go.mod` 不是最新的，则应抛出错误，而不是静静的去更新 `go.mod`。我们还会保证 `-mod=readonly` 参数能在 `go.sum` 文件不是最新时抛出错误（[#30667](https://golang.org/issue/30667)）。

# 兼容性

验证数据库的引入并不会在命令、语言层面有任何兼容性问题。但是修改过公共模块内容的代理将会在新的检查中变得不兼容，并导致该代理不可用。这正是我们设计的：不然这些被中间人攻击过代理将会混淆视听。

# 实现

Google 的 Go 团队正在开发 Go 模块代理、Go 验证数据库的生产环境版本。详细可见 [Go Modules in 2019](https://blog.golang.org/modules2019)。

我们将在 `go` 命令中发布一个验证数据库客户端，也会发布一个校验数据库的实现。我们将在 Go 1.13 中增加校验数据库的支持，并默认开启。

Russ Cox 将主导 `go` 命令的整合，并已在 [stack of changes in golang.org/x/exp/notary](https://go-review.googlesource.com/q/f:notary) 发布了一些修改。

Power by [Gitlies](https://gerrit.googlesource.com/gitiles/) | [Privacy](https://policies.google.com/privacy)
