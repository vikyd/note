# 为何配置 Golang 内网开发环境那么多坑？

在内网配置 Golang 开发环境容易踩很多坑，有时踩到怀疑人生。

想从本质聊下坑源自何处，更清晰的定位思路。

若有错，请告诉一声。

> 不聊细节，不聊包版本号的机制。也不聊包管理器的各个方面，话题太大。

# 目录

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [从包管理器的本质工作说起](#%E4%BB%8E%E5%8C%85%E7%AE%A1%E7%90%86%E5%99%A8%E7%9A%84%E6%9C%AC%E8%B4%A8%E5%B7%A5%E4%BD%9C%E8%AF%B4%E8%B5%B7)
- [Go Module 的解决方式](#go-module-%E7%9A%84%E8%A7%A3%E5%86%B3%E6%96%B9%E5%BC%8F)
  - [`去中心化` 机制](#%E5%8E%BB%E4%B8%AD%E5%BF%83%E5%8C%96-%E6%9C%BA%E5%88%B6)
    - [优点](#%E4%BC%98%E7%82%B9)
    - [引发的坑](#%E5%BC%95%E5%8F%91%E7%9A%84%E5%9D%91)
  - [`安全` 机制](#%E5%AE%89%E5%85%A8-%E6%9C%BA%E5%88%B6)
    - [如何保证安全](#%E5%A6%82%E4%BD%95%E4%BF%9D%E8%AF%81%E5%AE%89%E5%85%A8)
    - [引发的坑](#%E5%BC%95%E5%8F%91%E7%9A%84%E5%9D%91-1)
  - [一图概述](#%E4%B8%80%E5%9B%BE%E6%A6%82%E8%BF%B0)
  - [Go 自身的不足](#go-%E8%87%AA%E8%BA%AB%E7%9A%84%E4%B8%8D%E8%B6%B3)
- [与 Golang 无关的内网本身的坑](#%E4%B8%8E-golang-%E6%97%A0%E5%85%B3%E7%9A%84%E5%86%85%E7%BD%91%E6%9C%AC%E8%BA%AB%E7%9A%84%E5%9D%91)
- [能否有一键填坑工具？](#%E8%83%BD%E5%90%A6%E6%9C%89%E4%B8%80%E9%94%AE%E5%A1%AB%E5%9D%91%E5%B7%A5%E5%85%B7)
- [能否搭建内网的 GOPROXY、GOSUMDB 解决所有问题？](#%E8%83%BD%E5%90%A6%E6%90%AD%E5%BB%BA%E5%86%85%E7%BD%91%E7%9A%84-goproxygosumdb-%E8%A7%A3%E5%86%B3%E6%89%80%E6%9C%89%E9%97%AE%E9%A2%98)
- [小结](#%E5%B0%8F%E7%BB%93)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

[TOC]

# 从包管理器的本质工作说起

包管理器可减轻我们对依赖外部代码的管理负担，是个好东西。

包管理器的职责可能包括（但不限于）：

- 版本号形式?
- 如何发布依赖包？
- 依赖包的下载方式？
- 如何防止依赖包内容篡改？
- 如何处理依赖包版本间兼容关系？
- 等等很多 ......

# Go Module 的解决方式

历史：Golang 的包管理器发展过程坎坷，从最开始的无包管理器，到第三方包管理器百花齐放，到现在（2021 年）尘埃落定为 [Go Modules 方案](https://github.com/golang/go/wiki/Modules) 。

疑惑：历时多年确定下来的 Go Module 按理说用起来应该很丝滑才对，为何开发者配置开发环境时依然会踩那么多坑？（特别是公司内网中）

Golang 为了做得更好，采取了以下两个原则（但不限于）：

- 去中心化
- 安全

上述两个原则，个人认为是引发 Go Module 内网配置环境时各种坑的主要诱发原因。

## `去中心化` 机制

去中心化：无需将依赖包发布到 **某个网站**，可直接从源码网站（如 GitHub）获取依赖包。

### 优点

- 开发者方面
  - 无需注册传统包管理器网站账号即可发布依赖包版本
    - 减轻开发者负担
    - 反例，需要先注册账号的包管理器：
      - [npm](https://docs.npmjs.com/creating-and-publishing-unscoped-public-packages)
      - [Maven](https://juejin.cn/post/6844904143904210958)

> GOPROXY 不算中心化，因为没有 GOPROXY 依然能正常运作

### 引发的坑

- 坑：依赖 Git
  - 若想直接从源码网站下载依赖包，需安装对应的 VCS 工具
  - Git 命令不成功，会导致依赖包下载不成功，即 Git 本身的所有坑，也会成为 Go Module 使用过程中的坑
    - Git 可能的坑很多，包括但不限于：
      - 若走 HTTPS，则需输入用户名密码
      - 若走 SSH，则需预先配置 SSH 公钥私钥
      - 若是内网、远程环境，可能还得为 HTTPS、SSH 配置各自的代理
      - Git 自身版本不能太低
      - 等等还有很多 ......

## `安全` 机制

什么是不安全：

- 下载时内容被篡改
- 不小心自动升级到了有 bug 的依赖包版本

安全：就是能避免上述问题

### 如何保证安全

- 引入 [GOSUMDB](https://github.com/vikyd/note/blob/master/secure_the_public_go_module_ecosystem.md) 机制
  - 类似区块链的 [校验机制](https://github.com/vikyd/note/blob/master/translate-transparent_logs_for_skeptical_clients.md)，使得依赖包内容一旦被篡改，必然能被发现
- 引入 [GOPROXY](https://proxy.golang.org/) 机制
  - 可避免因源码网站依赖包若被删导致项目不可构建，因为 GOPROXY 会缓存依赖包
- 引入 [基于语义的版本号](https://github.com/vikyd/note/blob/master/go_and_versioning/semantic_import_versioning.md) 和 [最小版本选择](https://github.com/vikyd/note/blob/master/go_and_versioning/minimal_version_selection.md) 机制
  - 默认不自动升级依赖包版本，避免因自动升级带来的不确定性

### 引发的坑

- GOSUMDB 中的模块只能是公开模块，不能是公司内网的模块
  - 因为 GOSUMDB 必须实现 [lookup 接口](https://github.com/vikyd/note/blob/master/go_mod_secure_detail.md#%E6%8E%A5%E5%8F%A3lookupmodulepathversion-%E6%A8%A1%E5%9D%97%E7%89%88%E6%9C%AC%E5%93%88%E5%B8%8C%E5%8F%8A%E5%AD%90%E6%A0%91%E7%AD%BE%E5%90%8D%E6%A0%B8%E5%BF%83) ，此接口必然会泄露内网模块的 [import path](https://golang.org/doc/code#Organization)
  - 坑：有内网模块时，必须通过 GOPRIVATE（或 GOSUMDB=off） 区分公共模块和内网非公开模块
    - 这就增加了用户的心智负担，且初用者大概率会忘记配置
- GOPROXY 相关的坑
  - 同样需通过 GOPRIVATE 或（或 GOPROXY=direct）来区分公共模块和内网模块
    - 因为公网用户不能通过官方 GOPROXY 获取到内网依赖包
  - 初用者容易将 GOPROXY 与 https_proxy 误解为同样功能的东西（实质是完全不同的概念）

## 一图概述

下图的任何一个环节出错，都可能会导致 Go 下载或校验依赖包失败。

![](https://raw.githubusercontent.com/vikyd/note-bigfile/master/img/gomod.png)

## Go 自身的不足

出错时，错误信息不足，例如：

- `git ... reading ... at revision ... : unknown revision ...`：
  - 多数情况时因为 git 下载依赖包失败，开发者可能不知道下载依赖包时用到了 git，即使知道是 git 但不知道 git 的哪个配置有问题，开发者只能四处搜填坑方案
- `invalid version: git fetch -f origin refs/heads/*:refs/`：
  - 经常情况缓存重试就行 `go clean -x --modcache`，但是什么原因导致的错误？未知

# 与 Golang 无关的内网本身的坑

- 有些公司内网需配置 HTTP 代理才能访问公网
  - Golang 与 HTTP 代理的关系
    - Golang 获取 [go-import](https://golang.org/cmd/go/#hdr-Remote_import_paths) ：基于 HTTPS GET
    - 从 GOPROXY 获取依赖包基于：HTTPS GET
    - 从 GOSUMDB 获取校验信息基于：HTTPS GET
  - 所以，https_proxy、no_proxy 没配置或配置不正确，都会导致上述 3 种情况失败
  - 若内网有些环境需代理、有些环境不需代理，问题更复杂了
- 有些公司内网域名不是公网域名
  - 不是公网域名，会导致浏览器无法 [验证](http://www.ruanyifeng.com/blog/2011/08/what_is_a_digital_signature.html) HTTPS 证书，从而导致出现类似 `x509` 的错误
    - 此时需安装内网对应网站 HTTPS 对应的证书
      - Mac 中安装证书需管理员权限、有时证书会自动变不信任需重新信任

# 能否有一键填坑工具？

可以有，但可能不完美，甚至可能带来额外的问题。

- 因为涉及的方面较多：Git 的各种配置、HTTPS 证书的安装和权限、内网环境的判断、环境变量配置、GoLand、Win 和 Mac
- 修改各种配置文件可能会与开发者自行的配置冲突
- SSH 公钥粘贴到源码网站，这步貌似无法通过简单工具实现
- 即使是内网，可能也有不同的环境，有些需代理、有些无需代理

# 能否搭建内网的 GOPROXY、GOSUMDB 解决所有问题？

假设内网搭建了 GOPROXY、GOSUMDB 服务，且采用的是公网域名，能否彻底让各位 Gopher 少踩各种坑？

- 能解决的问题:
  - 增加对内网公开（但公网不公开）模块的：
    - SUMDB 校验，提高了安全性，防止内网模块被篡改
    - 依赖包内容缓存，以免内网源码网站对应依赖包版本被删导致项目不能构建
    - 公司内部开发人员配置不当造成 import path 泄露到公网
    - 缓存热点代码依赖，可降低公司公网出口带宽
- 不能解决的问题：
  - 内网的私有依赖包（即使在内网，也仅部分人有权限的依赖包）
    - 此时前面所说的所有坑，都依然避免不了，因为私有包都不能经过 GOPROXY、GOSUMDB，且只能通过 Git 直接获取源码

总的来说：

- 若处于内网，且所有项目代码都是内网公开的，则内网的 GOPROXY、GOSUMDB 几乎解决所有问题
- 若内网中依然有非公开的项目源码，则该踩的坑一个都不会少
  - 笔者依然会选择官方默认的 GOPROXY、GOSUMDB（`proxy.golang.org`、`sum.golang.org`）、自行安装 HTTPS 证书、自行配置 HTTP 代理、自行配置 SSH Key

# 小结

包管理器 `去中心化`、`安全` 都是 Golang 包管理机制的目的之一，GOPROXY、GOSUMDB 都是合理的存在。只是在达到这个目的的过程中，会附带一些条件和约束，例如：

- 源码网站即使是内网网站，也应采用公网域名
- 本来就要区分内网依赖包、公网依赖包，只是其他包管理器是通过搭建内网镜像源，Go 是通过环境变量 GOPRIVATE 来区分
- 内网访问外网应尽量无需配置 HTTP 代理，应对内网用户尽量透明无感知
- 对 Git 的依赖本就是开发者的开发环境的基本要求

很多坑来自于内网环境本身的不合理、来自于开发者自己电脑的开发环境不完善。这些不合理，本就不应存在，与 Golang 无关。

踩好这几样抗，一般问题不大，出问题时也是按排除法逐项排查：

- HTTPS 代理
- HTTPS 证书
- GOPRIVATE
- Git clone

Go Module 只是在促成更好的包管理器时，暴露了包管理器之外的环境的不合理之处。当然 Go 自身的出错提示信息不足，也是一大因素。
