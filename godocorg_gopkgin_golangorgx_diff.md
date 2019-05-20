# godoc.org 和 gopkg.in 和 golang.org/x 是什么

# 概述

Golang 编程中，经常会碰到这几个网站：

- https://godoc.org

- https://gopkg.in

- https://golang.org/x

容易迷惑：

- 这些网站是做什么用的？
- 我的项目能不能也放上去？

# 示例

如无特殊，均以下面最简单项目作为实例：

- https://github.com/vikyd/gopkg-test

- https://github.com/vikyd/gopkg-test-use

- https://github.com/vikyd/goget-test

# 总的来说

- [gopkg.in](https://gopkg.in)： go get 指定源码版本的转发服务（非 Golang 官方）
- [godoc.org](https://godoc.org)： 任意 go 项目的文档托管服务（Golang 官方）
- [golang.org/x](https://golang.org/x)： Golang 官方的部分工具项目（Golang 官方）

# 前提知识点

- [HTTP 消息结构](https://www.runoob.com/http/http-messages.html)
- Golang 的 [go-import](https://golang.org/cmd/go/#hdr-Remote_import_paths) 数据

  > 页面内搜索 `go-import`

- Golang 如何从代码中 [生成文档](https://blog.golang.org/godoc-documenting-go-code)？

- （可选）HTTPS 抓包工具
  - Mac 下的 [Charles](https://www.charlesproxy.com/)
  - Win 下的 [Fiddler](https://www.telerik.com/fiddler)

# 名词约定

- `gopkg.in` 指网站 https://gopkg.in/ ，后简称 `gopkg`
- `GoDoc` 指网站 https://godoc.org/
- `godoc` 指 Golang 的 [godoc 工具](https://golang.org/cmd/godoc/)

# gopkg.in 简述

官网：https://gopkg.in

> 会自动重定向到：http://labix.org/gopkg.in

gopkg.in 是一个用于为 go get 提供版本语义的转发服务。

如：

```sh
go get gopkg.in/vikyd/gopkg-test.v2
```

就能获取到 https://github.com/vikyd/gopkg-test 的 [tag=v2](https://github.com/vikyd/gopkg-test/tree/v2) 的代码了。

若是单纯的 go get GitHub 是获取不到 v2 这个 tag 的代码的：

```sh
go get https://github.com/vikyd/gopkg-test
```

简单说：

- 能让你在 go get 时获取不同的 tag 或 branch
  > 当然，go 引用时的路径也要带上版本号，如 `import "gopkg.in/vikyd/gopkg-test.v2"`
- 你无需对你 GitHub 上的 golang 项目做任何改动
- 你无需在 gopkg.in 做任何设置（无需注册、配置、点击）
- 一切都是 gopkg.in 自动识别
  > 实际 gopkg.in 网站的全部源码 [很少](https://github.com/niemeyer/gopkg)
- 目前仅支持 GitHub
- `gopkg.in` 不是 Golang 官方的

# golang.org/x 简述

官网：https://golang.org/x

> 会自动重定向到：https://godoc.org/-/subrepo

> 注意是 `golang.org/x`，不是 `golang.org`

`golang.org/x` 是：

- Golang [官方项目的一部分](https://github.com/golang/go/wiki/SubRepositories)
- 提供 go-import 的元数据信息，实际源码位于 https://go.googlesource.com
- 区别于 GitHub：
  - `GitHub` 的 go-import 同样指向 GitHub
  - `golang.org/x` 的 go-import 指向了另一个网站 https://go.googlesource.com
- 区别于 gopkg.in：
  - `gopkg.in` 除了提供 go-import 信息，还完全提供转发 git clone GitHub 的功能
  - `golang.org/x` 仅提供 go-import 信息，剩下就是 https://go.googlesource.com 的事了

# godoc.org 简述

官网：https://godoc.org

是文档托管服务，能自动分析 GitHub 等网站中的源码注释，自动生成在线文档。

- 支持多个网站：[GitHub](https://github.com/)、[Bitbucket](https://bitbucket.org/)、[Launchpad](https://launchpad.net/)、[Google Project Hosting](https://code.google.com/hosting/)
- 你无需对你 GitHub 等的 golang 项目做任何改动
- 无需注册、登录、设置
- 只需：在 https://godoc.org/ 中搜索你想要的项目即可
  - 若 GoDoc 上已有该项目的文档，则直接显示文档
  - 若未有，则 GoDoc 会自动拉起 GitHub 等上拉起源码，并生成 godoc 文档
- GoDoc 是 Golang [官方的网站](https://github.com/golang/gddo)

---

# 后面将详解每个服务的细节

# gopkg.in 详述

先说具体流程，最后再说优缺点。

## gopkg.in 的具体流程

### 简单版

当你执行此命令 `go get gopkg.in/vikyd/gopkg-test.v2` 时，实际会发生：

- 先向 gopkg.in 进行 HTTPS GET，获得 go-import 信息，即获得了源码位置
- 再向 gopkg.in 进行 git clone
  > 没错，gopkg.in 连源码也转发了。。。
- go get 成功，存在本地目录：`$GOPATH/src/gopkg.in/vikyd/gopkg-test.v2`

### 详细版

详细版包含抓包过程，内容较长。

- 执行：`go get gopkg.in/vikyd/gopkg-test.v2`
  > 全程只需执行这 1 条命令，后面都是抓包得知的过程
- 本地向 gopkg.in 发出 HTTPS GET 请求：
- URL：https://gopkg.in/vikyd/gopkg-test.v2?go-get=1
- 请求：

```
:authority: gopkg.in
:method: GET
:path: /vikyd/gopkg-test.v2?go-get=1
:scheme: https
accept-encoding: gzip
user-agent: Go-http-client/2.0
Pragma: no-cache
Cache-Control: no-cache
```

- 响应

```
:status: 200
content-type: text/html
content-length: 366
date: Sat, 18 May 2019 09:23:24 GMT
Expires: 0
Cache-Control: no-cache


<html>
<head>
<meta name="go-import" content="gopkg.in/vikyd/gopkg-test.v2 git https://gopkg.in/vikyd/gopkg-test.v2">
<meta name="go-source" content="gopkg.in/vikyd/gopkg-test.v2 _ https://github.com/vikyd/gopkg-test/tree/v2{/dir} https://github.com/vikyd/gopkg-test/blob/v2{/dir}/{file}#L{line}">
</head>
<body>
go get gopkg.in/vikyd/gopkg-test.v2
</body>
</html>
```

- 从响应得到的 go-import 信息
  - `<meta name="go-import" content="gopkg.in/vikyd/gopkg-test.v2 git https://gopkg.in/vikyd/gopkg-test.v2">`
  - 即：
    - import-prefix: `gopkg.in/vikyd/gopkg-test.v2`
    - vcs：`git`
    - repo-root: `https://gopkg.in/vikyd/gopkg-test.v2`
- 所以后面 `git` 会自动从 `https://gopkg.in/vikyd/gopkg-test.v2` 获取源码
  > 需了解下 [Git 内部原理 - 传输协议](https://git-scm.com/book/zh/v1/Git-%E5%86%85%E9%83%A8%E5%8E%9F%E7%90%86-%E4%BC%A0%E8%BE%93%E5%8D%8F%E8%AE%AE)
- 抓包知 git 客户端发送了 HTTPS GET 请求（`获取 info/refs`） https://gopkg.in/vikyd/gopkg-test.v2/info/refs?service=git-upload-pack：
- 请求：

```
GET /vikyd/gopkg-test.v2/info/refs?service=git-upload-pack HTTP/1.1
Host: gopkg.in
User-Agent: git/2.20.1 (Apple Git-117)
Accept: */*
Accept-Encoding: deflate, gzip
Pragma: no-cache
Cache-Control: no-cache
```

- 响应：

```
HTTP/1.1 200 OK
Content-Type: application/x-git-upload-pack-advertisement
Date: Sat, 18 May 2019 09:23:25 GMT
Content-Length: 423
Expires: 0
Cache-Control: no-cache
Connection: keep-alive

001e# service=git-upload-pack
00000108aa17cdf20e85164faa7bd51efada7afc8a177bc5 HEAD
multi_ack thin-pack side-band side-band-64k ofs-delta shallow deepen-since deepen-not deepen-relative no-progress include-tag multi_ack_detailed no-done oldref=HEAD:refs/heads/master agent=git/github-g98a2a39ebde2
003faa17cdf20e85164faa7bd51efada7afc8a177bc5 refs/heads/master
003aaa17cdf20e85164faa7bd51efada7afc8a177bc5 refs/tags/v2
0000
```

- git 在获得 info/refs 后，自动继续获取真正的源码，发送了一个 POST 请求，得到的响应就是源码数据
- URL：https://gopkg.in/vikyd/gopkg-test.v2/git-upload-pack
- 请求：

```
POST /vikyd/gopkg-test.v2/git-upload-pack HTTP/1.1
Host: gopkg.in
User-Agent: git/2.20.1 (Apple Git-117)
Accept-Encoding: deflate, gzip
Content-Type: application/x-git-upload-pack-request
Accept: application/x-git-upload-pack-result
Content-Length: 293
Pragma: no-cache
Cache-Control: no-cache

00b4want aa17cdf20e85164faa7bd51efada7afc8a177bc5 multi_ack_detailed no-done side-band-64k thin-pack no-progress ofs-delta deepen-since deepen-not agent=git/2.20.1.(Apple.Git-117)
0032want aa17cdf20e85164faa7bd51efada7afc8a177bc5
0032want aa17cdf20e85164faa7bd51efada7afc8a177bc5
00000009done
```

- 响应：

```
HTTP/1.1 200 OK
Cache-Control: no-cache, max-age=0, must-revalidate
Content-Type: application/x-git-upload-pack-result
Pragma: no-cache
Server: GitHub Babel 2.0
Vary: Accept-Encoding
X-Frame-Options: DENY
X-Github-Request-Id: D652:781C:92495F:108EEF6:5CDFCF0D
Date: Sat, 18 May 2019 09:23:25 GMT
Content-Length: 1001
Expires: 0
Connection: keep-alive

0008NAK
03d
一些二进制数据，此处略过
```

- git 得到 POST 得到的响应数据后，处理，并存储到 `$GOPATH/src/gopkg.in/vikyd/gopkg-test.v2`
  > 响应数据看起来乱码，实际是 git 能解析的数据，能最终转为源码
- go get 从网络获取数据到此结束

## gopkg.in 的优缺点

### 优点

- 轻量，本质是利用了 Golang 的 [go-import 机制](https://golang.org/cmd/go/#hdr-Remote_import_paths)，所有内容还是在 GitHub 上，gopkg 只是转发了 2 个东西（`go-import`、`git clone`
- 支持 go get GitHub 上指定版本的源码
  > go get 本身只能获取默认分支的源码
- import 地址较简短
- 浏览器打开时能指向自动生成的在线 godoc 文档
  > 如打开 https://gopkg.in/vikyd/gopkg-test.v2 ，里面有 API 文档的按钮

### 缺点

- [不支持子包（或叫 subpackage）](https://github.com/niemeyer/gopkg/issues/9)
  - 或说要支持子包，需将所有 `import "github.com"` 类似的子包都改为 `import "gopkg.in"` 开头
  - 如不支持此项目：https://github.com/vikyd/goget-test
    - 虽然可以
      - 执行 `go get gopkg.in/vikyd/goget-test.v2`
      - 查看到页面：https://gopkg.in/vikyd/goget-test.v2
      - 执行：`go run main.go` 也不会报错
    - 但实际此时 `$GOPATH/src/gopkg.in/vikyd/goget-test.v2/main.go` 中引用的 p01 是来自 `$GOPATH/src/github.com/vikyd/goget-test/p01/p01.go`，而非 `$GOPATH/src/gopkg.in/vikyd/goget-test.v2/p01/p01.go`
      - 删掉 `$GOPATH/src/github.com/vikyd/goget-test/` 目录就不能跑了
    - 因为经过 gopkg 后其中的 `p01` 包的 import 路径变了：
      - GitHub 中：[import "github.com/vikyd/goget-test/p01"](https://github.com/vikyd/goget-test/blob/master/main.go#L6)
      - gopkg 到本地后只能：`import "gopkg.in/vikyd/goget-test.v2/p01"`
  - 所以目前常见的推荐 go get gopkg.in 的库基本都是单包项目（single package）（或子包与上级包无引用关系），即没有子包（子目录），例如：
    > 个人认为 single package 的 go 项目 [不太好管理代码结构](https://medium.com/@benbjohnson/standard-package-layout-7cdbc8391fc1)
    - [lumberjack](https://github.com/natefinch/lumberjack)
      > lumberjack is a log rolling package for Go
    - [go-yaml](https://github.com/go-yaml/yaml)
      > YAML support for the Go language.
    - [cli](https://github.com/urfave/cli)
      > A simple, fast, and fun package for building command line apps in Go
    - [dap](https://github.com/go-ldap/ldap)
      > Basic LDAP v3 functionality for the GO programming language.
    - [Blackfriday](https://github.com/russross/blackfriday)
      > Blackfriday: a markdown processor for Go
  - 猜：是不是就因为 gopkg 这个问题，导致很多 go 项目都是 single package？
  - 目前使用 [go mod](https://github.com/golang/go/wiki/Modules#version-selection) 可以 Golang 官方支持获取不同版本的源码
    > 其中的坑这里不细说
- 由于 gopkg 不是 Golang 官方的网站，若 gopkg 下线了，则这些 import 就都失效了
  > 相对来说，gopkg 下线的概率比 GitHub 下线的概率高
- 目前只支持 GitHub
  - gopkg 的 [网站源码](https://github.com/niemeyer/gopkg) 实际也不多，要支持其他网站也不是不可以

# golang.org/x 详述

`golang.org/x` 的角色与 gopkg.in 虽部分功能相似，但目标不一样。

- `golang.org/x` 仅提供 go-import 信息，实际源码还是在 https://go.googlesource.com
- 之所以与核心代码 https://github.com/golang/go 分开，是因为这些工具的兼容性相对没那么严格

以 golang.org/x/crypto 为例：

- 执行 `go get golang.org/x/crypto`

### 简单版

当你执行此命令 `go get golang.org/x/crypto` 时，实际会发生：

- 先向 golang.org/crypto 进行 HTTPS GET，获得 go-import 信息，即获得了源码位置
- 再向 https://go.googlesource.com/crypto 进行 git clone
- go get 成功，存在本地目录：`$GOPATH/src/golang.org/x/crypto`

### 详细版

详细版包含抓包过程，内容较长。

- 执行：`go get golang.org/x/crypto`
  > 全程只需执行这 1 条命令，后面都是抓包得知的过程
- 本地向 golang.org 发出 HTTPS GET 请求：
- URL：https://golang.org/x/crypto?go-get=1
- 请求：

```
:authority: golang.org
:method: GET
:path: /x/crypto?go-get=1
:scheme: https
accept-encoding: gzip
user-agent: Go-http-client/2.0
Pragma: no-cache
Cache-Control: no-cache
```

- 响应：

```
:status: 200
date: Sun, 19 May 2019 05:03:59 GMT
content-type: text/html; charset=utf-8
vary: Accept-Encoding
content-encoding: gzip
via: 1.1 google
alt-svc: quic=":443"; ma=2592000; v="46,44,43,39"
Expires: 0
Cache-Control: no-cache

<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<meta name="go-import" content="golang.org/x/crypto git https://go.googlesource.com/crypto">
<meta name="go-source" content="golang.org/x/crypto https://github.com/golang/crypto/ https://github.com/golang/crypto/tree/master{/dir} https://github.com/golang/crypto/blob/master{/dir}/{file}#L{line}">
<meta http-equiv="refresh" content="0; url=https://godoc.org/golang.org/x/crypto">
</head>
<body>
Nothing to see here; <a href="https://godoc.org/golang.org/x/crypto">move along</a>.
</body>
</html>
```

- 从响应得到的 go-import 信息
  - `<meta name="go-import" content="golang.org/x/crypto git https://go.googlesource.com/crypto">`
  - 即：
    - import-prefix: `golang.org/x/crypto`
    - vcs：`git`
    - repo-root: `https://go.googlesource.com/crypto`
- 所以后面 `git` 会自动从 `https://go.googlesource.com/crypto` 获取源码
  > 需了解下 [Git 内部原理 - 传输协议](https://git-scm.com/book/zh/v1/Git-%E5%86%85%E9%83%A8%E5%8E%9F%E7%90%86-%E4%BC%A0%E8%BE%93%E5%8D%8F%E8%AE%AE)
- 抓包知 git 客户端发送了 HTTPS GET 请求（`获取 info/refs`）
- URL：https://go.googlesource.com/crypto/info/refs?service=git-upload-pack：
- 请求：

```
GET /crypto/info/refs?service=git-upload-pack HTTP/1.1
Host: go.googlesource.com
User-Agent: git/2.20.1 (Apple Git-117)
Accept: */*
Accept-Encoding: deflate, gzip
Pragma: no-cache
Cache-Control: no-cache
```

- 响应：

```
HTTP/1.1 200 OK
Cache-Control: no-cache, max-age=0, must-revalidate
Content-Encoding: gzip
Content-Security-Policy-Report-Only: script-src 'nonce-25YsrudLYDYWVOpfbw6IWA' 'unsafe-inline' 'strict-dynamic' https: http: 'unsafe-eval';object-src 'none';base-uri 'self';report-uri https://csp.withgoogle.com/csp/gerritcodereview/1
Content-Type: application/x-git-upload-pack-advertisement
Pragma: no-cache
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-Xss-Protection: 1; mode=block
Date: Sun, 19 May 2019 05:04:00 GMT
Alt-Svc: quic=":443"; ma=2592000; v="46,44,43,39"
Transfer-Encoding: chunked
Expires: 0
Connection: keep-alive

001e# service=git-upload-pack
0000011122d7a77e9e5f409e934ed268692e56707cd169e5 HEAD
include-tag multi_ack_detailed multi_ack ofs-delta side-band side-band-64k thin-pack no-progress shallow no-done allow-tip-sha1-in-want allow-reachable-sha1-in-want agent=JGit/4-google filter symref=HEAD:refs/heads/master
006cb42e5bc6f50cb210958473186c41d25cd8d078ee refs/cache-automerge/dd/b1fb0c71df5b4512fcbf653dddf624549896ee
0046b956ef63f191e906ae7ef55e5f2f497b77844fc7 refs/changes/00/163600/1
.... 有点长，此处忽略
```

- git 在获得 info/refs 后，自动继续获取真正的源码，发送了一个 POST 请求，得到的响应就是源码数据
- URL：https://go.googlesource.com/crypto/git-upload-pack
- 请求：

```
POST /crypto/git-upload-pack HTTP/1.1
Host: go.googlesource.com
User-Agent: git/2.20.1 (Apple Git-117)
Accept-Encoding: deflate, gzip
Content-Type: application/x-git-upload-pack-request
Accept: application/x-git-upload-pack-result
Content-Length: 269
Pragma: no-cache
Cache-Control: no-cache

009cwant 22d7a77e9e5f409e934ed268692e56707cd169e5 multi_ack_detailed no-done side-band-64k thin-pack no-progress ofs-delta agent=git/2.20.1.(Apple.Git-117)
0032want 56440b844dfe139a8ac053f4ecac0b20b79058f4
0032want e84da0312774c21d64ee2317962ef669b27ffb41
00000009done
```

- 响应：

```
HTTP/1.1 200 OK
Cache-Control: no-cache, max-age=0, must-revalidate
Content-Security-Policy-Report-Only: script-src 'nonce-vysiBooFyQ5uKpCiDBoYAg' 'unsafe-inline' 'strict-dynamic' https: http: 'unsafe-eval';object-src 'none';base-uri 'self';report-uri https://csp.withgoogle.com/csp/gerritcodereview/1
Content-Type: application/x-git-upload-pack-result
Pragma: no-cache
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-Xss-Protection: 1; mode=block
Date: Sun, 19 May 2019 05:04:01 GMT
Transfer-Encoding: chunked
Alt-Svc: quic=":443"; ma=2592000; v="46,44,43,39"
Expires: 0
Connection: keep-alive

0008NAK
一些二进制数据，此处略过
```

- git 得到 POST 得到的响应数据后，处理，并存储到 `$GOPATH/src/golang.org/x/crypto`
  > 响应数据看起来乱码，实际是 git 能解析的数据，能最终转为源码
- go get 从网络获取数据到此结束

# godoc.org 详述

没啥好详述的，简述就够了。

建议以此为在线文档。

# 总结

- godoc.org：建议使用
- gopkg.in：不建议使用
- golang.org/x：需要时用即可，也不是普通用户需要管的
