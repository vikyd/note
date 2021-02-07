# go get 在 go mod 项目与非 go mod 项目中的区别

# 目录

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [在 go mod 项目中](#%E5%9C%A8-go-mod-%E9%A1%B9%E7%9B%AE%E4%B8%AD)
- [在非 go mod 项目中](#%E5%9C%A8%E9%9D%9E-go-mod-%E9%A1%B9%E7%9B%AE%E4%B8%AD)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 在 go mod 项目中

- `go get` 会下载到 `$GOPATH/pkg/mod` 对应目录中
- go mod 项目中的所有依赖都来自 `$GOPATH/pkg/mod`，与 `$GOPATH/src` 无关
- 此时的 go get 类似于 npm 的 [npm install --save](https://stackoverflow.com/a/19578808/2752670)，会在 go.mod 文件中增加一条依赖

# 在非 go mod 项目中

- `go get` 会下载到 `$GOPATH/src` 对应目录中
- 与 `$GOPATH/pkg/mod` 无关
