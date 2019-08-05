# URL 中 QueryString 与 Fragment 的困惑

# 名词约定

- `query string`：中文可叫 `查询字符串`，指 `?` 之后，且以 `&` 分隔多个键值对，且以 `=` 分隔键与值，的片断

- `fragment`：未找到中文叫啥。有时又被叫做 `Anchor` 或 `Hash`，意思一样，都是指 URL 中 `#` 之后的片断

# 测试验证

具体可在浏览器中打开 F12 输入查看：

- `window.location.search`
  - 查询 `QueryString`
  - 如 `https://www.baidu.com/?a=123` 则得 `?a=123`
- `window.location.hash`
  - 查询 `Fragment`
  - 如 `https://www.baidu.com/#aaa` 则得 `#aaa`

# 疑惑

- 多个 `?` 会发生什么事？
- `?` 中多个 key 相同会发生什么事？
- `#` 是否可以在 `?` 之前？
- 多个 `#` 会发生什么事？
- 等等

没找有统一说明这些问题的文章，所以这里自己写一下。

# 实例

## 正常的例子

例：`http://example.com:8080?a=1&b=n#xx`

- QueryString:
  - `a`: `1`
  - `b`: `n`
- Fragment:
  - `#`: `xx`

结论：上述例子应无太多疑惑，很正常的使用方式。

## 多个 `?` 时，最终的 QueryString 是什么？

例：`?a=1?b=2&c=3`

答：最终是

- `a`: `1?b=2`
- `c`: `3`

结论：仅第 1 个 `?` 有效（标明后面是 QueryString），后面的 `?` 都作为 key=value 中的 value。

## `&` 字符本身如何才能作为值？

`&` 是 QueryString 中 key 与 value 的分隔符，若需其作为 value 的一部分，则需转义。

例：`?a=1%261&b=2`

答：最终是

- `a`: `1%261`
- `b`: `2`

## QueryString 中多个连续的 `&` 有没有什么用？

例：`?a=1&&b=2&&`

答：最终是

- `a`: `1`
- `b`: `2`

结论：QueryString 中多个连续 `&` 会被忽略（实例可参考前面 Chrome 验证方式）。
结论：其中 `%26` 是 `&` 经过 [urlencode](https://en.wikipedia.org/wiki/Percent-encoding) 得到的编码，若直接填 `&` 而非 `%26` 则会被忽略。

## QueryString 中单独的 `&` 会发生什么？

例：`?a=1&b=&2&`

答：最终是

- `a`: `1`
- `b`: ``（空）
- `2`: ``（空）

## QueryString 中有个多个同名 key，结果是什么？

例：`?a=1&a=2`

答：[并无规范对此进行定义](https://stackoverflow.com/a/1746566/2752670)，因此各软件的实现不一样。

以 Chrome 76.0.3809.87 为例：

1. 打开网址：`https://www.baidu.com/?a=1&a=2`
2. 按 F12，在开发者界面的 Console 中输入以下内容：

```js
var urlParams = new URLSearchParams(window.location.search)
console.log(urlParams.get('a'))
```

可得，输出是：`1`。

结论：Chrome 是以第一个 key 的值作为最终值，但这只是 Chrome 的行为，并不代表其他软件也是这样。

- TODO: 列举各语言的主要实现方式 Python、PHP、Go、Node、Java
- 参考：
  - https://github.com/vikyd/note/tree/master/content-type-urlencode

## 多个 `#` 时，最终的 Fragment 是什么？

例：`#xx#yy#zz`

答：仅以第 1 个 `#` 之后直至 URL 结尾的全部内容作为 Hash，即：

- `#`: `xx#yy#zz`

以 Chrome 76.0.3809.87 为例：

1. 打开网址：`https://www.baidu.com/#xx#yy#zz`
2. 按 F12，在开发者界面的 Console 中输入以下内容：

```js
window.location.hash
```

可得，输出是：`#aa#bb#cc`。

## `?` 与 `#` 谁的优先级高？

换个问法，下面例子，最终得到的 QueryString、Fragment 分别是什么？

### 例：`?a=1#xx?b=2`

答：最终是

- QueryString:
  - `a`: `1`
- Fragment:
  - `#`: `xx?b=2`

### 例：`#xx?b=2#yy`

答：最终是

- QueryString: 无
- Fragment：
  - `#`: `xx?b=2#yy`

验证：

- `window.location.search`
- `window.location.hash`

结论：`?` 为先，`#` 为后，且仅有效一次。

理由：抄录 RFC3986：

### [section-3.4 ↓](https://tools.ietf.org/html/rfc3986#section-3.4)

> The query component is indicated by the first question mark ("?") character and terminated by a number sign ("#") character or by the end of the URI.

说人话：Query 是以 `?` 开头，且以 `#` 结尾或直至 URI 的结尾。

### [section-3.5 ↓](https://tools.ietf.org/html/rfc3986#section-3.5)

> A fragment identifier component is indicated by the presence of a number sign ("#") character and terminated by the end of the URI.

说人话：Fragment 是以 `#` 开头，直至 URI 结尾。

`Fragment` 又可名为 `Anchor` 或 `Hash`。

# 其他问题

本文暂不回答以下问题，请自行 Google：

- URL 有哪些部分？
- [urlencode 或 百分号编码 是什么？](https://aotu.io/notes/2017/06/15/The-mystery-of-URL-encoding/index.html)
- 什么是 URL 保留字符？
- HTTP Header 中 `Content-Type: application/x-www-form-urlencoded` 与 QueryString 的关系？

# 参考

- https://tools.ietf.org/html/rfc3986
