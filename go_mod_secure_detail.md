# Golang Module 验证模块安全背后的细节

> 本文很啰嗦，因为有不少细节、实验

最近，可能有不少公司内网用户升级到 go 1.13 后踩到一个坑：go get 等操作突然无法获取内网的 Go 模块。

Golang 从 [1.11](https://golang.org/doc/go1.11#modules) 开始引入 Go Modules 机制，默认不启用。但到 [1.13](https://golang.org/doc/go1.13#modules) 开始自动启用 Golang Modules，并默认从 proxy.golang.org 拉取 Go 模块代码。若需拉取内网的 Go 模块，需自行配置环境变量：`GOPRIVATE=内网代码服务器URL`。

看似麻烦了一步，实质是 Golang 为模块安全而设计的方案。

Golang Module 为何要验证模块安全？又是如何验证模块哈希安全的 ？

> Golang 计划在 1.14 版本确定 [Modules 的最终方案](https://github.com/golang/go/wiki/Modules#go-111-modules)

本文用到的实验：

- https://github.com/vikyd/sumdbtest
- https://github.com/vikyd/go-checksum

# 目录

[TOC]

# 安全是指什么？

`模块内容的正确性` 与 `模块内容自身逻辑的安全性` 是两个话题，本文说的 `安全` 均指 `模块内容的正确性`，也可说是 `下载的正确性`。

举例来说：

- 是指：对于模块 M 的某个版本 V 的源码，其内容应是永远不变的，今天下载与明天下载的都应是相同的内容，全网所有人下载的也应是相同的内容，若遭中间人攻击、账号入侵、服务器入侵等，模块用户能及时发现该版本源码是否发生变化
- 不是指：模块 M 的某个版本 V 本身是否有内存泄露、SQL 注入、数组越界等问题

在 1.13 前，Golang 已在 go get 获取 [go-import](https://golang.org/cmd/go/#hdr-Remote_import_paths)（里面搜索 `go-import`）时强制使用 HTTPS，现在又基于 sumdb 方案向模块安全迈进了更彻底的一步。

# 名词约定

本文用到的词语：

- [Golang Module](https://github.com/golang/go/wiki/Modules)：又可称 `Golang 模块`，或 `Go 模块`，或 `模块`
- [Golang Module Proxy](https://golang.org/cmd/go/#hdr-Module_proxy_protocol)：又可称 `Go 模块代理`、`模块代理`、`代理`、`proxy`，官方的服务为 `proxy.golang.org`
- [Golang Checksum Database](https://go.googlesource.com/proposal/+/master/design/25530-sumdb.md#proposal)：又可称 `sumdb`，或 `校验数据库`，官方的服务为 `sum.golang.org`
- 默克尔树的根节点哈希值：又可称 `根哈希`，或 `树根哈希`
- 客户端：通常指 `go` 命令本身，可将 sumdb 理解为服务端，go 命令就是其客户端

# 引用说明

本文引用的 Golang 官方源码位置可能会因 Golang 的源码发生变化而找不到。若发现位置不存在，请告知。

# 实验环境

- 系统：macOS Mojave 10.14.6
- Golang：1.13.4
- 网络：Tencent-OfficeWiFi
- 抓包工具：
  - [Whistle](https://github.com/avwo/whistle)
  - [Charles](https://www.charlesproxy.com/)
    - 非必须，以树状看请求

> 本文应也适用于 DevNet 的 tlinux

# Go 1.13 中 go get 背后发生了什么？

## go get 1.13 vs 1.12

go get 时（或准确说是 `下载依赖的模块` 时），Go 1.13 相对于 1.12 的主要区别：

- Go 1.12
  - 通过 HTTPS 从源码仓库首页获取 [go-import](https://golang.org/cmd/go/#hdr-Remote_import_paths) 元数据
  - 通过 HTTPS 或 SSH clone 模块仓库源码
- Go 1.13
  - 对于外网模块
    - 从 \$GOPROXY 查询模块的版本列表
    - 从 \$GOSUMDB 获取模块哈希值及其辅助验证信息
    - 从 \$GOPROXY 下载模块源码
    - 若模块哈希值验证通过
      - 则正常使用
    - 若验证不通过
      - 抛出错误警告
  - 对于内网模块（\$GOPRIVATE）
    - 按 1.12 的方式进行

> \$GOPROXY 会自动从源码网站获取源码，再通过 HTTPS 转发给客户端

## go 1.13 中 go get 抓包实验

目的：查看 go 1.13 是如何使用 $GOPROXY、$GOSUMDB 的。

方法：将命令行的代理指向代理软件（Whistle），代理软件即可抓到 go get 命令的包。

### 抓包准备

安装、启动 Whistle：

```sh
# 适合在家里的安装方式（为了能自动读取系统 pac，通过你的翻墙服务访问 golang.org）
npm install -g whistle whistle.autopac

# 启动 Whistle
w2 start
```

- 浏览器打开 http://127.0.0.1:8899 -> 点击顶部右侧第二个：`HTTPS`
- 打钩 √ 2 个选项：
  - Capture TUNNEL CONNECTs
  - Enable HTTP/2
- 点击弹窗顶部：`Download RootCA`
- 双击下载的：`rootCA.crt`
  - 弹窗中：钥匙串=系统 -> 添加 -> 输入密码确定
- 打开 Mac 的 `钥匙串访问`
  - 弹窗中，左侧上方点击：系统
  - 此时右侧找到 `whistle.` 开头的，双击
  - 新弹窗中：信任 -> 使用此证书时 -> 始终信任 -> 输入密码，确定
- 重启 Whistle：`w2 restart`
- 浏览器打开 http://127.0.0.1:8899 ，点击左侧上方的 `Network`
  - 若有流量，此处会显示抓到的包

### 开始实验

```sh
# ---- 创建空模块 ----
# 任意位置创建目录
mkdir goget113
# 进入目录
cd goget113
# 初始化模块，模块路径随意，反正无需上传
go mod init github.com/vikyd/goget113

# ---- 删除所有缓存 ----
# 删除可能存在的 go.sum
rm go.sum
# 删除 go module 的所有源码、哈希缓存
sudo rm -rf $GOPATH/pkg

# ---- 设置命令行代理 ----
export https_proxy=127.0.0.1:8899

# ---- 正式 go get ----
# 尝试 go get 一个外网的简单模块（此模块不依赖其他模块）
go get github.com/google/uuid
```

另开一个命令窗（非必须），查看 Golang 默认的 GOPROXY、GOSUMDB：

```sh
go env
```

### 抓包结果

- 点击 http://127.0.0.1:8899 左侧的 `Network` 应能看到类似下图的抓包结果：
  - 点击每行，在左侧窗点击 `Inspectors`，应能看到响应结果

![go get Whistle 抓包](https://github.com/vikyd/note-bigfile/blob/master/img/go_mod_security/whistle-pure-go-get.png?raw=true)

- 若使用 Charles 抓包，还可看到直观的树状图：

![go get Charles 抓包](https://github.com/vikyd/note-bigfile/blob/master/img/go_mod_security/go-get-charles.png?raw=true)

- 会发现多了一个目录：`$GOPATH/pkg/mod/github.com/google/uuid@v1.1.1`

> 若想重现此结果，需再次清空 `$GOPATH/pkg`、`go.sum`，并删除 `go.mod` 中含 uuid 的行

> 清空缓存后，还可尝试下此命令 `go get github.com/google/uuid@master`，看看与前面的实验有何不同

### 结果简析

- 全程只与 proxy.golang.org、sum.golang.org 通讯，并无与 GitHub.com 通讯
- 全程只有 HTTP(S) 协议
- 部分响应 `410`，但不影响使用
- 除了从 proxy.golang.org 下载源码 zip 外，还有一些发向 sum.golang.org 的请求 `/lookup/...`、`/tile/...` 等
  - 这些请求用于获取模块哈希值及辅助验证信息，以确认模块内容没被篡改过

问题来了：为什么有了这些请求 `/lookup/...`、`/tile/...` 就可以确认模块内容没被篡改过？它是怎么做到的？

### 日常主要流程

- 开发者使用 Golang 开发项目
- 开发者引用了某个模块版本（如 [github.com/google/uuid 的 v1.1.1](https://github.com/google/uuid/releases/tag/v1.1.1)）
- `go get github.com/google/uuid` 等命令会：
  - 首先从 proxy.golang.org 获取版本列表
    - <https://proxy.golang.org/github.com/gin-gonic/gin/@v/list>
  - 再从 sum.golang.org 获取模块的哈希值等
  - 同时从 proxy.golang.org 下载模块的真正内容
- 若模块哈希值和签名验证成功：
  - 则开发者无感知，正常继续开发
- 若模块哈希值或签名验证失败：
  - 则警告该版本的模块内容可能被恶意篡改过，请谨慎使用

总之：正式使用外网公共模块前，Golang 会自动验证模块哈希值是否 `一致`，以及验证网上得来的哈希值是否 `可信`。

# Golang 关于 Module 安全的主要文章

Golang 官方针对 Go 模块的安全机制写了一些文章，下面是个人认为最主要的几篇：

- [【译】为持怀疑态度的客户端设计的透明日志（Transparent Logs for Skeptical Clients）](https://github.com/vikyd/note/blob/master/translate-transparent_logs_for_skeptical_clients.md)
- [【译】提案：为 Go 语言的公共模块生态建立安全机制（Proposal：Secure the Public Go Module Ecosystem）](https://github.com/vikyd/note/blob/master/secure_the_public_go_module_ecosystem.md)
- [GopherCon 2019 - Go Module Proxy: Life of a query](https://about.sourcegraph.com/go/gophercon-2019-go-module-proxy-life-of-a-query)
- [【译】我们的软件依赖问题（Our Software Dependency Problem）](https://github.com/vikyd/note/blob/master/our_software_dependency_problem.md)

继续看本文之前，建议先浏览上述文章。前 2 篇有些晦涩，第 3 篇相对通俗，但都缺乏一些详细可验证的实验。因此本文主要从可操作的实验出发对其内部机制继续解释。

# 安全方案总览

下图是 Go 模块方案中关于安全方面的内容：

![Golang Module 框架](https://github.com/vikyd/note-bigfile/blob/master/img/go_mod_security/go-mod-framework.png?raw=true)

> 上图只包含安全相关的内容，不包含 Go 模块关于语义版本等的其他内容

要点：

- 核心：Merkle Tree
  - 校验模块内容正确性的 `核心` 数据结构
- 客户端：
  - 可理解为开发者本地的 `go` 命令
  - 客户端新增了：
    - 中间层 URL 的配置（如 \$GOPROXY）
    - 模块记录文件 `go.mod`、`go.sum`
    - 模块相关命令
    - 本地模块源码、哈希缓存
- 中间层：
  - 在模块源码与开发者之间，加了一层代理、校验数据库
  - 对于公共模块，客户端将从代理获取模块
  - 代理不存储模块源码（仅按需缓存）
  - sumdb 用于验证模块下载的正确性
  - sumdb 仅存储哈希值
  - 第三方可自行搭建代理
- 内网私有模块：
  - 因私有，无法统一校验数据库，所以内网模块安全问题留给内网自行处理

此外，也可从 [这篇官方文章](https://blog.golang.org/modules2019#TOC_8.) 总览了解：

![](https://blog.golang.org/modules2019/code.png)

备注：

- mirror：可理解为 proxy.golang.org
- notary：可理解为 sum.golang.org
- index：可理解为 index.golang.org
- godoc.org：可参考 [这篇](https://github.com/vikyd/note/blob/master/godocorg_gopkgin_golangorgx_diff.md)

# 中间层总览

以前面 `go get github.com/google/uuid` 抓包实验为例。

下图是目前 Go 模块所有中间层服务的所有接口的总览、示例：

![中间层总览、示例](https://github.com/vikyd/note-bigfile/blob/master/img/go_mod_security/go-mod-all-service.png?raw=true)

> 前面实验只用到了上图的部分接口

下面是可戳戳戳的文字版：

## `proxy.golang.org`

本服务主要提供模块源码的转发。

- `/modulePath/@v/list`
  - <https://proxy.golang.org/github.com/google/uuid/@v/list>
- `/modulePath/@v/version.info`
  - <https://proxy.golang.org/github.com/google/uuid/@v/v1.1.1.info>
- `/modulePath/@v/version.mod`
  - <https://proxy.golang.org/github.com/google/uuid/@v/v1.1.1.mod>
- `/modulePath/@v/version.zip`
  - <https://proxy.golang.org/github.com/google/uuid/@v/v1.1.1.zip>
- `/sumdb/databaseURL/supported`
  - <https://goproxy.cn/sumdb/sum.golang.org/supported>
- `/sumdb/databaseURL/sumdbSubUrl`
  - <https://goproxy.cn/sumdb/sum.golang.org/lookup/github.com/google/uuid@v1.1.1>

参考：[Module proxy protocol](https://golang.org/cmd/go/#hdr-Module_proxy_protocol)

## `sum.golang.org`

本服务主要提供模块哈希值及其辅助校验信息。

- `/latest`
  - https://sum.golang.org/latest
- `/lookup/modulePath@version`
  - <https://sum.golang.org/lookup/github.com/google/uuid@v1.1.1>
- `/tile/tileHeight/tileLevel/offsetInLevel`
  - https://sum.golang.org/tile/8/0/003
- `/tile/tileHeight/tileLevel/offsetInLevel.p/tileWidth`
  - https://sum.golang.org/tile/8/0/x001/735.p/144
- `/tile/tileHeight/data/offsetInLevel0`
  - https://sum.golang.org/tile/8/data/003
- `/tile/tileHeight/data/offsetInLevel0.p/tileWidth`
  - https://sum.golang.org/tile/8/data/x001/735.p/144

参考：[Golang 关于 sumdb 的部分源码](https://github.com/golang/mod/blob/master/sumdb/server.go)

## `index.golang.org`

本服务主要提供已记录到 sumdb 中的模块哈希值列表。

- `/index`
  - https://index.golang.org/index
- `/index?limit=10`
  - https://index.golang.org/index?limit=10
- `/index?since=2019-10-20T09:00:00.123456Z`
  - https://index.golang.org/index?since=2019-10-20T09:00:00.123456Z
- `/index?since=2019-10-30T09:00:00.123456Z&limit=10`
  - https://index.golang.org/index?since=2019-10-20T09:00:00.123456Z&limit=10

参考：[index 首页文档](https://index.golang.org/)

## 可能的疑惑

- 为什么会有这些接口？
- 为什么 Merkle Tree 是本机制的核心？
- 这几个服务间有什么具体联系？
- `/lookup` 的响应内容每行是从哪来的？
- `/tile` 的路径是如何推导出来的？
- `/tile` 的响应内容为什么看起来像乱码？
- golang.org 域名需翻墙才能访问，不翻墙是否有办法使用上述服务？
- `GOPROXY`、`GOSUMDB` 等环境变量该如何使用、修改？其格式又是怎样的？

若好奇这些问题，可继续往下看。

# 服务分析

逐个服务分析之前，先大致了解下这三者之间的关系：

- 客户端通常只用到 `proxy.golang.org` 和 `sum.golang.org`
- 客户端先从 `proxy.golang.org` 获取模块版本列表后，再拼接出 sumdb 的 `/lookup` 具体路径
- `index.golang.org` 主要供第三方代理服务 [更新数据使用](https://blog.golang.org/module-mirror-launch#TOC_1.3.)
- 安全逻辑主要在 `sum.golang.org`，后面会有较大篇章分析此服务
- 第三方代理服务（如 goproxy.cn）在转发模块源码的同时，可顺便代理 sumdb
  - 原始链接：<https://sum.golang.org/lookup/github.com/google/uuid@v1.1.1>
  - 代理后的链接：<https://goproxy.cn/sumdb/sum.golang.org/lookup/github.com/google/uuid@v1.1.1>
- 所有服务接口都是 `GET` 操作

# 分析 `proxy.golang.org`

`proxy.golang.org`：提供获取模块源码的代理服务。

任何人都可以自行实现、搭建一个类似 `proxy.golang.org` 的代理，只需遵循 [模块代理协议（Module proxy protocol）](https://golang.org/cmd/go/#hdr-Module_proxy_protocol) 即可。

## 优点

> 以下纯属个人观点

- 解耦 `源码获取` 与 `版本管理工具`：
  - 客户端（如 go get 命令）只需 HTTP(S) 即可获取依赖的模块源码，无需依赖 git、svn 等版本管理工具
- 解耦 `源码获取` 与 `客户端的网络可达性`：
  - 只需代理服务能访问到模块源码，无需客户端直接访问，客户端只需与代理服务通讯（也适合持续集成使用）
- 仓库去中心化（这个不全是代理服务的优点）：
  - 即使 `proxy.golang.org` 完全挂掉，依然可使用第三方代理
  - 第三方也可自行搭建代理，且安全性不会受影响（因为 sumdb 的机制）
  - 仓库本身甚至都不算仓库，只是各大源码网站的代理而已
  - 无需仓库，也即第三方代理无需像 Java Maven、Python pip、JavaScript npm 等包管理方案那样镜像同步全量模块，按需获取、缓存即可
  - 简化模块的管理权限
    - 发布模块无需注册仓库账号
    - 各大源码网站（如 GitHub）本身的权限就是模块的管理权限，无中间权限环节
      - > 像 npm 是需要去仓库网站额外 [注册账号](https://juejin.im/post/5b95c2ed6fb9a05cd67699d1) 才能发布模块

> 模块代理有种 Golang 推崇的 `正交` 的味道

## 缺点

> 以下纯属个人观点

- 相比原来 [`go-import` tag](https://golang.org/cmd/go/#hdr-Remote_import_paths) 方案多加了一层逻辑
- 国内不能访问默认的 `proxy.golang.org`
  - 虽 Golang 官方提供了针对国内的 `sum.golang.google.cn`，但并未提供 `proxy.golang.google.cn`
  - 解决办法是使用类似 goproxy.cn 的第三方代理，或不使用代理
- 模块 import path 可能泄露：
  - 刚开始使用时，若忘了配置 GOPRIVATE 或 GONOPROXY 或 GONOSUMDB 等，go get 时可能会向外部代理（`proxy.golang.org` 或 `goproxy.cn`）发送内网模块的 import path，即导致 import path 的泄露
  - 若对于你来说 import path 泄露也没关系，则问题不大

## 细节特点

- 以 `/modulePath/@v/` 开头的接口：
  - `@v` 是固定的两个字符，用于分隔模块路径与后续 URL
- URL 中的 `modulePath`、`version` 中不能含有大写字母，若含大写字母，则应先转为 `!小写字母` 形式
  - 如这个模块 github.com/Azure/go-autorest
  - 可使用：<https://proxy.golang.org/github.com/!azure/go-autorest/@v/list>
  - 不可用：<https://proxy.golang.org/github.com/Azure/go-autorest/@v/list>

## 接口：`/modulePath/@v/list` 版本列表

用途：本接口返回一个模块的版本列表。

实例：<https://proxy.golang.org/github.com/google/uuid/@v/list>

响应实例：

```
v1.0.0
v1.1.1
v1.1.0
```

> 版本列表不一定按大小顺序，但只要遵循 [SemVer](https://blog.golang.org/versioning-proposal) 即可

逻辑：

- `go get` 时若不指定模块版本号，则默认获取此接口中的最新版本
- 客户端从本接口拿到模块的版本列表后可得知最新版本号是什么，再拼接出 sumdb 的 `/looup` 路径，如：<https://sum.golang.org/lookup/github.com/google/uuid@v1.1.1>

## 接口：`/modulePath/@v/version.info` 版本元数据信息

用途：获取指定模块版本的元数据信息。

实例：<https://proxy.golang.org/github.com/google/uuid/@v/v1.1.1.info>

响应实例：

```
{"Version":"v1.1.1","Time":"2019-02-27T21:05:49Z"}
```

目前元数据只有这 2 项（日后可能会增加）：

- Version：版本号
- Time：git 的 commit 时间

疑问：

- `/list` 接口已返回版本号，为什么还需要本接口？
  - 答：为了兼容类似 `go get github.com/google/uuid@master` 的场景。
    - 此时响应：`{"Version":"v1.1.2-0.20190416172445-c2e93f3ae59f","Time":"2019-04-16T17:24:45Z"}`
    - 其中 `"v1.1.2-0.20190416172445-c2e93f3ae59f"` 是一个 [伪版本号](https://golang.org/cmd/go/#hdr-Pseudo_versions)

参考：

- [此文](https://golang.org/cmd/go/#hdr-Module_proxy_protocol) 搜索 `// commit time`
- [此文](https://about.sourcegraph.com/go/gophercon-2019-go-module-proxy-life-of-a-query) 搜索 `why does the go command need it`

## 接口：`/modulePath/@v/version.mod` go.mod 文件

用途：获取指定模块版本的 go.mod。

实例：

- 无子依赖：<https://proxy.golang.org/github.com/google/uuid/@v/v1.1.1.mod>
- 有子依赖：<https://proxy.golang.org/github.com/gin-gonic/gin/@v/v1.4.0.mod>

响应实例：

```
module github.com/gin-gonic/gin

go 1.12

require (
	github.com/gin-contrib/sse v0.0.0-20190301062529-5545eab6dad3
	github.com/golang/protobuf v1.3.1
	github.com/json-iterator/go v1.1.6
	github.com/mattn/go-isatty v0.0.7
	github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd // indirect
	github.com/modern-go/reflect2 v1.0.1 // indirect
	github.com/stretchr/testify v1.3.0
	github.com/ugorji/go v1.1.4
	golang.org/x/net v0.0.0-20190503192946-f4e77d36d62c
	gopkg.in/go-playground/assert.v1 v1.2.1 // indirect
	gopkg.in/go-playground/validator.v8 v8.18.2
	gopkg.in/yaml.v2 v2.2.2
)
```

备注：

- 虽然模块源码内通常都有 go.mod 文件，但没必要下载整个模块再分析其子依赖。所以专门提供了本接口，方便快速获取子依赖

## 接口：`/modulePath/@v/version.zip` 模块源码

用途：返回模块的真正源码（不含 `.git` 等版本工具目录）。

实例：<https://proxy.golang.org/github.com/google/uuid/@v/v1.1.1.zip>

响应实例：就是一个 zip 文件

备注：

- 后面提到的模块哈希值不是指本 zip 文件的直接哈希值，详细可看 [这篇文章](https://github.com/vikyd/note/blob/master/golang-checksum.md)

## 接口：`/sumdb/databaseURL/supported` 检查是否支持 sumdb 代理

用途：检测此代理服务是否也支持代理 sumdb（支持则返回 HTTP Status 200）。

实例：

- 支持：https://goproxy.cn/sumdb/sum.golang.org/supported
- 不支持：https://proxy.golang.org/sumdb/sum.golang.org/supported

响应实例 Header（无 Body）：

```
:status: 200
server: nginx/1.12.2
date: Thu, 31 Oct 2019 07:40:03 GMT
content-length: 0
```

备注：

- 官方代理 `proxy.golang.org` 不支持代理 sumdb，应是因为能访问 `proxy.golang.org` 自然也就能访问 `sum.golang.org`，所以无需代理 sumdb
- 一旦代理服务提供本接口，则客户端会优先从本代理服务获取 sumdb 的数据，[不通再](https://go.googlesource.com/proposal/+/master/design/25530-sumdb.md#proxying-a-checksum-database) 从 `$GOSUMDB` 获取
- 由于国内不能访问 `sum.goalng.org` 和 `proxy.golang.org`，所以第三方代理连 sumdb 也代理了，用户只需配置一步 `GOPROXY=第三方代理`，即可同时代理两者（Golang 的 [约定](https://go.googlesource.com/proposal/+/master/design/25530-sumdb.md#proxying-a-checksum-database)）
  - Golang 官方虽 [针对国内](https://github.com/golang/go/blob/master/src/cmd/go/internal/modfetch/sumdb.go#L70) 提供了 sum.golang.google.cn，但用户需额外配置 `GOSUMDB=sum.golang.org https://sum.golang.google.cn`，相对麻烦

## 接口：`/sumdb/databaseURL/sumdbSubUrl` sumdb 的子路径

用途：代理后的 sumdb 的各个接口。

实例（以 `goproxy.cn` 为例）：

- sumdb 的 `/lookup`：<https://goproxy.cn/sumdb/sum.golang.org/lookup/github.com/google/uuid@v1.1.1>
- sumdb 的 `/tile`：https://goproxy.cn/sumdb/sum.golang.org/tile/8/0/003

响应实例（`/lookup` 为例）：

```
842
github.com/google/uuid v1.1.1 h1:Gkbcsh/GbpXz7lPftLA3P6TYMwjCLYm83jiFQZF/3gY=
github.com/google/uuid v1.1.1/go.mod h1:TIyPZe4MgqvfeYDBFedMoGGpEw/LqOeaOT+nhxU+yHo=

go.sum database tree
445646
jEFFy4AtYgBBNTSZTiNnQrgQqMbcH0mfO2oP2FxR9VU=

— sum.golang.org Az3grkGho/PqvUmEuTv6+r2g303hUhu60FOD6vLpm19mBwH9UjquWY2OKxNmZ55z0gHrp24AgPC3Q5WO7uZrVdvdCQU=
```

备注：

- 除了 URL 前面部分是代理服务的外（`goproxy.cn/sumdb/sum.golang.org`），URL 后面部分与 sumdb 的路径一致（`lookup/github.com/google/uuid@v1.1.1`）
- 代理服务同时提供对 sumdb 的代理，对用户来说更方便了，因为无需再配置独立的 sumdb 代理

## 第三方代理

第三方代理的优缺点在本节开头已有说明。

这么多第三方代理，该选哪个？

答：

- 无翻墙条件时用 goproxy.cn
- 有翻墙条件时用 Golang 默认的 proxy.golang.org

推荐 goproxy.cn 理由：见下面优缺点。

下面是目前搜索到的一些代理：

### 官方：proxy.golang.org

- 推荐：★★★★★
- 能翻墙且速度可以的话，能用官方的尽量用官方的
- 仅支持模块源码代理，不支持代理 sumdb
  - 因为能访问 `proxy.golang.org` 的话，当然也就能访问 `sum.golang.org`，所以官方无需代理

### 七牛云：goproxy.cn

- 推荐：★★★★★
- [简介](https://github.com/guanhui07/blog/issues/642)
- 同时支持模块源码代理 和 [sumdb 代理](https://go.googlesource.com/proposal/+/master/design/25530-sumdb.md#proxying-a-checksum-database)，比较省心
- 速度 [较快](https://github.com/goproxy/goproxy.cn/blob/master/assets/videos/goproxy.cn-vs-goproxy.io.mp4?raw=true)
- 在国内已备案域名，未来被封的风险相对低些

下图是 `export GOPROXY=goproxy.cn` 后，`go get github.com/google/uuid` 的抓包结果：

![goproxy.cn 的 go get 抓包](https://github.com/vikyd/note-bigfile/blob/master/img/go_mod_security/go-get-goproxy-cn.png?raw=true)

可见本地只与代理 `goproxy.io` 通讯，并无与 `proxy.golang.org`、`sum.golang.org` 通讯。

### 个人？：goproxy.io

- 推荐：★★★★
- 同时支持 [模块源码代理](https://golang.org/cmd/go/#hdr-Module_proxy_protocol) 和 [sumdb 代理](https://go.googlesource.com/proposal/+/master/design/25530-sumdb.md#proxying-a-checksum-database)，比较省心

下图是 `export GOPROXY=goproxy.io` 后，`go get github.com/google/uuid` 的抓包结果：

![goproxy.io 的 go get 抓包](https://github.com/vikyd/note-bigfile/blob/master/img/go_mod_security/go-get-goproxy-io.png?raw=true)

可见本地只与代理 `goproxy.io` 通讯，并无与 `proxy.golang.org`、`sum.golang.org` 通讯。

### 腾讯云：mirrors.tencent.com/go

- 推荐：★★★
- 仅支持 [模块源码代理](https://golang.org/cmd/go/#hdr-Module_proxy_protocol)，不支持 [sumdb 代理](https://go.googlesource.com/proposal/+/master/design/25530-sumdb.md#proxying-a-checksum-database)

  - 即此接口未返回 HTTP Status 200：https://mirrors.tencent.com/go/sumdb/sum.golang.org/supported

### 阿里云：mirrors.aliyun.com/goproxy

- 推荐：★★
- 仅支持 [模块源码代理](https://golang.org/cmd/go/#hdr-Module_proxy_protocol)，不支持 [sumdb 代理](https://go.googlesource.com/proposal/+/master/design/25530-sumdb.md#proxying-a-checksum-database)

  - 此接口未返回 HTTP Status 200：https://mirrors.aliyun.com/goproxy/sumdb/sum.golang.org/supported

### 百度：goproxy.baidu.com

- 推荐：★★★
- 同时支持 [模块源码代理](https://golang.org/cmd/go/#hdr-Module_proxy_protocol)，和 [sumdb 代理](https://go.googlesource.com/proposal/+/master/design/25530-sumdb.md#proxying-a-checksum-database)，比较省心

# 分析 `sum.golang.org`

`sum.golang.org`：校验下载到的模块内容是否被篡改过。

> 有种 [区块链](https://zh.wikipedia.org/wiki/%E5%8C%BA%E5%9D%97%E9%93%BE) 在包管理器中应用的感觉

本服务是整个 Golang 模块安全机制中的 `核心`，也是篇幅最长的一节。

往下看本文前，建议先浏览以下 Golang 官方的文章（或者对本文章节有疑惑时，也可从这几篇文章找到原始的答案）：

- [【译】为持怀疑态度的客户端设计的透明日志（Transparent Logs for Skeptical Clients）](https://github.com/vikyd/note/blob/master/translate-transparent_logs_for_skeptical_clients.md)
- [【译】提案：为 Go 语言的公共模块生态建立安全机制（Proposal：Secure the Public Go Module Ecosystem）](https://github.com/vikyd/note/blob/master/secure_the_public_go_module_ecosystem.md)
- [GopherCon 2019 - Go Module Proxy: Life of a query](https://about.sourcegraph.com/go/gophercon-2019-go-module-proxy-life-of-a-query)

## 概述

从前面的 go get 实验抓包可发现以下规律：

- 在从 `proxy.golang.org` 下载模块源码的同时，也从 `sum.golang.org` 中的 `/lookup`、`/tile` 接口获取验证信息
- 先获取 `/lookup`，再获取 `/tile`

可从这两个接口的 URL、响应 入手，逐步了解其中原理。

## sumdb 原理简述

- 对每个版本模块的源码计算哈希值（SHA-256）
  - 由于目前 SHA-256 不可破解，做不到生成两个内容不同的文件，但其 SHA-256 一致
  - 所以模块内容发生变化，则其 SHA-256 一定发生变化
- 全网有很多模块，会有多个哈希值，以这些哈希值作为二叉树的叶子节点，每往上一层的节点值都是下层 2 个节点哈希值的哈希值，这棵树可称为默克尔树（[Merkle Tree](https://en.wikipedia.org/wiki/Merkle_tree)）
- 默克尔树的特性
  - 作为叶子节点的模块内容一旦发生变化，则树的根节点哈希值（后简称 `根哈希`）必然会发生变化
  - 也即若叶子节点的模块内容没发生变化，且叶子节点顺序没变化，且叶子数没有增多，则树的根节点哈希值也必然不变
- 默克尔树的上述特性可使得：计算底层哈希值，并对比根节点哈希值是否一致，即可验证模块内容是否发生过变化
  - 若发生变化了，则说明该模块版本内容被篡改过，应引起警惕或不要使用该模块
  - 若没变，则说明该模块版本内容没变，可放心下一步使用

默克尔树本质很简单，就是一直往上计算哈希值，并对比根哈希。

有了原理还不够，实际应用中会碰到很多细节问题需要解决。

### 细节问题

- 如何让客户端使用尽量少的数据就能验证模块？
  - 全网模块仅哈希值总和的大小都很大，不可能全量一齐计算根节点
- 如何证明即使服务器被入侵篡改了，客户端也能发现模块被篡改过？
- 如何高效在客户端缓存，且尽量提高网络传输效率？
- 何时、如何、谁去增加新叶子节点？
- 是否该存储非叶子节点？
- 默克尔树是否该把私有模块也纳入叶子节点？
- 如何才能区分私有模块和外网模块？
- 一个 sumdb 足够么？多个 sumdb 的话有没有什么问题？

## 优点

- 基于类似 [区块链底层](https://www.chainnews.com/articles/439491610598.htm) 的默克尔树作为验证方式，简单且有效
- 可验证一个模块的内容确实没被篡改过，且能快速发现服务器是否作出欺骗行为

## 缺点

- 猜：是否会存在恶意模块请求攻击，导致 sumdb 快速膨胀？
- 猜：一旦目前主要的 sumdb `sum.golang.org` 挂掉了，新模块如何才能记录到 sumdb 中，且与恢复后的 `sum.golang.org` 兼容？

## 细节特点

- URL 中的 `modulePath`、`version` 中不能含有大写字母，若含大写字母，则会转为 `!小写字母`

  - 如这个模块 github.com/Azure/go-autorest
  - 可使用：<https://sum.golang.org/lookup/github.com/!azure/go-autorest@v1.1.0>
  - 不可用：<https://sum.golang.org/lookup/github.com/Azure/go-autorest@v1.1.0>

### sumdb 涉及技术

可无需深入了解，这里只是简单汇总一下。

哈希：

- [默克尔树](https://en.wikipedia.org/wiki/Merkle_tree)
- [SHA-256](https://en.wikipedia.org/wiki/SHA-2)
- SHA-512
- [大端序](http://www.ruanyifeng.com/blog/2016/11/byte-order.html)

签名：

- [ED25519](https://en.wikipedia.org/wiki/EdDSA#Ed25519)
  - [椭圆曲线加密](https://zhuanlan.zhihu.com/p/26029199)

编码：

- [Base64](http://www.ruanyifeng.com/blog/2008/06/base64.html)

## 接口：`/lookup/modulePath@version` 模块版本哈希及子树签名（核心）

用途：获取一个模块版本的哈希值，以及其在 sumdb 中的编号、树大小、根哈希、根哈希签名，其中模块哈希值、根哈希将是被最终对比验证的值。

> 本接口通常与 `/tile` 接口配合使用才能最终验证模块正确性

实例：<https://sum.golang.org/lookup/github.com/google/uuid@v1.1.1>

响应实例：

```
842
github.com/google/uuid v1.1.1 h1:Gkbcsh/GbpXz7lPftLA3P6TYMwjCLYm83jiFQZF/3gY=
github.com/google/uuid v1.1.1/go.mod h1:TIyPZe4MgqvfeYDBFedMoGGpEw/LqOeaOT+nhxU+yHo=

go.sum database tree
454425
CF4Gdi7ahAx2DQ1icZRlXpgIZ4mMy3FE7ZH+asIYk9Y=

— sum.golang.org Az3grrJsLRs6sNa2gQWy6G6jb/FLI7opFZErrJT1PWmmP4iUdRxoJhMgfmSkirJgj3zj7n3N61yL16+9521wNu12Sgo=
```

初看上面响应结果可能一脸懵逼，这是什么？我是谁？我为什么会在这里？这些像 base64 的一串东西是什么？

一番搜索可能会发现 Golang 官方这个 [说明文档](https://go.googlesource.com/proposal/+/master/design/25530-sumdb.md#checksum-database) ，但其中说明并不太具体。以下是具体说明：

```
模块在树中的编号（可理解为树中叶子节点的顺序号，从 0 起算）
模块内容哈希值（遍历文件，而非基于 zip）
模块内 go.mod 的哈希值（基于 文件内容+辅助字符串 而得的哈希）

go.sum database tree
树大小（即叶子数）
sum.golang.org 树根哈希值（默克尔树中的一棵包含该模块的子树）

— sum.golang.org 网站私钥 对根哈希进行的签名（Go 内置了公钥对签名进行验证）
```

### 模块哈希值的奇怪计算方法

```
github.com/google/uuid v1.1.1 h1:Gkbcsh/GbpXz7lPftLA3P6TYMwjCLYm83jiFQZF/3gY=
github.com/google/uuid v1.1.1/go.mod h1:TIyPZe4MgqvfeYDBFedMoGGpEw/LqOeaOT+nhxU+yHo=
```

上述两行是模块源码的哈希值、模块 go.mod 的哈希值，看起来与 go.sum 文件中的哈希值有些相似，可从这两行开始理解。

奇怪就怪在容易造成以下误解：

- （错误）模块的哈希值是模块的 zip 包哈希值
- （错误）go.mod 的哈希值由 go.mod 的内容直接计算而得

正确的理解：

- 模块的哈希值由模块里每个文件内容的哈希值按文件名顺序拼接一起后计算而得
- go.mod 的哈希值由 go.mod 的内容及一些辅助字符拼接一起后计算而得
- 这些 SHA-256 最终均以 base64 编码后在本接口中返回
- 源码仓库内的 `.git` 等版本管理工具目录内的文件不作为哈希计算范围
- 源码仓库内的任何文件变化（除 `.git` 等外）都会导致其 SHA-256 变化
  - 即使是 `README.md`、`a.txt` 等文件内容发生变化，此模块的哈希也会变化

疑问 & 解答 & 实验：

- 为什么需要计算模块哈希值？
- 为何不对整个模块打包 zip 求哈希？
- 为什么已有模块哈希，还需 go.mod 哈希？
- 前面的 `h1` 又是什么？
- 是否有简单实验验证此哈希计算过程？

以上解答、实验均可见 [这篇小文](https://github.com/vikyd/note/blob/master/golang-checksum.md)，这里不再重复。

### 根哈希签名验证

根哈希的用途暂放一边，先来看看根哈希的签名。

签名目的：

（若理解有错，请指正）因 sumdb 可能被中间人攻击修改，中间人修改根哈希后可能会导致客户端从一开始就被中间人欺骗，私钥只有 `sum.golang.org` 知道，签名后中间人无法篡改根哈希而不被发现。

```
go.sum database tree
454425
CF4Gdi7ahAx2DQ1icZRlXpgIZ4mMy3FE7ZH+asIYk9Y=

— sum.golang.org Az3grrJsLRs6sNa2gQWy6G6jb/FLI7opFZErrJT1PWmmP4iUdRxoJhMgfmSkirJgj3zj7n3N61yL16+9521wNu12Sgo=
```

即：

```
go.sum database tree
树大小（即叶子数）
sum.golang.org的树根哈希值（默克尔树中的一棵包含该模块的子树根哈希）

— sum.golang.org 对根哈希的签名（Go 内置了公钥对签名进行验证）
```

解释：

- 原始文本（被签名）：
  - `go.sum database tree\n454425\nCF4Gdi7ahAx2DQ1icZRlXpgIZ4mMy3FE7ZH+asIYk9Y=\n`
  - 注意上面包含 3 个换行符 `\n`
  - 此字符串就是被签名的原始文本
- 签名结果：
  - `Az3grrJsLRs6sNa2gQWy6G6jb/FLI7opFZErrJT1PWmmP4iUdRxoJhMgfmSkirJgj3zj7n3N61yL16+9521wNu12Sgo=`
  - 此字符串前面一小部分不属于签名

下面将对此签名细节进行分析及实验验证 ↓

#### 数字签名回顾

数字签名可用于证实数据确实是某人发出的：

- A 想发数据给 B，B 想验证数据确实是 A 发出的
- A 生成钥匙对，私钥自己保留，公钥对外公布
- A 用私钥对数据 D 的哈希 H 进行加密，得到一个签名 S
- A 将数据 D、签名 S 一同发送给 B
- B 用 A 公布的公钥，对 S 进行解密得到 H1
- 再与由 D 计算得到的哈希 H2 进行对比
  - 一致：说明 D 确实是 A 发出的
  - 不一致：说明 D 不是 A 发出的
- 通俗图示说明可见阮一峰老师的 [数字签名是什么？](http://www.ruanyifeng.com/blog/2011/08/what_is_a_digital_signature.html)

#### sumdb 签名

Golang sumdb 使用的签名方式：

- 算法：[Ed25519](https://godoc.org/golang.org/x/exp/sumdb/internal/note#hdr-Generating_Keys)
- 私钥：Golang 官方持有，不公开
- 公钥：内置在 Golang 源码内
  - [公钥位置](https://github.com/golang/go/blob/master/src/cmd/go/internal/modfetch/key.go#L8)
  - 公钥：`sum.golang.org+033de0ae+Ac4zctda0e5eza+HJyk9SxEdh+s3Ux18htTTAD8OuAn8`
  - 这是一个特殊值，后面会详解
- 明文数据（即此数据的哈希将被私钥加密）：
  - `go.sum database tree\n454425\nCF4Gdi7ahAx2DQ1icZRlXpgIZ4mMy3FE7ZH+asIYk9Y=\n`
  - 注意上面包含 3 个换行符 `\n`
  - 此字符串就是被签名的原始文本
- 密文（即签名值）
  - `— sum.golang.org Az3grrJsLRs6sNa2gQWy6G6jb/FLI7opFZErrJT1PWmmP4iUdRxoJhMgfmSkirJgj3zj7n3N61yL16+9521wNu12Sgo=`
  - 此字符串前面一小部分不属于签名（下面会有详解）

#### 公钥的哈希值

实验：对应可运行的实验见 [这里](https://github.com/vikyd/sumdbtest/blob/master/public-key-hash/main.go)。

已知 [Golang sumdb 的公钥](https://github.com/golang/go/blob/master/src/cmd/go/internal/modfetch/key.go#L8) 形式为 `sum.golang.org+033de0ae+Ac4zctda0e5eza+HJyk9SxEdh+s3Ux18htTTAD8OuAn8`，这个字符串看起来也有些怪怪的，不像是纯粹的公钥。

此字符串通过前面 2 个 `+` 分割后得 3 个部分：

- `sum.golang.org`：签发者名称
- `033de0ae`：一个特殊哈希
- `Ac4zctda0e5eza+HJyk9SxEdh+s3Ux18htTTAD8OuAn8`：其中一部分是公钥

下面逐个介绍。

1. 签发者名称：

- 值为：`sum.golang.org`
- 通常是 sumdb 的 URL
- 目前官方只有 1 个 sumdb 签发者

2. `033de0ae`：

- 本质：是一个 SHA-256 值的前 32 bit 的 [大端序](http://www.ruanyifeng.com/blog/2016/11/byte-order.html)（[实验](https://github.com/vikyd/sumdbtest/blob/master/bigendian/main.go)） 数字的十六进制形式（很绕）
- 目的：验证此公钥确实是与该 `签发者名称` 对应
- 此 SHA-256 从哪来？
  - 从这个二进制数据计算而来：`签发者名称` + `\n` + `1` + `公钥`
    - `签发者名称`：如 `sum.golang.org`
    - `\n`：换行符
    - `1`：代表 [Ed25519 加密算法](https://godoc.org/golang.org/x/exp/sumdb/internal/note#hdr-Generating_Keys)，长度为 1 字节（即 8 bit）
    - `公钥`：二进制的公钥数据，长度为 32 字节（即 256 bit）
- SHA-256 值是一个长度固定为 256 bit 的数据，可用一个 8 bit 的数组表示：长度为 32，每项为 8 bit
- 取数组的前 4 项（即前 32 bit），并以大端序解释这 32 bit 数据为一个 uint32 数字
- 最后将这个数字转换为十六进制表示，得到最终的 `033de0ae` （8 个十六进制值）

3. `Ac4zctda0e5eza+HJyk9SxEdh+s3Ux18htTTAD8OuAn8`：

- 这是一个长为 44 的 base64 字符串
- 1 个 base64 为 6 bit（2^6 = 64），则此字符串实质代表长为 264 bit = 6 \* 44 的二进制数据
- 此 264 bit 数据实质由 2 部分组成 264 = 8 + 256
  - 前 8 bit：一个 uint8 的数字，表示签名算法代号，目前主要是 `1`，表示 [Ed25519 加密算法](https://godoc.org/golang.org/x/exp/sumdb/internal/note#hdr-Generating_Keys)
  - 后 256 bit：Ed25519 的公钥

至此，公钥的哈希值计算完毕。

> 注意：本小节并非 Golang 的最终方案，最终方案可能要等到 Go 1.14 出来

参考：

- [package note - GoDoc](https://godoc.org/golang.org/x/exp/sumdb/internal/note)

#### 私钥的哈希值

根据 [此文档](https://godoc.org/golang.org/x/exp/sumdb/internal/note#hdr-Signing_Notes)，私钥的综合格式如下：

```
PRIVATE+KEY+<name>+<hash>+<keydata>
```

举例：

```
PRIVATE+KEY+example.com+1ec6d849+AVIVyAPYK1crY/z8Gcy1HTCIdWyahnbr34X8uITllx6h
```

Golang 并没有求私钥的哈希，而是直接 [借用了](https://github.com/golang/exp/blob/master/sumdb/internal/note/note.go#L380) 公钥的哈希结果（即 `name`、`hash` 是与公钥相同的）。

#### 签名的哈希值

![](https://github.com/vikyd/note-bigfile/raw/master/img/go_mod_security/sign-hash.png)

本小节的可执行实例见 [此程序](https://github.com/vikyd/sumdbtest/blob/master/sign-hash/main.go)。

签名的 `哈希值` 是指下面字符串的后面部分的前 32bit（4 字节）：

```
— sum.golang.org Az3grrJsLRs6sNa2gQWy6G6jb/FLI7opFZErrJT1PWmmP4iUdRxoJhMgfmSkirJgj3zj7n3N61yL16+9521wNu12Sgo=
```

上述字符串来自：<https://sum.golang.org/lookup/github.com/google/uuid@v1.1.1> ， 其值可能有变化，但不影响解析其哈希值。

即下面 base64 字符串转换为二进制后的前 32bit 为哈希值：

```
Az3grrJsLRs6sNa2gQWy6G6jb/FLI7opFZErrJT1PWmmP4iUdRxoJhMgfmSkirJgj3zj7n3N61yL16+9521wNu12Sgo=
```

此哈希值实际上也是 public key 的哈希值，转换为十六进制后均为：`033de0ae`。

也就是说，整个过程中公钥、私钥、签名的前面部分的哈希值均为 `033de0ae`，也即从 sumdb URL + 公钥 计算而得的哈希值。

这也就是说明了为什么不管哪个模块的 `/lookup` 响应，其中的签名的前面几个字符均为 `Az3grr` 了（32 - 5 \* 6 = 2，还剩余 2 bit 与后面的 bit 组合）。

#### Ed25519 了解

[Ed25519](https://blog.csdn.net/u013137970/article/details/84573265) 基于 [椭圆曲线](https://zhuanlan.zhihu.com/p/26029199)、[SHA-512](https://github.com/golang/go/blob/master/src/crypto/ed25519/ed25519.go#L200)，可用于数字签名。

特点：

- 公钥长度：32 字节（即 256 bit）
- 私钥长度：32 字节（即 256 bit）
- 签名长度：64 字节（即 512 bit）

公钥、私有长度的验证可见 [此实验](https://github.com/vikyd/sumdbtest/blob/master/sign-new/main.go)，签名长度的验证可见 [此实验](https://github.com/vikyd/sumdbtest/blob/master/sign-hash/main.go)。

### 根哈希、树大小、模块编号

回头看看 <https://sum.golang.org/lookup/github.com/google/uuid@v1.1.1> 的响应：

```
842
github.com/google/uuid v1.1.1 h1:Gkbcsh/GbpXz7lPftLA3P6TYMwjCLYm83jiFQZF/3gY=
github.com/google/uuid v1.1.1/go.mod h1:TIyPZe4MgqvfeYDBFedMoGGpEw/LqOeaOT+nhxU+yHo=

go.sum database tree
454425
CF4Gdi7ahAx2DQ1icZRlXpgIZ4mMy3FE7ZH+asIYk9Y=

— sum.golang.org Az3grrJsLRs6sNa2gQWy6G6jb/FLI7opFZErrJT1PWmmP4iUdRxoJhMgfmSkirJgj3zj7n3N61yL16+9521wNu12Sgo=
```

里面还有几个信息待解释：

- `842`：模块在树中的编号（准确来说是：模块的综合哈希在树的叶子从左到右的序号，从 0 起算）
- `454425`：树的大小（准确来说是叶子数，不一定是最大树，只要是包含模块哈希的树即可）
- `CF4Gdi7ahAx2DQ1icZRlXpgIZ4mMy3FE7ZH+asIYk9Y=`：叶子数为 `454425` 这棵树的根哈希值

问：`/lookup` 接口返回的这 3 个数据有什么用？

答：前两个数字用于推算待获取的瓦片 URL（瓦片中存储了树节点的哈希值），计算树的根哈希值，并与返回的根哈希值对比，若一致则说明模块没问题，若不一致则说明模块被篡改过。

#### 叶子节点不是模块 zip 哈希值

从 `/lookup` 的响应可知模块有 2 个哈希值（可对应 go.sum 文件中的行）：

```
github.com/google/uuid v1.1.1 h1:Gkbcsh/GbpXz7lPftLA3P6TYMwjCLYm83jiFQZF/3gY=
github.com/google/uuid v1.1.1/go.mod h1:TIyPZe4MgqvfeYDBFedMoGGpEw/LqOeaOT+nhxU+yHo=
```

这 2 个哈希在默克尔树中是作为 2 个？还是 1 个叶子节点？

答：作为 1 个叶子节点。

叶子节点是模块哈希值与 go.mod 哈希值的综合哈希值，其计算方式如下：

1. 拼接字符串：上述两哈希值末尾都加上换行符 `\n`：

```
github.com/google/uuid v1.1.1 h1:Gkbcsh/GbpXz7lPftLA3P6TYMwjCLYm83jiFQZF/3gY=\ngithub.com/google/uuid v1.1.1/go.mod h1:TIyPZe4MgqvfeYDBFedMoGGpEw/LqOeaOT+nhxU+yHo=\n
```

2. 计算此综合字符串的 SHA-256，得：

```
gCGotQKRpCpTloDkBuQHaEaIfNvKFRiwWgilbJLPPm0=
```

3. 验证：获取瓦片接口 https://sum.golang.org/tile/8/0/003 的数据，将其编码为 base64，可发现里面包含上述综合哈希值：`gCGotQKRpCpTloDkBuQHaEaIfNvKFRiwWgilbJLPPm0=`

4. 本计算验证可见 [此实验](https://github.com/vikyd/sumdbtest/blob/master/leaf-module-hash/main.go)

#### 树大小为何经常变化

`/lookup` 接口返回的树大小（即叶子数）的特点：

- 经常会变化（大概 1 小时内会变化几次）
- 每次变化都是变大
- 且通常比 https://sum.golang.org/latest 返回的最新树大小要小一些

原因：

- 根据透明日志的 [性质](https://github.com/vikyd/note/blob/master/translate-transparent_logs_for_skeptical_clients.md#%E6%80%BB%E7%BB%93) 只要树大小比模块的编号大，已足够验证模块哈希是可信的
- 变化的具体规律
  - 没有具体规律，受服务端的缓存的影响
  - 具体原因见 [Golang 官方的回答](https://github.com/golang/go/issues/25530#issuecomment-545851339)，还有 [这里](https://github.com/golang/go/issues/25530#issuecomment-545570569)

### 瓦片 URL 推算

瓦片本质是一堆哈希值，是从默克尔树中按 [一定规则](https://research.swtch.com/tlog#tiling_a_log) 切割出来的。

![](https://raw.githubusercontent.com/vikyd/note/master/img/go_mod_security/whistle-pure-go-get.png)

回顾前面抓包实验的几个抓到的 `/tile` URL：

- https://sum.golang.org/tile/8/0/003
- https://sum.golang.org/tile/8/0/x001/735.p/144
- https://sum.golang.org/tile/8/2/000.p/6
- https://sum.golang.org/tile/8/1/006.p/199
- https://sum.golang.org/tile/8/1/000

依据前面 `/lookup` 接口返回的模块编号、树大小可推算出瓦片的 URL，下面小节将逐一介绍。

#### 瓦片 URL 组成

首先，看看 `/tile` URL 的组成部分。

以 https://sum.golang.org/tile/8/0/003 为例：

- 模式：`/tile/tileHeight/tileLevel/offsetInLevel`
- `8`：瓦片的高度，即 1 个瓦片跨越默克尔树多少个层级
- `0`：瓦片的层级，即切成瓦片后，这些瓦片又组成是一棵树，指此瓦片在瓦片树中的层级（从 0 起算）
- `003`：在瓦片特定层级的偏移量（从 0 起算），`0/003` 表示在瓦片的 0 级的从左数起的第 4 个瓦片

问：为什么瓦片的高度为 `8` ？

答：

- `go` 命令 [默认使用](https://github.com/golang/exp/blob/master/sumdb/internal/sumweb/client.go#L127) 瓦片高度 `8`
- Golang 官方文章 [提及](https://github.com/vikyd/note/blob/master/translate-transparent_logs_for_skeptical_clients.md#%E6%8F%90%E4%BE%9B%E7%93%A6%E7%89%87%E6%9C%8D%E5%8A%A1) 使用 `8`，因为 [存储](https://github.com/vikyd/note/blob/master/translate-transparent_logs_for_skeptical_clients.md#%E5%AD%98%E5%82%A8%E7%93%A6%E7%89%87) 使用了 `4`，而 `4` 是 [兼容](https://github.com/vikyd/note/blob/master/translate-transparent_logs_for_skeptical_clients.md#%E6%8F%90%E4%BE%9B%E7%93%A6%E7%89%87%E6%9C%8D%E5%8A%A1) `8` 高度的

#### 瓦片 URL 特殊规则

对于不完整或瓦片序号大于 [1000](https://github.com/golang/mod/blob/master/sumdb/tlog/tile.go#L168) 的瓦片，其 URL 还有一些特殊规则。

目的：主要是为了方便客户端缓存，[避免同一目录内文件数太多](https://github.com/golang/mod/blob/master/sumdb/tlog/tile.go#L162)。

实例 & 规则：

- https://sum.golang.org/tile/8/1/007.p/12
  - `8`：瓦片高度
  - `1`：表示在第 2 级瓦片层（从 0 起算，所以编号为 `1`）
  - `007`：在第 2 级瓦片层的第 8 个瓦片（从 0 起算，所以编号为 `007`）
  - `.p`：表示此瓦片是不完整的
  - `12`：表示此瓦片的宽度为 `12`（完整瓦片宽：2^8 = 256）
- https://sum.golang.org/tile/8/0/x001/700
  - `x001/700`：表示这是该瓦片层的第 1701 个瓦片（从 0 起算，所以编号为 `1700`）
  - `x`：表示数字大于 1000
- https://sum.golang.org/tile/8/0/x001/804.p/219
  - 本实例是上述两个例子的综合

规则：

- 若瓦片不完整，则最后格式应为 `number.p/tileWidth`
- 瓦片位置的每段若不足 3 位，则前面补零，如 `1` 应表示为 `001`
- 若瓦片在该层级的位置大于 1000，则应被拆分为 `xNumber/number` 的形式，如 12345，应表示为 `x012/345`
- 若瓦片位置比 1000 \* 1000 还大，则除最后一部分，均应加 `x`，如 1234567，应表示为 `x001/x234/567`，如此类推
- 即使树的叶子数已大于瓦片所在位置的叶子，依然可使用不完整瓦片的 URL 形式
  - 完整瓦片：https://sum.golang.org/tile/8/0/003
  - 不完整瓦片：https://sum.golang.org/tile/8/0/003.p/5
- 官方源码参考：https://github.com/golang/mod/blob/master/sumdb/tlog/tile.go#L171

目的：

- 避免 1 个目录内有太多文件，目前限制为最多 1000
  - 如：用了 `8/0/x001/700`，而非 `8/0/1700`
- 避免完整瓦片与不完整瓦片的目录名冲突
  - 如 `8/0/003` 与 `8/0/003.p/5`
  - 若不加 `.p`，则 `003` 目录名会冲突歧义
- 避免大数字前缀与普通小数字目录冲突
  - 如 `8/0/001` 与 `8/0/x001/700`
  - 若不加 `x`，则 `001` 目录名会冲突歧义

实验：

- 打开此目录，观察里面每个子目录的名称：`$GOPATH/pkg/mod/cache/download/sumdb/sum.golang.org/tile/`
  - 可见里面的目录名基本与 URL 中的分段一致
- 也可通过 [此程序](https://github.com/vikyd/sumdbtest/blob/master/calc-level0-tile-url/main.go) 运行验证

#### 推算模块哈希所在瓦片

输入：

- 瓦片高度：`8`
- 模块所在默克尔树叶子的编号（从左开始，从 0 起算）：`842`

推算：

- 因瓦片高度为 `8`（若算上根节点则为 `9`，参考 [此图](https://github.com/vikyd/note/blob/master/translate-transparent_logs_for_skeptical_clients.md#%E5%AF%B9%E6%97%A5%E5%BF%97%E8%BF%9B%E8%A1%8C%E7%93%A6%E7%89%87%E5%8C%96)）
  - 所以按满二叉树计算其叶子节点数为：2^(9 - 1) = 2^8 = 256
  - 即一个标准瓦片包含 256 个长为 256bit 的 SHA-256 哈希值
- 所以模块编号 `842` / `256` = 3 余 74
- 所以模块在第 4 块瓦片中，从 0 起算的话，瓦片编号为 3，也即 https://sum.golang.org/tile/8/0/003

上述推算验证可见 [此实验](https://github.com/vikyd/sumdbtest/blob/master/calc-level0-tile-url/main.go) 。

#### 推算叶子层最右侧瓦片

输入：

- URL：<https://sum.golang.org/lookup/github.com/google/uuid@v1.1.1>
- 瓦片高度：`8`
- 树的叶子数：`469237`（叶子数随时变化，这里只是举个例子）

推算：

- 根据前面可知瓦片宽为 256 个哈希
- 所以 469237 / 256 = 1832 余 245
- 所以叶子层最右侧瓦片为：https://sum.golang.orgtile/8/0/x001/832.p/245

上述推算验证可见 [此实验](https://github.com/vikyd/sumdbtest/blob/master/calc-level0-tile-url/main.go) 。

#### 推算其他层的瓦片

由于计算树的根哈希还需不同层的节点哈希值，所以还需获取不同层的瓦片。

推算所需的其他层瓦片，逻辑相对复杂。

若需了解，可参考以下官方源码：

- [ReadHashes( )](https://github.com/golang/mod/blob/master/sumdb/tlog/tile.go#L302)

### 验证模块哈希可信

验证模块哈希可信的详细逻辑也相对复杂。

但具体步骤大致为：

- 获取各层所需的瓦片（瓦片内包含了模块哈希）
- 根据模块哈希、各层哈希计算出根哈希
- 对比 `/lookup` 得到的根哈希，与计算得到的根哈希对比
  - 一致：则验证成功，模块哈希是可信的
  - 不一致：验证失败，模块内容可能被篡改过

具体逻辑可参考：

- [官方源码 checkRecord( )](https://github.com/golang/exp/blob/master/sumdb/internal/sumweb/client.go#L296)
- Golang 官方验证模块安全的独立工具 gosumcheck
  - [这里](https://blog.golang.org/module-mirror-launch) 搜索 `gosumcheck`

> 全程无需 `/latest` 接口

## 接口：`/tile/tileHeight/tileLevel/offsetInLevel` 哈希值完整瓦片

用途：获取宽度完整的瓦片（目前默认宽度：256）

实例：https://sum.golang.org/tile/8/0/003

响应实例：

```
���n�8�t��Ybs���U�|J�w��mkp"�j{��l~�}3���Y���v�4<��Z�i�8��,>&W�߼��|��o:eg�����/Ft'�|٩|=��z�؏��Ǒ�Y
�Q��s����L�ȿ@Ӓn,�A[R�{���,�b��5
���ا�\�������X��P�Y	�=㚊��e$��p)
......
```

这些乱码实质是：

- 一堆 SHA-256 的二进制值
- 此响应的大小为 8192 字节

  - 1 个 SHA-256 大小为 256 bit（即 32 字节）
  - 所以此响应包含 8192 / 32 = 256 个
  - 也即刚好是一个瓦片的宽度：256

- [此实验](https://github.com/vikyd/sumdbtest/blob/master/tile-data/main.go) 可将响应内容打印成 base64 形式
- [此实验](https://github.com/vikyd/sumdbtest/blob/master/leaf-module-hash/main.go) 可验证瓦片的这些二进制内容确实是 SHA-256 哈希值

## 接口：`/tile/tileHeight/tileLevel/offsetInLevel.p/tileWidth` 哈希值不完整瓦片

用途：获取宽度不完整的瓦片（目前默认宽度：256，即宽度 < 256 的瓦片）

实例：https://sum.golang.org/tile/8/0/x001/775.p/25

- 此瓦片宽度为 URL 最后数字：25

响应实例：

```
�/����x�U04<0���M���c.��p��\vW|��n5_K���Kv�$��^l�?2O�&���^?Y��N��W@���쨇﨟m9��5?�e(_�QE>@H|�[�����fGL���cO�Z#��-
P��`��x�����z�e��:��m�Q<�ݕ�~�$���l�]�o�m�;(�4��$f^�H;�.��r|-�Ѐ�p'{��%Ϥ^�b7
Z�
s�5վ|-�d��qP�z[
......
```

这些乱码实质是：

- 一堆 SHA-256 的二进制值
- 此响应的大小为 800 字节
  - 1 个 SHA-256 大小为 256 bit（即 32 字节）
  - 所以此响应包含 800 / 32 = 25 个
  - 也即刚好是此瓦片的宽度：25

## 接口：`/tile/tileHeight/data/offsetInLevel0` 叶子完整瓦片对应模块哈希

用途：获取叶子层完整瓦片里的 SHA-256 哈希值对应的模块哈希值。

实例：https://sum.golang.org/tile/8/data/003

- 此实例对应的瓦片地址：https://sum.golang.org/tile/8/0/003

响应实例：

```
......
github.com/google/uuid v1.1.1 h1:Gkbcsh/GbpXz7lPftLA3P6TYMwjCLYm83jiFQZF/3gY=
github.com/google/uuid v1.1.1/go.mod h1:TIyPZe4MgqvfeYDBFedMoGGpEw/LqOeaOT+nhxU+yHo=

github.com/opentracing-contrib/go-stdlib v0.0.0-20171029140428-b1a47cfbdd75 h1:EIdPB7oNWEV0cOQ7eIrdyKQfEV5XxO/fB/GrEQIk7J0=
github.com/opentracing-contrib/go-stdlib v0.0.0-20171029140428-b1a47cfbdd75/go.mod h1:PLldrQSroqzH70Xl+1DQcGnefIbqsKR7UDaiux3zV+w=

github.com/googleapis/gnostic v0.2.0 h1:l6N3VoaVzTncYYW+9yOz2LJJammFZGBO13sqgEhpy9g=
github.com/googleapis/gnostic v0.2.0/go.mod h1:sJBsCZ4ayReDTBIg8b9dl28c5xFWyhBTVRp3pOg5EKY=
......
```

注意，https://sum.golang.org/tile/8/data/003 中的哈希综合值，才是瓦片 https://sum.golang.org/tile/8/0/003 中的 SHA-256 哈希值。

也即对此字符串求得的 SHA-256 才是瓦片 https://sum.golang.org/tile/8/0/003 里的其中一个哈希值：

```
github.com/google/uuid v1.1.1 h1:Gkbcsh/GbpXz7lPftLA3P6TYMwjCLYm83jiFQZF/3gY=\ngithub.com/google/uuid v1.1.1/go.mod h1:TIyPZe4MgqvfeYDBFedMoGGpEw/LqOeaOT+nhxU+yHo=\n
```

可通过 [此实验](https://github.com/vikyd/sumdbtest/blob/master/leaf-module-hash/main.go) 进行验证。

## 接口：`/tile/tileHeight/data/offsetInLevel0.p/tileWidth` 叶子不完整瓦片对应模块哈希

用途：获取叶子层不完整瓦片里的 SHA-256 哈希值对应的模块哈希值。

实例：https://sum.golang.org/tile/8/data/x001/775.p/25

- 此实例对应的瓦片地址：https://sum.golang.org/tile/8/0/x001/775.p/25

响应实例：

```
......
github.com/vuleetu/logrus v0.6.3-0.20150109081124-d32e3e5b84eb h1:gRxKL3QhKYgvn1nW20KhAGJX9UZgnu+nPFw/Hyc3nZY=
github.com/vuleetu/logrus v0.6.3-0.20150109081124-d32e3e5b84eb/go.mod h1:7oU26alNpbgiEqoSssDQu19SUZWVol3YEi3QpObxYlg=

github.com/xiaost/redisgo v0.0.0-20190222081556-5843ce6d9264 h1:HrZQR/+gjy/ej224rg6CVipKKGc/ZTho8cEvPi6QMeY=
github.com/xiaost/redisgo v0.0.0-20190222081556-5843ce6d9264/go.mod h1:TrrOkpxOZMl3uW6c6P0YPuq5/HnA/9ipUcqOgonWmck=

github.com/runner-mei/zip v0.0.0-20190614074322-c80fd4edb7a7 h1:5GODI8ARDONLc6QO83cU5nyiW86LpvhGvsLS3i2l0Ck=
github.com/runner-mei/zip v0.0.0-20190614074322-c80fd4edb7a7/go.mod h1:jH6zGYHOCoic0MOlTHC0lWE4pABYRty5Ejlyyzq96uI=
......
```

## 接口：`/latest` 最新根哈希

用途：获取 sumdb 默克尔树的最新根哈希值。

实例：https://sum.golang.org/latest

响应实例：

```
go.sum database tree
454425
CF4Gdi7ahAx2DQ1icZRlXpgIZ4mMy3FE7ZH+asIYk9Y=

— sum.golang.org Az3grrJsLRs6sNa2gQWy6G6jb/FLI7opFZErrJT1PWmmP4iUdRxoJhMgfmSkirJgj3zj7n3N61yL16+9521wNu12Sgo=
```

备注：

- 此接口与 <https://sum.golang.org/lookup/github.com/google/uuid@v1.1.1> 中的后半部分一样（不一样在于树的大小及对应的根哈希）
  - 不一致的原因：
    - `/lookup` 接口的树大小不必为最新树大小，只需包含模块哈希节点即可
    - 目前 `sum.golang.org` 官方服务有对 `/lookup` 进行 [缓存](https://github.com/golang/go/issues/25530#issuecomment-545851339)

## 第三方 sumdb

第三方 sumdb 与 Golang 官方的 sumdb 是相互独立的，其中数据互不干扰。

目前已搜索到的第三方 sumdb 有：

- https://gosum.io

Golang 官方认为：

- 目前 [官方只有 1 个 sumdb](https://github.com/vikyd/note/blob/master/secure_the_public_go_module_ecosystem.md#%E5%AE%89%E5%85%A8)（里面搜索 `多个数据库`）（`sum.golang.org`），且也足够简单、安全
  - Golang 内置的 `sum.golang.google.cn` 实质也是 [指向](https://github.com/golang/go/blob/master/src/cmd/go/internal/modfetch/sumdb.go#L70) `sum.golang.org`
- 未来可以有多个 sumdb
- sumdb 可被代理，且即使被代理，也不会影响安全
  - 支持代理 sumdb 的模块代理：
    - 七牛云：<https://goproxy.cn/sumdb/sum.golang.org/lookup/github.com/google/uuid@v1.1.1>
    - `goproxy.io`：<https://goproxy.io/sumdb/sum.golang.org/lookup/github.com/google/uuid@v1.1.1>
  - 不支持代理 sumdb 的模块代理：
    - 腾讯云：<https://mirrors.tencent.com/go/sumdb/sum.golang.org/lookup/github.com/google/uuid@v1.1.1>
    - 阿里云：<https://mirrors.aliyun.com/goproxy/sumdb/sum.golang.org/lookup/github.com/google/uuid@v1.1.1>

虽然 Golang 的 GOSUMDB 支持配置为第三方的 sumdb，但目前来看并不建议使用第三方的 sumdb。原因：官方的 sum.golang.org 足够使用，且未发现高可用、速度快的第三方 sumdb。

## `sum.golang.org` 网站是否开源？

答：不开源。[This code is all pretty Google-specific, so it's not open source](https://github.com/golang/go/issues/25530#issuecomment-545851339)。

不过，[这里](https://github.com/golang/mod/blob/master/sumdb/server.go) 可以看到部分逻辑。

[据说](https://research.swtch.com/tlog#further_reading)（里面搜索 `trillian`）用到了 Google 的开源项目 [Trillian](https://github.com/google/trillian)。但此项目的文档并不好操作，所以可参考 [这篇文章](https://medium.com/google-cloud/google-trillian-for-noobs-9b81547e9c4a) 来跑起一个简单的透明日志服务（此篇文章的一些坑可参考 [这里](https://github.com/vikyd/note/blob/master/trillian_docker_issues.md)）。

# 分析 `index.golang.org`

`index.golang.org`：获取已被 `sum.golang.org` 记录的模块信息列表。

## 接口：`/index`

用途：获取已被 `sum.golang.org` 记录的模块信息列表。

> 普通开发者基本不会用到此服务

实例：

- https://index.golang.org/index
  - 默认返回最早记录进 sumdb 的 2000 个（默认）模块信息
- https://index.golang.org/index?limit=10
  - 返回 10 个
- https://index.golang.org/index?since=2019-04-11T18:51:37.123456Z
  - 返回从 2019-04-11T18:51:37.123456Z 开始的 2000 个
- https://index.golang.org/index?since=2019-04-11T18:51:37.123456Z&limit=10
  - 返回从 2019-04-11T18:51:37.123456Z 开始的 10 个

响应实例：

> 下面响应来自 https://index.golang.org/index 的一部分

```
{"Path":"github.com/google/uuid","Version":"v1.1.1","Timestamp":"2019-04-11T18:51:37.508535Z"}
{"Path":"github.com/googleapis/gnostic","Version":"v0.2.0","Timestamp":"2019-04-11T18:51:37.646782Z"}
{"Path":"github.com/opentracing-contrib/go-stdlib","Version":"v0.0.0-20171029140428-b1a47cfbdd75","Timestamp":"2019-04-11T18:51:37.725626Z"}
{"Path":"github.com/coreos/go-systemd","Version":"v0.0.0-20190212144455-93d5ec2c7f76","Timestamp":"2019-04-11T18:51:38.102166Z"}
```

备注：

- 字段解释：
  - `Path`：模块路径
  - `Version`：模块版本号
  - `Timestamp`：记录进 sumdb（即 sum.golang.org）的时间
    - 注意：不是模块版本的 git commit 时间（vs 来自代理服务的 `/modulePath/@v/version.info`）
- 一个模块什么时候会记录进 sumdb ？
  - 第一个用户向 sumdb 查询模块版本时（如 go get 时向 `/lookup` 请求），sumdb 会去对应源码网站抓取，这个时间会记录到 sumdb
- 返回的列表顺序：按时间升序
- 貌似没找到哪个第三方代理用到了 `index.golang.org`
  - [goproxy GitHub 源码搜索](https://github.com/goproxy/goproxy/search?q=index&unscoped_q=index)
  - [goproxy.cn GitHub 源码搜索](https://github.com/goproxy/goproxy.cn/search?q=index&unscoped_q=index)
  - [goproxy.io GitHub 源码搜索](https://github.com/goproxyio/goproxy/search?q=index&unscoped_q=index)

下图来自 [这里](https://blog.golang.org/modules2019/code.png?ynotemdtimestamp=1573522277663)：
![](https://blog.golang.org/modules2019/code.png?ynotemdtimestamp=1573522277663)

# GOPROXY、GOSUMDB、GOPRIVATE 等的用法

## GO111MODULE

### 可选值

- 留空，如 `export GO111MODULE=`
  - 与 `auto` 的效果一致
- `on`
- `off`
- `auto`

### 值解释

在不同的 go 版本、不同的目录中，`GO111MODULE` 的作用有些不一样：

- `auto`
  - go < 1.13
    - 当前目录或父辈目录有 `go.mod` 文件，且目录在 `$GOPATH/src` 外：才使用 module 模式
  - go >= 1.13
    - 当前目录或父辈目录有 `go.mod` 文件，即使目录在 `$GOPATH/src` 内：都使用 module 模式
- `on`
  - 不管什么时候，都使用 module 模式
- `off`
  - 不管什么时候，都不使用 module 模式

官方参考：https://github.com/golang/go/issues/31857#issue-440694837

### 注意

Golang 从 [1.13](https://golang.org/doc/go1.13#modules) 开始默认开启 `GO111MODULE`（即 `GO111MODULE=auto`），有一些默认行为的改变：

- 模块源码下载方式的改变
  - 原来：直接从源码仓库（如 github.com）获取
  - 变为：从 Golang 官方提供的模块代理 proxy.golang.org 中获取
    - 会导致获取不了公司内网的模块（因为 proxy.golang.org 访问不了内网，需设置 `GOPRIVATE=内网源码地址` 才能不使用代理）
    - 且会从 sum.golang.org 下载模块验证信息并验证
- 下载模块源码存放位置的改变
  - 原来：`$GOPATH/src`
  - 变为 `$GOPATH/pkg/mod`
    - 此时 `$GOPATH/pkg/mod` 与 `$GOPATH/src` 互不相关

> [参考](https://github.com/golang/go/wiki/Modules#recent-changes)

此时 `GOPROXY`、`GOSUMDB`、`GOPRIVATE`、`GONOPROXY`、`GONOSUMDB` 等环境变量可对上述行为作修改。

执行以下命令，可查看当前环境这些变量的值：

```sh
go env
```

为避免踩太多坑，下面将逐一聊下这些变量。

## GOPROXY

- 用途：提供代理获取 Golang 模块源码的功能。
- 优缺点：见前面的 `proxy.golang.org` 一节
- 默认值：`proxy.golang.org,direct` （[参考](https://github.com/golang/go/blob/master/src/cmd/go/internal/cfg/cfg.go#L248)）
- 格式（[参考](https://github.com/golang/go/blob/master/src/cmd/go/internal/modfetch/proxy.go#L113)）：`<proxyURL01>,<proxyURL02>,direct` 或 [off](https://golang.org/doc/go1.13#modules)
  - 允许以英文逗号 `,` 分隔设置多个代理地址，多个地址中，优先从第 1 个代理开始获取模块源码，若失败则尝试后面的地址
  - `direct`：表示不使用代理，直接从源码仓库获取
  - `proxy.golang.org,direct`：表示优先从 `proxy.golang.org` 获取，若失败，则直接从源码仓库获取（`direct`）
  - `off`：表示一开始就不从任何代理下载模块，只从模块本身源码网站下载
- 第三方可用代理：见前面 `第三方代理` 一节

## GOSUMDB

- 用途：提供模块源码的哈希值，以及哈希值是否可信的相关验证信息
- 优缺点：见前面的 `sum.golang.org` 一节
- 默认值：`sum.golang.org`（[参考](https://github.com/golang/go/blob/master/src/cmd/go/internal/cfg/cfg.go#L249)）
- 实例：
  - `GOSUMDB=sum.golang.org+033de0ae+Ac4zctda0e5eza+HJyk9SxEdh+s3Ux18htTTAD8OuAn8`（Golang 官方 [内置](https://github.com/golang/go/blob/master/src/cmd/go/internal/modfetch/key.go#L8)）
  - `GOSUMDB=gosum.io+ce6e7565+AY5qEHUk/qmHc5btzW45JVoENfazw8LielDsaI+lEbq6`（来自 [goproxy.io](https://gosum.io/)）
- 格式（[参考](https://golang.org/cmd/go/#hdr-Module_authentication_failures)）：`<name>+<hash>+<keydata> [URL]`（URL 可选） 或 `off`
  - 用于指定 1 个 sumdb
  - 默认值 `sum.golang.org` 省略了 `+<hash>+<keydata>`，这是因为 Golang 内部对其进行了 [特殊处理](https://github.com/golang/go/blob/master/src/cmd/go/internal/modfetch/key.go#L8)
  - `off`：表示不使用 sumdb，并只验证 go.sum 中的哈希值（若有 go.sum 文件的话）
- 特殊情况：
  - 可以填值为 `sum.golang.google.cn`
  - 这是 Golang 官方 [为国内专供](https://github.com/golang/go/blob/master/src/cmd/go/internal/modfetch/sumdb.go#L69) 的免翻墙别名
  - 一般不建议填此值
- 建议：不要修改 GOSUMDB（原因见后面 `最佳实践`）
- 第三方 sumdb：见前面 `第三方 sumdb` 一节

## GOPRIVATE

- 用途：用于指明哪些模块属于私有模块（如公司内部的、非外网可获取的）
  - 私有模块表示通常（不是绝对）无需走模块代理、无需去 sumdb 检查模块哈希值
- 默认值：空
- 实例：`export GOPRIVATE=公司源码网站URL`
- 格式：见后面 `公共特点` 一节
- 查看帮助：`go help module-private`
- 特性：
  - 若 `GONOPROXY`、`GONOSUMDB` 未被用户主动设置值时，`GOPRIVATE` 设置值后，会被作为 `GONOPROXY`、`GONOSUMDB` 的 [默认值](https://github.com/golang/go/blob/master/src/cmd/go/internal/cfg/cfg.go#L251)
  - 反过来说，若 `GONOPROXY`、`GONOSUMDB` 已被用户主动设置过值，则 `GOPRIVATE` 不会对那两个变量有任何影响（如：不会取 `GOPRIVATE` 与 `GONOPROXY` 的并集）

## GONOPROXY

- 用途：用于指明哪些模块无需从代理下载（即应直接从模块源码网站下载）
- 默认值：空
- 实例：`export GONOPROXY=公司源码网站URL`
- 格式：见后面 `公共特点` 一节

## GONOSUMDB

- 用途：用于指明哪些模块无需去 sumdb 查询、验证模块哈希值
- 默认值：空
- 实例：`export GONOSUMDB=公司源码网站URL`
- 格式：见后面 `公共特点` 一节

## GOPRIVATE、GONOPROXY、GONOSUMDB 的公共特点

- 值的格式一致
  - 实例
    - `*.corp.example.com,rsc.io/private`
  - 格式：
    - 允许多个值，用英文逗号分隔 `,`
    - 每个值均为模块路径
    - 支持 [glob](http://www.ruanyifeng.com/blog/2018/09/bash-wildcards.html) 匹配模式
  - 特殊注意：
    - `*.corp.example.com`：包含 `a.corp.example.com`、`b.corp.example.com`、`c.corp.example.com/xyz` 等，但不包含 `corp.example.com`
    - `rsc.io/private`：包含 `rsc.io/private/abc` 等，但不包含 `rsc.io/privateabc`
- 都是指定模块路径，而非服务地址
- [官方参考](https://godoc.org/github.com/golang/go/src/cmd/go#hdr-Module_configuration_for_non_public_modules)

## 修改这些值的方式

上述变量值的修改方式有 2 种：

- 修改系统环境变量
- 通过 `go env -w VarName=value` 的形式修改

具体特点：

- 不管哪种方式，都是 `key=value` 的形式
- `go env -w` 的方式默认会存储到 `GOENV` 所指向的文件，以下是默认位置：
  - Linux：`~/.config/go/env`
  - Mac：`~/Library/Application Support/go/env`
  - Win：`%HOMEPATH%\AppData\Roaming\go\env`
- 若同时设置了环境变量、`go env -w`，则以环境变量为准
- 查看当前这些变量值：`go env`

## 几种组合方式的含义

假设有 3 个源码网站（`a.com`、`b.com`、`c.com`）可下载 Golang 模块。

### 全部默认

什么都不设置，全部默认：

- 所有模块
  - √ 从 proxy 下载
  - √ 从 sumdb 验证哈希值

### 仅设置 GOPRIVATE

`GOPRIVATE=a.com`：

- `a.com` 的模块
  - × 从 proxy 下载
  - × 从 sumdb 验证哈希值
- 其他的模块
  - √ 从 proxy 下载
  - √ 从 sumdb 验证哈希值

说明：`GOPRIVATE` 设置值后，`GONOPROXY` 与 `GONOSUMDB` 的值也自动与 `GOPRIVATE` 的一致

### GOPRIVATE + GONOPROXY

`GOPRIVATE=a.com` + `GONOPROXY=b.com`：

- `a.com` 的模块
  - √ 从 proxy 下载
  - × 从 sumdb 验证哈希值
- `b.com` 的模块
  - × 从 proxy 下载
  - √ 从 sumdb 验证哈希值
- `c.com` 的模块
  - √ 从 proxy 下载
  - √ 从 sumdb 验证哈希值

说明：`GONOPROXY` 设置值后会覆盖 `GOPRIVATE` 的效果（即并不会与 `GOPRIVATE` 取并集）

### GOPRIVATE + GONOSUMDB

`GOPRIVATE=a.com` + `GONOSUMDB=b.com`：

- `a.com` 的模块
  - × 从 proxy 下载
  - √ 从 sumdb 验证哈希值
- `b.com` 的模块
  - √ 从 proxy 下载
  - × 从 sumdb 验证哈希值
- `c.com` 的模块
  - √ 从 proxy 下载
  - √ 从 sumdb 验证哈希值

说明：`GONOSUMDB` 设置值后会覆盖 `GOPRIVATE` 的效果（即并不会与 `GOPRIVATE` 取并集）

### GOPRIVATE + GONOPROXY + GONOSUMDB

`GOPRIVATE=a.com` + `GONOPROXY=b.com` + `GONOSUMDB=c.com`：

- `a.com` 的模块
  - √ 从 proxy 下载
  - √ 从 sumdb 验证哈希值
- `b.com` 的模块
  - × 从 proxy 下载
  - √ 从 sumdb 验证哈希值
- `c.com` 的模块
  - √ 从 proxy 下载
  - × 去 sumdb 验证哈希值

### GONOPROXY + GONOSUMDB

`GONOPROXY=a.com` + `GONOSUMDB=a.com`：

- `a.com` 的模块
  - × 从 proxy 下载
  - × 从 sumdb 验证哈希值
- 其他的模块
  - √ 从 proxy 下载
  - √ 从 sumdb 验证哈希值

说明：GONOPROXY、GONOSUMDB 设置相同值时，效果与只设置 GOPRIVATE 一致。

## 推荐配置

最佳实践不止与用户的设置相关，且与公司是否有对应服务相关。

考虑的要点：

- 私有模块路径是否被泄露到外网
- 模块的下载速度
- 是否能翻墙
- 模块代理是否能下载到原始代码网站的代码
- 模块代理是否也能同时代理 sumdb

下面将描述不同情况下的最佳实践。

### 公司有模块代理且代理了 sumdb

此时的最佳实践：

- 只设置 `export GOPROXY=公司的模块代理服务,direct`

原因：

- 公司的这个模块代理服务应能自动判断哪些是私有模块
  - 对于私有模块不去外网下载、也不去 sumdb 验证模块哈希
  - 从而避免了私有模块路径泄露，模块下载速度也能由公司内的代理服务统一提供保证
- 代理 sumdb 时也应能自动判断哪些路径是私有模块
  - Go 会优先考虑使用代理服务中的 sumdb 代理，其次才考虑直连官方的 sum.golang.org

### 公司有模块代理但没代理 sumdb

此时用户可能需要多做一些设置。

此时的最佳实践：

- `export GOPROXY=公司的模块代理服务,direct`
- `export GOPRIVATE=私有模块地址`

原因：

- 此时公司的模块代理估计不会自动判断哪些是私有模块
- 所以需要设置 GOPRIVATE
- 依然使用公司的模块代理服务，是因为估计其速度会快一些

### 公司无模块代理也无代理 sumdb

此时的最佳实践：

- `export GOPRIVATE=私有模块地址`

原因：

- 比同时设置 `GONOPROXY`、`GONOSUMDB` 节省一步

> 这里默认公司能翻墙（即能访问 proxy.golang.org、sum.golang.org）

### 在家里

此时的最佳实践：

- 若有翻墙条件：
  - 则一切按默认，不修改
  - 前提是你的翻墙速度足够快
- 若无翻墙条件：
  - `export GOPROXY=https://goproxy.cn,direct`

原因：

- 此时默认没有私有模块（若真有，建议设置具体的模块路径，而非整个源码网站）
- goproxy.cn 速度比较快，代理模块下载，同时也代理 sumdb，用户只需设置 GOPROXY，即可同时享受 proxy、sumdb

# 未解的疑问

- 按照目前 Golang module 的 GOSUMDB 机制，是否会存在大量 sum 填充攻击？
  - 即大量请求，并导致 gosumdb 内产生太多无用的 hash，导致 gosumdb 性能下降？
- 为什么 sumdb 不包含版本列表接口？而由 proxy 提供？
- 官方的 `sum.golang.org` 一旦挂机，是否全网都不能去验证未曾记录在 `sum.golang.org` 的新模块版本了？
  - 除非第三方的 sumdb 已记录过这些模块版本？
- sumdb 中的根哈希签名为什么可允许多个 server ？
- sumdb 的公钥的哈希值
  - 为什么只取其 SHA-256（256 bit）的前 32 bit 作为返回（`/lookup`、`/latest`）？
    - [来源 01](https://github.com/golang/mod/blob/master/sumdb/note/note.go#L231)、[来源 02](https://godoc.org/golang.org/x/mod/sumdb/note)
  - 为什么使用大端序？

# 总结

因 Go 1.13 开始默认启用 Golang Modules，并默认使用 `proxy.golang.org`、`sum.golang.org`，导致了开发者会踩一些新的坑。所以，本文介绍了 Golang Modules 一些相关的细节：

- 介绍了 `GOPROXY`、`GOSUMDB`、`GOPRIVATE` 等的用法
- 介绍了背后的服务 `proxy.golang.org`、`sum.golang.org`、`index.golang.org` 的各个接口
- 提供了验证上述服务接口工作原理的一些 [可运行的实验](https://github.com/vikyd/sumdbtest)

> 本文未提及关于 go mod 相关命令的使用细节，因这是另一个大话题

以下是一些个人结论：

- Golang 的模块代理机制有点意思，有正交的味道
- Golang 的 sumdb 验证模块正确性的机制，有种区块链的味道

总的来说，Golang 的包管理器机制虽颇具争议，但其中也有一些有意思的、值得去了解的创新点。

> 本文写于 Go 1.13 发布后，1.14 发布前，而 [Golang 计划在 1.14 版本才最终确定 Modules 的定稿](https://github.com/golang/go/wiki/Modules#go-111-modules)。

# 参考

主要参考：

- [【译】为持怀疑态度的客户端设计的透明日志（Transparent Logs for Skeptical Clients）](https://github.com/vikyd/note/blob/master/translate-transparent_logs_for_skeptical_clients.md)
- [【译】提案：为 Go 语言的公共模块生态建立安全机制（Proposal：Secure the Public Go Module Ecosystem）](https://github.com/vikyd/note/blob/master/secure_the_public_go_module_ecosystem.md)
- [GopherCon 2019 - Go Module Proxy: Life of a query](https://about.sourcegraph.com/go/gophercon-2019-go-module-proxy-life-of-a-query)
- [【译】我们的软件依赖问题（Our Software Dependency Problem）](https://github.com/vikyd/note/blob/master/our_software_dependency_problem.md)

其他参考：

- [干货满满的 Go Modules 和 goproxy.cn](https://github.com/guanhui07/blog/issues/642)
- [数字签名是什么？](http://www.ruanyifeng.com/blog/2011/08/what_is_a_digital_signature.html)
- [理解以太坊的椭圆曲线签名](https://www.jianshu.com/p/d622e1ec9470)
- [椭圆曲线加解密及签名算法的技术原理](https://blog.51cto.com/11821908/2057726)

> 文章较啰嗦，难免有错，若有发现，请告诉一声
