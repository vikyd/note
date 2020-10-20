# Golang go mod 伪版本号的几种形式、产生原因
go mod 遵循语义版本，即 [semver](https://semver.org/)，项目的各种依赖包版本都记录在 `go.mod` 文件中。

`go.mod` 中有时会记录到一些伪版本号（pseudo version），这些伪版本号看起来很奇怪，到底是在什么场景下产生的？

本文尝试用一些实例解答。


# 目录
[TOC]


# go mod 的伪版本号官方定义
官方定义有 3 种伪版本号形式：https://golang.org/cmd/go/#hdr-Pseudo_versions

1. `vX.0.0-yyyymmddhhmmss-abcdefabcdef`
1. `vX.Y.Z-pre.0.yyyymmddhhmmss-abcdefabcdef`
1. `vX.Y.(Z+1)-0.yyyymmddhhmmss-abcdefabcdef`

但此外还有一种伪版本号形式：

1. 类似：`vX.0.0-00010101000000-000000000000`

先不说前面的版本号，先说说后面几节的含义：

> 以 Git 为例

- `yyyymmddhhmmss`：表示 git commit（提交）的时间，精确到秒
- `abcdefabcdef`：表示 git commit 的短 hash 值

前面的版本号部分的含义，将在介绍完实验后，再逐一描述。



# go mod 的伪版本号实例

以下是 `go.mod` 中伪版本的常见实例：

```
github.com/vikyd/go-pseudo-version-zero v0.0.0-20200223151919-aadbc87446db

github.com/vikyd/go-pseudo-version-v2/v2 v2.0.0-20200223161956-2e71a98095ff

github.com/vikyd/go-pseudo-version-v3/v3 v3.0.0-20200223162350-28befbc6632e

github.com/vikyd/go-pseudo-version-precommit v1.2.3-abc.0.20200224083453-edee0fbb7b85

github.com/vikyd/go-pseudo-version-precommit v1.2.4-pre.0.20200224083546-e188359d5696

github.com/vikyd/go-pseudo-version-normal-tag v1.1.2-0.20200224165638-e6ffd0534483

github.com/google/uuid v0.0.0-00010101000000-000000000000
github.com/go-playground/validator/v10 v10.0.0-00010101000000-000000000000
```

这些伪版本号分别代表什么意思？

为什么项目的 `go.mod` 中会有类似这些伪版本号？




# 实验
本实验将一步步复现出上述伪版本号。

- 在非 GOPATH 任意位置创建一个目录，假设名为：`abc`
- 进入 `abc` 目录
- 初始化 go mod，得到一个 `go.mod` 文件：

```sh
go mod init github.com/example/abc
```

> 上述路径可任意，反正都不会上传



## 第 1 种伪版本号（主版本：v0）：`vX.0.0-yyyymmddhhmmss-abcdefabcdef` 
被 go get 仓库：github.com/vikyd/go-pseudo-version-zero 。

执行：

```sh
go get -v github.com/vikyd/go-pseudo-version-zero
```

`go.mod` 中多了一行：

```go.mod
require github.com/vikyd/go-pseudo-version-zero v0.0.0-20200223151919-aadbc87446db // indirect
```

观察可知：

- 得到 `v0.0.0-...` 开头的伪版本号

原因：

- 仓库中没有任何 tag
- 所以：
  - go 取了最新的 commit 版本
  - 命名为 `v0.0.0-...` 开头，表示比 `v0.0.0` 更低版本



## 第 1 种伪版本号（主版本：v2）：`vX.0.0-yyyymmddhhmmss-abcdefabcdef` 
被 go get 仓库：github.com/vikyd/go-pseudo-version-v2 。


执行：

```sh
go get -v github.com/vikyd/go-pseudo-version-v2/v2
```

`go.mod` 中多了一行：

```go.mod
github.com/vikyd/go-pseudo-version-v2/v2 v2.0.0-20200223161956-2e71a98095ff // indirect
```

观察可知：

- 得到 `v2.0.0-...` 开头的伪版本号

原因：

- 仓库中没有任何 tag
- 且 go get 请求的是 `v2` 版本（留意 go get 命令的最后部分）
- 且仓库中有 `go.mod` 文件
- 且仓库中 `go.mod` 的模块名是 v2：`module github.com/vikyd/go-pseudo-version-v2/v2`


同理可继续 `go get -v github.com/vikyd/go-pseudo-version-v3/v3` 。


## go get 可指定版本
下一个实验之前，先大致了解 go get 指定版本的方式。

go get 支持类似以下方式指定版本：

```sh
go get github.com/gorilla/mux@latest    # same (@latest is default for 'go get')
go get github.com/gorilla/mux@v1.6.2    # records v1.6.2
go get github.com/gorilla/mux@e3702bed2 # records v1.6.2
go get github.com/gorilla/mux@c856192   # records v0.0.0-20180517173623-c85619274f5d
go get github.com/gorilla/mux@master    # records current meaning of master
```


参考：https://golang.org/cmd/go/#hdr-Module_queries



## 第 2 种伪版本号：`vX.Y.Z-pre.0.yyyymmddhhmmss-abcdefabcdef`
被 go get 仓库：github.com/vikyd/go-pseudo-version-precommit 。

执行：

```sh
go get -v github.com/vikyd/go-pseudo-version-precommit@e188359
```

`go.mod` 中多了一行：

```go.mod
github.com/vikyd/go-pseudo-version-precommit v1.2.4-pre.0.20200224083546-e188359d5696 // indirect
```


观察可知：

- 得到 `v1.2.4-pre.0.  ...` 开头的伪版本号
- 看看 git commit 时间线：

```
         +------------+           +------------+
   tags: | v1.2.3-abc |           | v1.2.4-pre |
         |            |           |            |
commits: |  9a56718   |  edee0fb  |  7e43580   |  e188359
         +-----+------+     +     +-----+------+     +
               |            |           |            |
               |            |           |            |
               v            v           v            v
       +-------+------------+-----------+------------+---->
                                                       time
```


原因：

- go get 指明一个 tag 时（如 [e188359](https://github.com/vikyd/go-pseudo-version-precommit/commit/e188359d5696226acd71d85bd1448b2ec47e15e5)），若其之前存在一个 tag 版本号为预发布版本号，则会得到：以之前的预发布版本（pre-release）开头，以所指 tag 结尾，的伪版本号，即：`v1.2.4-pre.0.20200224083546-e188359d5696`


同理可继续 `go get -v github.com/vikyd/go-pseudo-version-precommit@edee0fb`，得 `go.mod` 多出一行：`github.com/vikyd/go-pseudo-version-precommit v1.2.3-abc.0.20200224083453-edee0fbb7b85 // indirect`。

即，不管是 `v1.2.3-abc`，还是 `v1.2.4-pre`，都属于预发布版本的允许形式。



## 第 3 种伪版本号：`vX.Y.(Z+1)-0.yyyymmddhhmmss-abcdefabcdef` 
被 go get 仓库：github.com/vikyd/go-pseudo-version-normal-tag 。

执行：

```sh
go get -v github.com/vikyd/go-pseudo-version-normal-tag@e6ffd05
```

go.mod 中多了一行：

```go.mod
github.com/vikyd/go-pseudo-version-normal-tag v1.1.2-0.20200224165638-e6ffd0534483 // indirect
```


观察可知：

- 得到 `v1.1.2-0.  ...` 开头的伪版本号
- 看看 git commit 时间线：

```
         +-----------+
   tags: |   v1.1.1  |
         |           |
commits: |  1d608fd  |   e6ffd05
         +-----+-----+      +
               |            |
               |            |
 +-------------v------------v----->
                               time
```

- commit [e6ffd05](https://github.com/vikyd/go-pseudo-version-normal-tag/commit/e6ffd0534483f029b688ac482fcd0749243eef1d) 之前有个正常的版本号 [v1.1.1](https://github.com/vikyd/go-pseudo-version-normal-tag/releases/tag/v1.1.1)

原因：

- go get 指明一个 tag 时（如 [e6ffd05](https://github.com/vikyd/go-pseudo-version-normal-tag/commit/e6ffd0534483f029b688ac482fcd0749243eef1d)），若其之前的 tag 版本号是一个正常版本号（如 v1.1.1），则会得到：以之前的正常版本号的最后一位 `+1` 开头（原 v1.1.1，`+1` 之后得到 `v1.1.2`），以所指 tag 结尾，的伪版本号，即：`v1.1.2-0.20200224165638-e6ffd0534483`



## 第 4 中伪版本号：`vX.0.0-00010101000000-000000000000`

下载或 git clone 此仓库：https://github.com/vikyd/gomod-replace-pseudo 。

下载后什么都不做，先观察 `go.mod` 文件（此时没有 `require`）：

```go.mod
module github.com/vikyd/gomod-replace-pseudo

go 1.15

replace (
	github.com/go-playground/validator/v10 => github.com/vikyd/validator/v10 v10.4.0
	github.com/google/uuid => github.com/vikyd/uuid v1.1.2
	github.com/jinzhu/now v1.1.1 => github.com/vikyd/now v1.1.1
)
```

在根目录执行 `go run main.go`，得的类似输出：

```sh
➜ go run main.go
144a2e9a-467a-4fde-bfe1-086adcfac818
2020-10-20 12:00:00 +0800 CST
validator works
```

此时再观察 `go.mod` 文件（此时底部多了 `require`）：

```go.mod
module github.com/vikyd/gomod-replace-pseudo

go 1.15

replace (
	github.com/go-playground/validator/v10 => github.com/vikyd/validator/v10 v10.4.0
	github.com/google/uuid => github.com/vikyd/uuid v1.1.2
	github.com/jinzhu/now v1.1.1 => github.com/vikyd/now v1.1.1
)

require (
	github.com/go-playground/validator/v10 v10.0.0-00010101000000-000000000000 // indirect
	github.com/google/uuid v0.0.0-00010101000000-000000000000 // indirect
	github.com/jinzhu/now v1.1.1 // indirect
)
```

解释：
- 若 `go.mod` 中 `replace` 指令没有指明左侧的版本号，则 Go 会自动生成一个伪版本号，并添加到 `require` 中
- `v0.0.0-00010101000000-000000000000`
  - 因为 `github.com/google/uuid => github.com/vikyd/uuid v1.1.2` 左侧没指明 `github.com/google/uuid` 的具体版本号是多少
- `v10.0.0-00010101000000-000000000000`
  - 因为 `github.com/go-playground/validator/v10 => github.com/vikyd/validator/v10 v10.4.0` 左侧只指明了主版本号 `v10`，但并未指明 `github.com/go-playground/validator/v10` 的次要、补丁具体版本号
- `v1.1.1`
  - 因为 `github.com/jinzhu/now v1.1.1 => github.com/vikyd/now v1.1.1` 左侧指明了 `github.com/jinzhu/now` 的具体版本号

Go 生成此伪版本号的源码 [`cmd/go/internal/modload/import.go`](https://github.com/golang/go/blob/go1.15.3/src/cmd/go/internal/modload/import.go#L229-L243):

```go
if _, pathMajor, ok := module.SplitPathVersion(p); ok && len(pathMajor) > 0 {
	v = modfetch.PseudoVersion(pathMajor[1:], "", time.Time{}, "000000000000")
} else {
	v = modfetch.PseudoVersion("v0", "", time.Time{}, "000000000000")
}
```

↓ [`cmd/go/internal/modfetch/pseudo.go`](https://github.com/golang/go/blob/go1.15.3/src/cmd/go/internal/modfetch/pseudo.go#L53-L77):

```go
func PseudoVersion(major, older string, t time.Time, rev string) string {
	if major == "" {
		major = "v0"
	}
	segment := fmt.Sprintf("%s-%s", t.UTC().Format(pseudoVersionTimestampFormat), rev)
	build := semver.Build(older)
	older = semver.Canonical(older)
	if older == "" {
		return major + ".0.0-" + segment // form (1)
	}
	if semver.Prerelease(older) != "" {
		return older + ".0." + segment + build // form (4), (5)
	}

	// Form (2), (3).
	// Extract patch from vMAJOR.MINOR.PATCH
	i := strings.LastIndex(older, ".") + 1
	v, patch := older[:i], older[i:]

	// Reassemble.
	return v + incDecimal(patch) + "-0." + segment + build
}
```



# 在线检测 语义版本合法性

网站：https://jubianchi.github.io/semver-check

此网站可检测一个版本号是否符合语义版本。

> 主要关注网站右侧绿色的 [Version]

- 语义版本：https://jubianchi.github.io/semver-check/#/version/v999.777.888
  - 会提示：`... Given the version you entered: ...`
- 非语义版本：https://jubianchi.github.io/semver-check/#/version/v1.0
  - 会提示：`This version is invalid.`


# 语义版本的正常版本
以下是 **符合** 语义版本的正常版本（也最常见）：

- [v0.1.0](https://jubianchi.github.io/semver-check/#/version/v0.1.0)
- [v1.0.0](https://jubianchi.github.io/semver-check/#/version/v1.0.0)
- [v1.2.3](https://jubianchi.github.io/semver-check/#/version/v1.2.3)
- [v2.0.0](https://jubianchi.github.io/semver-check/#/version/v2.0.0)
- [v2.3.4](https://jubianchi.github.io/semver-check/#/version/v2.3.4)
- [v999.777.888](https://jubianchi.github.io/semver-check/#/version/v999.777.888)


# 语义版本号的伪版本号
以下是 **符合** 语义版本的伪版本号：

- [v1.2.3-pre](https://jubianchi.github.io/semver-check/#/version/v1.2.3-pre)
- [v1.2.3-rc.1](https://jubianchi.github.io/semver-check/#/version/v1.2.3-rc.1)
- [v1.2.3-abcdefghijklmn](https://jubianchi.github.io/semver-check/#/version/v1.2.3-abcdefghijklmn)
- [v1.2.3-123](https://jubianchi.github.io/semver-check/#/version/v1.2.3-123)
- [v1.2.4-pre.0.20200224083546-e188359d5696](https://jubianchi.github.io/semver-check/#/version/v1.2.4-pre.0.20200224083546-e188359d5696)



# 补充说明
下面例子的 `+incompatible`、`// indirect` 是怎样产生的？

```
github.com/vikyd/go-incompatible v2.3.4+incompatible // indirect

github.com/vikyd/go-pseudo-version-zero v0.0.0-20200223151919-aadbc87446db // indirect
```


## `+incompatible` 是什么？
同样以前面的空 go mod 项目为主目录。

被 go get 仓库：github.com/vikyd/go-incompatible 。

执行：

```sh
go get -v github.com/vikyd/go-incompatible
```

`go.mod` 中多了一行：

```go.mod
github.com/vikyd/go-incompatible v2.3.4+incompatible // indirect
```


观察可知：

- 此仓库有一个 tag 为：[v2.3.4](https://github.com/vikyd/go-incompatible/tags)
- 但此 tag 中没有 `go.mod`
- 所以：
  - 虽然 tag v2.3.4 属于 v2 主版本号下的版本，但其源码中没有 `go.mod` 文件，所以说明这不是一个十分符合 go mod 预期的 `v2` 版本

参考：https://golang.org/cmd/go/#hdr-Module_compatibility_and_semantic_versioning


## `// indirect` 是什么？
`// indirect` 表示：当前项目源码并无用到此模块。

- 通常手动 `go get -v 某个模块` 后，项目没 import 此模块的包时，就会出现 `// indirect` 。
- 通常 `go mod tidy` 后，`// indirect` 的行就会自动消失。



# go get 某些版本的失败情况

## 情况01：无 go.mod
被 go get 仓库：github.com/vikyd/go-pseudo-version-v2-nogomod 。

执行：`go get -v github.com/vikyd/go-pseudo-version-v2-nogomod/v2`


得到：`go get github.com/vikyd/go-pseudo-version-v2-nogomod/v2: module github.com/vikyd/go-pseudo-version-v2-nogomod@upgrade found (v0.0.0-20200223162538-e734ae478275), but does not contain package github.com/vikyd/go-pseudo-version-v2-nogomod/v2`


所以：要产生类似 `v2.0.0-20200223161956-2e71a98095ff` 的伪版本号，至少需源码中包含 `go.mod` 文件，且其中的 `module` 后的路径最后应是 `v2`


## 情况02：有 `go.mod` 但版本不对
被 go get 仓库：github.com/vikyd/go-pseudo-version-v2-gomod-notmatch 。

执行：`go get -v github.com/vikyd/go-pseudo-version-v2-gomod-notmatch`


得到：`go get github.com/vikyd/go-pseudo-version-v2-gomod-notmatch/v2: module github.com/vikyd/go-pseudo-version-v2-gomod-notmatch@upgrade found (v0.0.0-20200223162902-1f16ea803414), but does not contain package github.com/vikyd/go-pseudo-version-v2-gomod-notmatch/v2`


所以：即使有 `go.mod` 还不够，里面的 module 路径最后还得是 v2，类推。



# 伪版本号的一些特点

- 类似 `v1.2.4-pre.0.20200224083546-e188359d5696`，依然符合 semver 的 [预发布版本](https://semver.org/#spec-item-9)、[版本元数据](https://semver.org/#spec-item-10) 规范
- 无需人工手动修改，go 命令会自动生成，也不应手动修改伪版本号
- 伪版本号优先级低于正常版本号，若有 tag：`v1.1.1`、`v1.1.2-pre`，则 go get 不指定版本时依然优先选择 `v1.1.1`，而非更新的 `v1.1.2-pre`。



# 总结
go mod 的伪版本号，看起来虽然有些奇怪，但其作用也是明显的：

- 可兼容获取无发布 tag 版本号的依赖包（形式01：`vX.0.0-yyyymmddhhmmss-abcdefabcdef`）
- 可兼容预发布版本（形式02：`vX.Y.Z-pre.0.yyyymmddhhmmss-abcdefabcdef`）
- 可告诉用户某些 commit 可能代表未来可能会发布的版本（形式03：`vX.Y.(Z+1)-0.yyyymmddhhmmss-abcdefabcdef`）
- 自动适配 `replace` 中有指定，但 `require` 中未指定的模块（形式：`vX.0.0-00010101000000-000000000000`）

日常使用，可无需了解伪版本号。

但有时 go get 不成功，了解下这些伪版本号，对填坑会有点帮助。


# 其他参考

- Golang 处理伪版本号的源码：https://github.com/golang/go/blob/master/src/cmd/go/internal/modfetch/pseudo.go#L14
- 貌似仓库无 `go.mod` 时， https://pkg.go.dev/ 不会收录。但 `proxy.golang.org` 会收录，如：
  - 有收录：https://proxy.golang.org/github.com/vikyd/go-pseudo-version-pre/@v/list
  - 无收录：https://pkg.go.dev/github.com/vikyd/go-pseudo-version-pre?tab=doc
