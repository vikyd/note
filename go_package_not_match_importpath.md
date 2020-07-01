# Golang 的 import path 与根目录 package name 不匹配的处理方式

使用 Golang 的第三方依赖包时，通常不会碰到本文的情况，但万一真碰到了，可参考本文进行 import 使用。


# 目录
[TOC]


# 不匹配的案例

不匹配的仓库：https://github.com/vikyd/pkgnotmatch

即 import path：`github.com/vikyd/pkgnotmatch`

仓库内的文件：

```
├── README.md
└── a.go
```

文件 `a.go` 内容：

```go
package abc

import "fmt"

func F01() {
	fmt.Println("from package abc")
}
```

注意：

- `a.go` 的包名是 `abc`
- 而此仓库的 import path 是 `github.com/vikyd/pkgnotmatch`，最后部分是 `pkgnotmatch`
- 即 `pkgnotmatch` 与 `abc` 不匹配


问题来了：项目中该如何 import 此库？




# 如何 import 不匹配的库

## 案例
参考：https://github.com/vikyd/pkgnotmatch-use

首先 clone 此仓库（或直接下载）：

```sh
git clone git@github.com:vikyd/pkgnotmatch-use.git
```

执行 `main.go`：

```sh
go run main.go

cd pkgnotmatch-use
```

会输出类似下面文字：

```
main
from package abc
```


## 案例解释

虽然 `pkgnotmatch` 与 `abc` 不匹配，但还是可以被 import 的。

可成功 import 的方式：

```go
import "github.com/vikyd/pkgnotmatch"

abc.F01()
```


```go
import abc "github.com/vikyd/pkgnotmatch"

abc.F01()
```


```go
import othername "github.com/vikyd/pkgnotmatch"

othername.F01()
```

结论：

- import 时按原 import path 进行 import，但实际调用时，需以根目录的 package name 为准，如：`abc.F01()`
- 另一种方法是 import 时给一个别名（最好与其根目录实际包名一致），如：`import abc "github.com/vikyd/pkgnotmatch"`




# go mod 版的例子

不匹配的仓库：https://github.com/vikyd/importnotmatchmod

使用方式：https://github.com/vikyd/importnotmatchmod-usage

