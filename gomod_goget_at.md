# Golang module 模式下 go get 使用 `@` 的各种姿势、实例
go module 的版本号基于 [semver](https://semver.org/)，允许类似 `go get github.com/google/uuid@v1.1.0` 的形式获取指定版本依赖包，即 `@` 后跟 `v` 再跟 `语义数字版本号`。

但从 Golang 官方文档看 [1](https://golang.org/cmd/go/#hdr-Module_queries)、[2](https://golang.org/cmd/go/#hdr-Add_dependencies_to_current_module_and_install_them)，在字符 `@` 后面还支持更多的形式，包括但不限 `"@>v1.1.0"`、 `@latest`、`@commitHash`、`@patch` 等。

问题：

- 到底 Golang 的 `go get` 支持哪几种的 `@` 形式？
- 不同的 `@` 形式是否有什么潜规则？

Golang 官方文档貌似没清晰地列出 `@` 的所有可能情况。

本文尝试以可操作实例形式，汇总 Golang 官方文档曾列出过的可用方式，列出注意事项。




# 目录
[TOC]


# 名词约定

- semver：语义版本
- tag：指 git 的 tag
- branch：指  git 的分支
- commit：指 git 的提交
- hash：指 git 的 commit 哈希
- release：指符合 [semver](https://semver.org/#spec-item-9) 的正式发布版本，如 `v1.2.3`
- pre：指符合 [semver](https://semver.org/#spec-item-9) 的预发布版本，如 `v1.2.3-pre`、`v2.3.4-abc`
  - pre 版本优先级比 release 版本低
- major：主版本号，即 `v1.2.3` 中的 `1`
- minor：次版本号，即 `v1.2.3` 中的 `2`
- patch：补丁版本号，即 `v1.2.3` 中的 `3`
- modulePath：代指一个 go 模块的名称


# 伪版本号

本文实例会出现一些伪版本号，但这里暂不做详解。

伪版本号形如：`v0.0.0-20200308080801-2936fb96f1eb`、`v1.3.2-pre.0.20200308080801-a3735a849469` 等。

Golang 更多伪版本号的格式、来源，可见 [这里](https://github.com/vikyd/note/blob/master/go_pseudo_version.md)。




# 实验环境
- OS：MacBook Pro 10.14
- Go：1.14
- go env（即 Golang 默认）

```
GOPROXY="https://proxy.golang.org,direct"
GOSUMDB="sum.golang.org"
```




# 实例 github 仓库

实验仓库：https://github.com/vikyd/gomod-goget-at

后面实例都将以此仓库作为被 go get 实例。

下面是仓库的 commit、tag、branch 流程图：


```
* 760713c    (dev 分支)        commit 12
| \
|  * a3735a8 (master 分支)     commit 13
| /  
* a72dc08                      commit 11
|
* e1fe73f    (tag: v1.3.2-pre) commit 10
|
* 2d2b8d8    (tag: v1.3.1)     commit 9
|
* a84af9c    (tag: v1.2.5)     commit 8
|
* 153c5e1    (tag: v1.2.4)     commit 7
|
* 2874453    (tag: v1.2.4-abc) commit 6
|
* 9624374    (tag: v1.2.3)     commit 5
|
* ba43e9a    (tag: v1.2.3-pre) commit 4
|
* f3d16d0    (tag: v1.2.2)     commit 3
|
* fca104f    (tag: v1.2.1)     commit 2
|
* 2936fb9                      commit 1
↑
```

> ↑ 打印类似上面 flow 小技巧：`alias gl='git log --oneline --graph --decorate --all'`，或 `gitk --all` 


# 实验准备

准备一个空的 go mod 项目：

```sh
# GOPATH 外任意目录创建空目录
cd ~/Desktop
mkdir gogetat

go mod init modulePath

# 可看到有一个 go.mod
ls -lah

cat go.mod
```



# 实验：go get `@` 模式、实例

下面将列举每种 go get 的 `@` 模式，及其可操作实例。

## 类型：不带任何 `@`
说明：

- 获取当前主版本号的最新 release 版本
- 等同于 `go get -v modulePath@latest`，具体细节见下面的 `@latest` 类型

模式：

```sh
go get -v modulePath
```

实例：

> 后面 `实例` 命令均可复制到命令行进行验证

> 命令的 `-v` 表示打印详细信息，非必须

```sh
# 得：最新 release 版本 v1.3.1
go get -v github.com/vikyd/gomod-goget-at
```



## 类型：`@semverTag`

例子：`v0.1.2`、`v1.2.3`、`v2.3.4`

说明：

- 精确获取 release 版本

模式：

```sh
go get -v modulePath@semverTag
```

实例：

```sh
# 得：精确版本 v1.2.3
go get -v github.com/vikyd/gomod-goget-at@v1.2.3
```




## 类型：`@semverTagPrefix`
例子：`v1`、`v1.2`、`v2`

说明：

- 获取指定版本前缀的最新 release 版本

模式：

```sh
go get -v modulePath@semverTagPrefix
```

实例：

```sh
# 得：v1.x.x 的最新版本 v1.3.1
go get -v github.com/vikyd/gomod-goget-at@v1

# 得：v1.2.x 的最新版本 v1.2.5
go get -v github.com/vikyd/gomod-goget-at@v1.2
```



## 类型：`@"运算符semverTag"`
例子：`"@>1.1.0"`、`"<=1.5.3"`

说明：

- 所有允许运算符：`>`、`>=`、`<`、`<=`
- 用于指定版本的最近 release 版本
- 假设有：`v1.2.3`、`v1.2.4`、`v1.2.5`，且当前依赖版本是 `v1.2.3`
- 则 `"@>v1.2.3"` 会获取 `v1.2.4`，而非 `v1.2.5`
- 须用英文单引号 `''` 或双引号 `""` 包围

模式：

```sh
go get -v modulePath@">semverTag"
```

实例：

```sh
# 初始环境
go get -v github.com/vikyd/gomod-goget-at@v1.2.3
# 得：比 v1.2.3 更新的最旧 release 版本 v1.2.4，而非 v1.2.5
go get -v github.com/vikyd/gomod-goget-at@">v1.2.3"

# 初始环境
go get -v github.com/vikyd/gomod-goget-at@v1.2.3
# 得：比 v1.2.3 更旧的最新 release 版本 v1.2.2，而非 v1.2.1
go get -v github.com/vikyd/gomod-goget-at@"<v1.2.3"

# 初始环境
go get -v github.com/vikyd/gomod-goget-at@v1.2.3-pre
# 得：符合条件的最低 release 版本 v1.2.3
# 注意：结果不是 pre 版本了
go get -v github.com/vikyd/gomod-goget-at@">=v1.2.3-pre"

# 初始环境
go get -v github.com/vikyd/gomod-goget-at@v1.2.3-pre
# 得：符合条件的最高 release 版本 v1.2.2
# 注意：结果不是 pre 版本了
go get -v github.com/vikyd/gomod-goget-at@"<=v1.2.3-pre"
```



## 类型：`@commitHash`
例子：`81e4ea7`

说明：

- 获取指定 commit 的源码
- 若刚好有 tag 对应此 commit，则会记录为 tag 名称
- 若此 commit 不对应 tag，且 commit 之前有 tag，则会记录为特殊伪版本号（后面会细说）

模式：

```sh
go get -v modulePath@commitHash
```

实例：

```sh
# 获取仓库 master 分支最旧的 commit
# 得：伪版本 v0.0.0-20200308080801-2936fb96f1eb
go get -v github.com/vikyd/gomod-goget-at@2936fb9

# 获取仓库 master 分支最新的 commit
# 得：伪版本 v1.3.2-pre.0.20200308080801-a3735a849469
go get -v github.com/vikyd/gomod-goget-at@a3735a8

# 获取 v1.2.3 所在的 commit
# 得：release 版本 v1.2.3
go get -v github.com/vikyd/gomod-goget-at@9624374
```



## 类型：`@branchName`
例子：`master`、`dev`、`abc`

说明：

- 获取指定 git 分支的最新 commit
- 分支有新 commit 后，会获取旧的 commit，但因 GOPROXY 缓存，会有延迟几小时（经验），若想立即获取新 commit，应直接指定该 commit hash

模式：

```sh
go get -v modulePath@branchName
```

实例：

```sh
# 获取 master 分支最新 commit
# 得：伪版本 v1.3.2-pre.0.20200308080801-a3735a849469
go get -v github.com/vikyd/gomod-goget-at@master

# 获取 dev 分支最新 commit
# 得：伪版本 v1.3.2-pre.0.20200308080801-760713c6050b
go get -v github.com/vikyd/gomod-goget-at@dev
```



## 类型：固定字符串 `@latest`
说明：

- 获取当前主版本号的最新 release 版本
- 而不是最新的 commit，也不是最新的 pre 版本
- 若 go.mod 已依赖指定模块的 pre 版本，且最新的 release 版本都比此 pre 版本旧，则本动作会回退到最近的 release 版本
- `go get -v modulePath` 与此动作的作用一致

模式：

```sh
go get -v modulePath@latest
```

实例：

```sh
# 初始环境
go get -v github.com/vikyd/gomod-goget-at@v1.3.2-pre
# 得：回退到最新 release 版本 v1.3.1
go get -v github.com/vikyd/gomod-goget-at@latest
```



## 类型：固定字符串 `@HEAD`
说明：

- 默认分支 master 的最新 commit
- 参考：https://github.com/golang/go/issues/29761#issuecomment-492650199

模式：

```sh
go get -v modulePath@HEAD
```

实例：

```sh
# 获取默认分支的最新 commit
# 得：伪版本 v1.3.2-pre.0.20200308080801-a3735a849469
go get -v github.com/vikyd/gomod-goget-at@HEAD
```




## 类型：固定字符串 `@upgrade`
说明：

- 获取当前主版本号的最版本
- 可以是最新的 release 或 pre 版本
- 不能是无 tag 的 commit
- 若 go.mod 已依赖指定模块的 pre 版本，且没有比此 pre 版本更新的 release 版本，则不会回退到比 pre 更旧的 release 版本

模式：

```sh
go get -v modulePath@upgrade
```

实例：

```sh
# 初始环境
go get -v github.com/vikyd/gomod-goget-at@v1.3.2-pre
# 得：不变，依然为 pre 版本 v1.3.2-pre
go get -v github.com/vikyd/gomod-goget-at@upgrade
```




## 类型：固定字符串 `@patch`
说明：

- 若 go.mod 中已依赖此模块，则获取此模块的最新补丁版本
- 若 go.mod 中不存在此模块，则获取此模块对应主版本号的最新版本，此时相当于 `@latest`

模式：

```sh
go get -v modulePath@patch
```

实例：

```sh
# 初始环境
go get -v github.com/vikyd/gomod-goget-at@v1.2.3
# 得：v1.2.x 的最新 patch 版本 v1.2.5
go get -v github.com/vikyd/gomod-goget-at@patch
```




## 类型：固定字符串 `@none`
说明：

- 从 go.mod 中删除指定模块（称为 A 模块）
- 若有其它模块（称为 B 模块）依赖了 A
  - 若 B 不被任何模块依赖，则会在 go.mod 删除 B
  - 若 B 又被其他模块依赖，且版本较低，则会在 go.mod 降级 B

模式：

```sh
go get -v modulePath@none
```

实例：

```sh
# 初始环境
go get -v github.com/vikyd/gomod-goget-at@v1.2.3
# 查看当前 go.mod，有此模块
cat go.mod
# 得：go.mod 中删除了 gomod-goget-at
go get -v github.com/vikyd/gomod-goget-at@none
# 再次查看 go.mod，已无此模块
cat go.mod
```




# 版本优先级
## 优先级
下面列表，越往下，优先级越低：

- release 版本（如 `v0.1.2`、`v1.2.3`、`v2.3.4`）
- pre 版本（如 `v1.2.3-pre`、`v1.2.3-alpha`、`v1.2.3-beta`、`v1.2.3-abc123`）
- commit（如 `81e4ea7`、`1f1ba6f`）
  - 若刚某个 tag 匹配指向此 commit，则记录为该 tag


> 若主版本号与 go.mod 中的主版本号不对应，则直接报错，不会修改 go.mod


## 优先级实验

实验仓库：https://github.com/vikyd/gomod-v0-vs-pre-vs-commit

其 commit、tag 如下图所示：

```
                  +------------+ +------------+
   tags:          |   v0.1.2   | | v1.2.3-pre |
                  |            | |            |
commits:  db27517 |   6599569  | |  f8244b4   | 14c4ca9
             +    +------+-----+ +-----+------+    +
             |           |             |           |
             |           |             |           |
             v           v             v           v
       +-----+-----------+-------------+-----------+---->
                                                     time
```

任意位置新建目录 `mymodule`：
```sh
mkdir mymodule

cd mymodule

go mod init example.com/mymodule

go get -v github.com/vikyd/gomod-v0-vs-pre-vs-commit

cat go.mod
```

观测可知：

- go get 得到的是 `v0.1.2`，而不是更新的 `v1.2.3-pre` 或 `14c4ca9`。

结论：

- release 版本（`v0.1.2`）总比预发布版本（`v1.2.3-pre`）优先级更高，与发布时间无关，与 release 版本是否低于 `v1.0.0` 无关




# 其他

- go 模块版本号 [均应](https://github.com/golang/mod/blob/master/semver/semver.go#L20) 以 `v` 开头，如 `@v1.2.3`，而非 `1.2.3`
  - 打 tag 时，应 `v1.2.3`，而非 `1.2.3`
  - go get 时，也应 `@v1.2.3`，而非 `@1.2.3`
- 获取 `v2` 版本应这样，即 `@` 左、右都应带应对主版本号
  - 如：`go get modulePath/v2@v2.1.3`
- `proxy.golang.org` 的延迟问题
  - 例如 `go get -v modulePath@latest` 之后，再有新发布的 tag 时，再次 go get `@latest` 都无法获取刚发布的 tag
  - 原因：猜是 `proxy.golang.org` 有延迟
  - 解决：
    - 若是外网模块，直接 `@tag`，即可，会立即发现对应的 tag 
    - 若是内网模块，无此问题，因为不会经过 `proxy.golang.org`
- 调试 Golang 自身源码测试用例的方式之一，可便于断点 Golang 本身的源码：
  - VSCode 打开 `$GOROOT/src`
  - 打开 `cmd/go/internal/modload/query.go`
    - 在函数 `queryProxy` 里面随便打个断点
  - 打开 `cmd/go/internal/modload/query_test.go`
    - 按 `F5`
    - 等待一会，就会自动暂停在刚才的断点处



# 自建验证 git 仓库
本文的实验仓库 https://github.com/vikyd/gomod-goget-at 是通过执行下面的文件 `init_git_repo.sh` 进行快速创建的。

若想自行创建类似此 git 仓库进行更多验证，可参考下面步骤：

1. 本地执行下面的 `init_git_repo.sh`
   - 会自动创建空目录，并创建、提交，在本地得到一个与本文实验类似的 git 仓库（未 push）
1. 手动去 https://github.com/new 创建新的空仓库 
1. 在本地 git 仓库目录内执行下面命令，即可 push 所有 commit、branch、tag 到 github（请把下面路径，修改为你的新仓库路径）。
   ```sh
   # 请把下面路径，修改为你的新仓库路径
   git remote add origin git@github.com:vikyd/gomod-goget-at.git
   git push origin --mirror   
   ```

文件 `init_git_repo.sh` ↓：

```sh
#!/bin/bash

# https://stackoverflow.com/a/13658950/2752670
L=$'\n'
# https://askubuntu.com/a/385532/1042664
i=0
# datetimestamp as dir name 
dt=$(date +"%Y%m%d_%H%M%S")

# ----------------------

mkdir $dt

cd $dt

git init

touch README.md

# ----------------------

modify_and_commit()
{
  msg="commit $((++i))"
  
  echo "${msg}${L}" >> README.md
  
  git add -A
  
  git commit -m "${msg}"
}

# ----------------------

modify_and_commit

modify_and_commit
git tag v1.2.1

modify_and_commit
git tag v1.2.2

modify_and_commit
git tag v1.2.3-pre

modify_and_commit
git tag v1.2.3

modify_and_commit
git tag v1.2.4-abc

modify_and_commit
git tag v1.2.4

modify_and_commit
git tag v1.2.5

modify_and_commit
git tag v1.3.1

modify_and_commit
git tag v1.3.2-pre

modify_and_commit
git checkout -b dev
modify_and_commit

git checkout master
modify_and_commit

```



# 参考

- Golang 官方文档，关于 `@` 的使用：[文档 1](https://golang.org/cmd/go/#hdr-Module_queries)、[文档 2](https://golang.org/cmd/go/#hdr-Add_dependencies_to_current_module_and_install_them)
- `@>`、`@>=`、`@<`、`@<=` 等的 [源码参考](：https://github.com/golang/go/blob/master/src/cmd/go/internal/modload/query.go#L128)
- [Golang 更多伪版本号的格式、来源](https://github.com/vikyd/note/blob/master/go_pseudo_version.md)
- Golang 官方文章翻译：
  - [Semantic Import Versioning（基于语义的 import 版本管理）](https://github.com/vikyd/note/blob/master/go_and_versioning/semantic_import_versioning.md)
  - [Minimal Version Selection（最小版本选择）](https://github.com/vikyd/note/blob/master/go_and_versioning/minimal_version_selection.md)

