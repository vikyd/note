# 实例演示：Golang go mod 同一仓库多模块、多主版本并存

Golang 的 go mod 模式有很多与众不同的设计，其中之一就是：同一仓库中允许同时存在多个模块、多个不同主版本。

个人理解，其关键点就是：

- 以子目录方式存放子模块（不是子包）或不同主版本
- 打 tag 时，tag 名称记得带上子目录
  - 如：子模块所在子目录为 `abc`，则打 tag 时应为类似 `abc/v1.2.3`，即可
- 子目录中的 go.mod 的模块路径应适当修改为对应路径

# 目录

<!-- START doctoc -->
<!-- END doctoc -->

# 实例

定义：https://github.com/vikyd/submodule01

使用：https://github.com/vikyd/import-submodule

更多文档、更多使用方式，请见上述两个仓库的 README.md 说明。

下面是单一仓库中，多模块、多主版本并存时的大致结构（及 go.mod 的模块名）；

```
├── README.md
├── a.go
├── go.mod          --> `module github.com/vikyd/submodule01`
│
├── v2
│   ├── README.md
│   ├── a.go
│   └── go.mod      --> `module github.com/vikyd/submodule01/v2`
│
└─── module01
    ├── README.md
    ├── b.go
    ├── go.mod      --> `module github.com/vikyd/submodule01/module01`
    └── v2
        ├── README.md
        ├── b.go
        └── go.mod  --> `module github.com/vikyd/submodule01/module01/v2`
```

因上述两仓库的文档已包含详细可操作说明，本文到此结束。

# 参考

- 定义 Go 语言的模块（Module）
  - [英文原文](https://research.swtch.com/vgo-module)
  - [中文译文](https://github.com/vikyd/note/blob/master/go_and_versioning/defining_go_modules.md)
