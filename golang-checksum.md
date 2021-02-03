# Golang 的 go module 校验值计算方式

Golang 的 modules（模块）使用了一些哈希校验值来防止源码被篡改，以更安全地使用第三方依赖。

哈希值的计算方式并非单纯对 go.mod、源码 zip 包 进行简单 SHA-256 运算。但计算方式也不算复杂，而且也是基于 SHA-256 和 Base64。

写文本时也顺便写了个计算这种特殊哈希的工具 https://github.com/vikyd/go-checksum 。

# 目录

<!--ts-->
   * [Golang 的 go module 校验值计算方式](#golang-的-go-module-校验值计算方式)
   * [目录](#目录)
   * [go.sum 中哪些字符串是哈希值？](#gosum-中哪些字符串是哈希值)
      * [简单](#简单)
      * [详细](#详细)
   * [哈希值计算方式：简述版](#哈希值计算方式简述版)
      * [go.mod 的哈希值计算方式](#gomod-的哈希值计算方式)
      * [模块全部内容 的哈希值计算方式](#模块全部内容-的哈希值计算方式)
   * [哈希值计算方式：详细版](#哈希值计算方式详细版)
      * [go.mod 的哈希值计算方式](#gomod-的哈希值计算方式-1)
      * [模块全部内容 的哈希值计算方式](#模块全部内容-的哈希值计算方式-1)
   * [思考 &amp; 问题](#思考--问题)
      * [为何 Golang 需要求模块的哈希值？](#为何-golang-需要求模块的哈希值)
      * [为何既要整个模块的哈希值，还要 go.mod 哈希值？](#为何既要整个模块的哈希值还要-gomod-哈希值)
      * [为何 Golang 模块哈希计算如此奇怪？](#为何-golang-模块哈希计算如此奇怪)
      * [为何不对整个模块打包 zip 求哈希？](#为何不对整个模块打包-zip-求哈希)
   * [备注](#备注)


<!--te-->

# go.sum 中哪些字符串是哈希值？

## 简单

`h1:` 之后那一串就是哈希值，基于 SHA-256、Base64。

例如后面例子中的 `3tMoCCfM7ppqsR0ptz/wi1impNpT7/9wQtMZ8lr1mCQ=`

## 详细

使用 Golang modules 后，每个项目下都会出现 go.sum 文件，内容类似：

```
github.com/gin-gonic/gin v1.4.0 h1:3tMoCCfM7ppqsR0ptz/wi1impNpT7/9wQtMZ8lr1mCQ=
github.com/gin-gonic/gin v1.4.0/go.mod h1:OW2EZn3DO8Ln9oIKOvM++LBO+5UPHJJDH72/q/3rZdM=
```

上述内容的格式可理解为：

```
module version hashMethod:checksumBase64Text
module version/go.mod hashMethod:checksumBase64Text
```

- 两行：一行是该模块该版本全部内容的综合哈希值，另一行是该模块该版本中 go.mod 这个文件内容的综合哈希值。
- `module`：模块名，也即 go 源码使用该模块时的 import 前缀。
- `version`：版本号
- `hashMethod`：可以是 SHA-256 或其他哈希算法，Golang 约定以 `h1` 指代 SHA-256 算法，若以后采用其他哈希算法，可能会出现 `h2`、`h3` 之类的算法代号。目前（至少 2019 年内），都只用到了 `h1`。
- `checksumBase64Text`：以 Base64 形式展示的哈希值。本文将详细介绍如何计算此值（不是纯粹 SHA-256）

参考：https://golang.org/cmd/go/#hdr-Module_authentication_using_go_sum

# 哈希值计算方式：简述版

## `go.mod` 的哈希值计算方式

> 即 go.sum 中的第 2 行

- 先计算 go.mod 内容本身的 SHA-256 值（设为 H）
- 再计算 `H go.mod\n` 这个字符串的 SHA-256 值（设为 mixedH）
- 以 Base64 编码 mixedH（设为 finalH）

则 finalH 就是 go.sum 中的 go.mod 行最后的哈希值。

## `模块全部内容` 的哈希值计算方式

> 即 go.sum 中的第 1 行

- 输入：
  - 模块版本路径（如 `github.com/gin-gonic/gin@v1.4.0`）
  - 模块所在目录路径（如 `/dir01/dir02/gin`）
- 遍历模块目录内所有文件，对每个文件计算其内容的 SHA-256 值（设为 H）
- 再计算每个文件 `H github.com/gin-gonic/gin@v1.4.0/具体文件路径\n` 这个字符串的 SHA-256 值（设为 mixdH）
- 将前面各文件的 mixedH（多少个文件就有多少个 mixedH） 按文件名顺序直接拼在一起，再次求 SHA-256 值（设为 mixedAllH）
- 以 Base64 编码 mixedAllH（设为 finalH）

则 finalH 就是 go.sum 中的模块行最后的哈希值。

---

至此，Golang 的 go module 校验值计算方式已讲完。

可用 [此工具](https://github.com/vikyd/go-checksum) 进行计算。

若有兴趣，可继续往下看详细版。

# 哈希值计算方式：详细版

## `go.mod` 的哈希值计算方式

> 即 go.sum 中的第 2 行

步骤：

- 输入：`go.mod` 文件的路径
- 读取 `go.mod` 文件的内容，设为变量 `content`
- 计算 `content` 的 SHA-256 哈希值，设为变量 `hash`
- 构建如下字符串（中间是 2 个空格），设为变量 `mixedHash`
  - ```
    hash  go.mod\n
    ```
  - 若 `hash` = `CDa7N`（假设而已，实际长度更长些）
  - 则 `mixedHash` 为：
  - ```
    CDa7N  go.mod\n
    ```
  - 这个字符串看起来很奇怪吧，但 Golang 就是这么做的
- 计算 `mixedHash` 的 SHA-256 哈希值，设为变量 `hashSynthesized`
- 将 `hashSynthesized` 进行 Base64 编码，设为变量 `hashSynthesizedBase64`
- 在 `go.sum` 文件中的校验值的形式是：`h1:hashSynthesizedBase64`，设为变量 `GoCheckSum`
  - 若 `hashSynthesizedBase64` = `CCfM7`（假设而已，实际长度更长些）
  - 则 `GoCheckSum` = `h1:CCfM7`
  - `h1`：代表 SHA-256，以后使用其他算法会采用 `h2`、`h3` 之类的代号，`h` 可理解为 Hash 一词的首字母
  - [参考文档](https://tip.golang.org/cmd/go/#hdr-Module_authentication_using_go_sum)

## `模块全部内容` 的哈希值计算方式

> 即 go.sum 中的第 1 行

步骤：

- 输入：
  - 模块的所在目录
  - 模块的 ImportPrefix（之所以需要这个，是因为会被作为内容计算哈希值）
- 整理模块所在目录路径（例如，删除重复的路径分隔符 `/` 等）
- 遍历模块目录中的所有文件：
  - 只考虑文件，不考虑目录
  - 忽略 `.git` 目录内的所有文件
  - 找出每个文件的相对于模块目录的相对路径
  - 将文件相对路径与 ImportPrefix 拼在一起，设为变量 `fileImportPath`
  - 例如：
    - 模块中有一个文件 [gin.go](https://github.com/gin-gonic/gin/blob/v1.4.0/gin.go)
    - 模块目录为：`/dir01/dir02/gin`
    - 该文件绝对路径为：`/dir01/dir02/gin/gin.go`
    - 则其相对路径为：`gin.go`
    - 则 `fileImportPath` = `github.com/gin-gonic/gin@v1.4.0/gin.go`
- 上述遍历结束后，我们得到一个 `fileImportPath` 列表，设为变量 `files`
- 对 `files` 进行升序排序
- 然后开始进行哈希计算
- 遍历排序后的 `files`
  - 从 `files` 中读取一个文件的内容，设为 `content`
  - 计算 `content` 的 SHA-256 哈希值，设为 `hash`
  - 构建如下字符串（中间是 2 个空格），设为变量 `mixedHash`
    - ```
      hash  fileImportPath\n
      ```
    - 若 `hash` = `CDa7N`（假设而已，实际长度更长些）
    - 若 `fileImportPath` = `github.com/gin-gonic/gin@v1.4.0/gin.go`
    - 则 `mixedHash` 为：
    - ```
      CDa7N  github.com/gin-gonic/gin@v1.4.0/gin.go\n
      ```
    - 这个字符串看起来也很奇怪吧，但 Golang 就是这么做的
- 遍历结束后，我们可得到一个由各个文件的 `mixedHash` 直接拼成的一个长字符串，设为变量 `mixedHashAll`
  - 例如：
  - ```
    CDa7N  github.com/gin-gonic/gin@v1.4.0/gin.go\nEFb8M  github.com/gin-gonic/gin@v1.4.0/context.go\n ...
    ```
- 对 `mixedHashAll` 计算 SHA-256 哈希值，设为变量 `hashSynthesized`
- 将 `hashSynthesized` 转换为 `Base64`，设为变量 `hashSynthesizedBase64`
- 在 `go.sum` 文件中的校验值的形式是：`h1:hashSynthesizedBase64`，设为变量 `GoCheckSum`
  - 若 `hashSynthesizedBase64` = `CCfM7`（假设而已，实际长度更长些）
  - 则 `GoCheckSum` = `h1:CCfM7`
  - `h1`：代表 SHA-256，以后使用其他算法会采用 `h2`、`h3` 之类的代号，`h` 可理解为 Hash 一词的首字母
  - [参考文档](https://tip.golang.org/cmd/go/#hdr-Module_authentication_using_go_sum)
- 总之，不是对全部内容的 zip 包进行哈希，而是对每个文件内容。

# 思考 & 问题

## 为何 Golang 需要求模块的哈希值？

答：一句话：安全考虑。具体方案细节也挺多，可参考 Golang 官方的其他文章。

## 为何既要整个模块的哈希值，还要 go.mod 哈希值？

答：[The go.mod-only hash allows downloading and authenticating a module version's go.mod file, which is needed to compute the dependency graph, without also downloading all the module's source code.](https://golang.org/cmd/go/#hdr-Module_authentication_using_go_sum)

已有模块哈希，还需 go.mod 哈希的原因：可无需下载整个模块内容即可找到子依赖，使得可以并行下载多个依赖。

## 为何 Golang 模块哈希计算如此奇怪？

答：

- 确实，拼接字符串的方式有点奇怪，看着不太优雅，但能起作用

## 为何不对整个模块打包 zip 求哈希？

答：估计是因为：

- 避免对 zip 算法的依赖
  - 若 zip 压缩算法有修改优化，导致最终的 zip 包的字节略不一样了，也就会导致模块的哈希发生变化
- 避免打包后的 zip 太大，即没必要去产生一个更大的临时文件
- 所以只依赖文件内容应是最根本的方法

# 备注

- 本文主要参考 [Golang 的部分源码](https://github.com/golang/go/blob/master/src/cmd/go/internal/dirhash/hash.go) 理解而得
- Golang 的 modules 是一个有趣的依赖管理综合方案，区别于其他语言的包管理器，有不少关于版本、安全等多个方面的创新，值得去深入了解。
