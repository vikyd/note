# 技巧：VSCode 调试 Golang 自身源码

> `Golang 自身源码` 是指：`/usr/local/go/src` 的源码，或说 https://github.com/golang/go 的源码

VSCode 可快速对 Golang 自身源码进行 debug 调试。

> 更准确说，可快速对 Golang 中的测试用例进行调试


# 前提
本文不详述，并认为你已能做到以下几点：

- 命令行 go get、go mod 内网、外网依赖包都没问题
- VSCode 中已能 [debug 打断点](https://github.com/Microsoft/vscode-go/wiki/Debugging-Go-code-using-VS-Code) 最简单的 [main.go](https://play.golang.org/p/MAohLsrz7JQ)
- [能命令行以 VSCode 打开指定目录](https://stackoverflow.com/a/36882426/2752670)



# 开始 debug
下面以 Mac 为例。

假设你的 Golang 安装位置在 `/usr/local/go`，即默认的 `GOROOT`。

1. 命令行中执行以下命令，表示以 VSCode 打开 Golang 自身源码：

```sh
code /usr/local/go/src

# 或 

code $GOROOT/src
```

2. 随便打开一些测试用例，如 VSCode 中打开这两个文件：

```
path/path.go
path/path_test.go
```

3. 在 `path/path.go` 中 `func Ext( ...` 函数内打个断点，如 [这行](https://github.com/golang/go/blob/master/src/path/path.go#L171)：

```go
func Ext(path string) string {
	for i := len(path) - 1; i >= 0 && path[i] != '/'; i-- {
		if path[i] == '.' {
			return path[i:]
		}
	}
	return ""
}
```

4. 打开 `path/path_test.go` 文件，按下 `F5`，等一小会，应会在刚打断点的行停下来

5. 演示完毕



# 用途？
若对 Golang 内部机制有疑惑，可通过调试 Golang 自身源码对应功能的用例来证明自己的想法。

例如，想了解 [go get `@` 的各种用途](https://github.com/vikyd/note/blob/master/gomod_goget_at.md)，可调试 [这个文件](https://github.com/golang/go/blob/master/src/cmd/go/internal/modload/query_test.go#L123)。
