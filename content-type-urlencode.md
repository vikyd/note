# 由 urlencode、HTTP Content-Type、嵌套数组想到的

# 目录

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [起因](#%E8%B5%B7%E5%9B%A0)
- [原因](#%E5%8E%9F%E5%9B%A0)
- [解决](#%E8%A7%A3%E5%86%B3)
- [下面比较长，需配合实例来验证](#%E4%B8%8B%E9%9D%A2%E6%AF%94%E8%BE%83%E9%95%BF%E9%9C%80%E9%85%8D%E5%90%88%E5%AE%9E%E4%BE%8B%E6%9D%A5%E9%AA%8C%E8%AF%81)
- [由此引发的思考](#%E7%94%B1%E6%AD%A4%E5%BC%95%E5%8F%91%E7%9A%84%E6%80%9D%E8%80%83)
- [urlencode 了解](#urlencode-%E4%BA%86%E8%A7%A3)
  - [urlencode 允许的字符](#urlencode-%E5%85%81%E8%AE%B8%E7%9A%84%E5%AD%97%E7%AC%A6)
  - [urlencode 编码规则](#urlencode-%E7%BC%96%E7%A0%81%E8%A7%84%E5%88%99)
  - [为什么需要 urlencode，而不是直接原始字符编码或二进制发送到服务端？](#%E4%B8%BA%E4%BB%80%E4%B9%88%E9%9C%80%E8%A6%81-urlencode%E8%80%8C%E4%B8%8D%E6%98%AF%E7%9B%B4%E6%8E%A5%E5%8E%9F%E5%A7%8B%E5%AD%97%E7%AC%A6%E7%BC%96%E7%A0%81%E6%88%96%E4%BA%8C%E8%BF%9B%E5%88%B6%E5%8F%91%E9%80%81%E5%88%B0%E6%9C%8D%E5%8A%A1%E7%AB%AF)
- [urlencode 中表示一个空格，应是 `%20`？还是 `+`？](#urlencode-%E4%B8%AD%E8%A1%A8%E7%A4%BA%E4%B8%80%E4%B8%AA%E7%A9%BA%E6%A0%BC%E5%BA%94%E6%98%AF-%E8%BF%98%E6%98%AF-)
  - [urlencode 实验](#urlencode-%E5%AE%9E%E9%AA%8C)
  - [HTTP Content-Type 与 urlencode 关系](#http-content-type-%E4%B8%8E-urlencode-%E5%85%B3%E7%B3%BB)
  - [关系](#%E5%85%B3%E7%B3%BB)
  - [urlencode 编码数组（嵌套数组）](#urlencode-%E7%BC%96%E7%A0%81%E6%95%B0%E7%BB%84%E5%B5%8C%E5%A5%97%E6%95%B0%E7%BB%84)
    - [HTML form submit 嵌套数据的 urlencoded 编码方式](#html-form-submit-%E5%B5%8C%E5%A5%97%E6%95%B0%E6%8D%AE%E7%9A%84-urlencoded-%E7%BC%96%E7%A0%81%E6%96%B9%E5%BC%8F)
    - [jQuery 嵌套数据的 urlencoded 编码方式](#jquery-%E5%B5%8C%E5%A5%97%E6%95%B0%E6%8D%AE%E7%9A%84-urlencoded-%E7%BC%96%E7%A0%81%E6%96%B9%E5%BC%8F)
    - [axios.js 嵌套数据的 urlencoded 编码方式](#axiosjs-%E5%B5%8C%E5%A5%97%E6%95%B0%E6%8D%AE%E7%9A%84-urlencoded-%E7%BC%96%E7%A0%81%E6%96%B9%E5%BC%8F)
  - [PHP 嵌套数据的 urlencoded 编码方式](#php-%E5%B5%8C%E5%A5%97%E6%95%B0%E6%8D%AE%E7%9A%84-urlencoded-%E7%BC%96%E7%A0%81%E6%96%B9%E5%BC%8F)
  - [Python urllib.urlencode 嵌套数据的 urlencoded 编码方式](#python-urlliburlencode-%E5%B5%8C%E5%A5%97%E6%95%B0%E6%8D%AE%E7%9A%84-urlencoded-%E7%BC%96%E7%A0%81%E6%96%B9%E5%BC%8F)
  - [py requests 嵌套数据的 urlencoded 编码方式](#py-requests-%E5%B5%8C%E5%A5%97%E6%95%B0%E6%8D%AE%E7%9A%84-urlencoded-%E7%BC%96%E7%A0%81%E6%96%B9%E5%BC%8F)
- [PHP 的 `php://input` 能否读取多次](#php-%E7%9A%84-phpinput-%E8%83%BD%E5%90%A6%E8%AF%BB%E5%8F%96%E5%A4%9A%E6%AC%A1)
  - [`php://input` 是什么？](#phpinput-%E6%98%AF%E4%BB%80%E4%B9%88)
  - [能否读取多次](#%E8%83%BD%E5%90%A6%E8%AF%BB%E5%8F%96%E5%A4%9A%E6%AC%A1)
- [Laravel](#laravel)
  - [服务端](#%E6%9C%8D%E5%8A%A1%E7%AB%AF)
  - [客户端](#%E5%AE%A2%E6%88%B7%E7%AB%AF)
  - [结论](#%E7%BB%93%E8%AE%BA)
- [Codeigniter](#codeigniter)
  - [服务端](#%E6%9C%8D%E5%8A%A1%E7%AB%AF-1)
  - [客户端](#%E5%AE%A2%E6%88%B7%E7%AB%AF-1)
  - [结论](#%E7%BB%93%E8%AE%BA-1)
- [urlencode 与 base64 的区别](#urlencode-%E4%B8%8E-base64-%E7%9A%84%E5%8C%BA%E5%88%AB)
- [`Content-Type` vs `MIME`](#content-type-vs-mime)
- [杂](#%E6%9D%82)
- [总结](#%E6%80%BB%E7%BB%93)
  - [HTTP Client（Py requests、浏览器、jQuery、axios）](#http-clientpy-requests%E6%B5%8F%E8%A7%88%E5%99%A8jqueryaxios)
- [HTTP 基础](#http-%E5%9F%BA%E7%A1%80)
- [备注](#%E5%A4%87%E6%B3%A8)
- [名词约定](#%E5%90%8D%E8%AF%8D%E7%BA%A6%E5%AE%9A)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 起因

Python [requests](http://python-requests.org) POST 一个嵌套数据到 PHP Server 时丢失了部分数据。

嵌套数据示例：

```json
{
  "a": 123,
  "b": [789, { "c": 456 }]
}
```

# 原因

浏览器 jQuery 直接用 obj 向 PHP 发送 POST 请求：

- 默认：`Content-Type: application/x-www-form-urlencoded`
- 实际发送数据是字符串：`a=123&b[]=789&b[1][c]=456`

py requests 直接用 dict 向 PHP 发送 POST 请求：

- 默认：`Content-Type: application/x-www-form-urlencoded`
- 实际发送数据是字符串：`a=123&b=789&b=c`

PHP Server 接收到的数据：

- jQuery：PHP 的 `$_POST` 有数据，并所有数据均能还原
- py requests：只能还原部分数据，且结构发生了变化

**原因：`application/x-www-form-urlencoded` 原本用于编码 key=val 形式的数据，对嵌套 JSON 形式的数据并无具体规定形式，导致不同 HTTP 客户端的实现各有不同。**

# 解决

py requests 若想发送像 jQuery 那样的字符串（让 PHP Server `$_POST` 能直接解析），则需：

- 显式设置 `Content-Type: application/x-www-form-urlencoded`
- 并将 dict 或类 JSON 结构的对象转换成符合 PHP `$_POST` 能识别的数组字符串
  > 譬如可以用这个 [py 库](https://github.com/vikyd/to_php_post_arr)

---

# 下面比较长，需配合实例来验证

# 由此引发的思考

- 为什么 py requests 和 jQuery 对 `application/x-www-form-urlencoded` 的实现不一致？

- `application/x-www-form-urlencoded` 到底是什么？和 urlencode 的关系？

- `application/x-www-form-urlencoded` 对类似嵌套 JSON 数据是否真的没有标准规定？

- 浏览器、py requests、jQuery、axios 等 HTTP Client，其默认 Content-Type 分别是什么？

  - 是否会因为数据的类型不同而自动采用不同的 Content-Type？
  - 是否会因为 Content-Type 的不同而对数据采用不同的编码方式？

- 发送普通的嵌套数据，Content-Type 及其编码方式的 Best Practice 是什么？`application/x-www-form-urlencoded`？`application/json`？

  - PHP
  - Python requests
  - 浏览器
    - HTML form
    - jQuery
    - axios

- urlencode 和 base64 的区别

  - 编码方式
  - 适用场景

- urlencode 中表示一个空格，应是 `%20`？还是 `+`？

- URL 的长度限制
- HTTP Header 长度限制
- HTTP Body 长度限制

- Content-Type 与 MIME 关系

- Python 的 `urllib.urlencode(data)` 实际输出怎样的字符串

- PHP 的 `php://input` 是否允许读取多次

- PHP 的常用框架的 GET、POST 参数是如何读取的
  - PHP 本身
  - Laravel
  - Codeigniter

---

# urlencode 了解

[urlencode](https://zh.wikipedia.org/wiki/%E7%99%BE%E5%88%86%E5%8F%B7%E7%BC%96%E7%A0%81) 又称：

- URL 编码
- 百分比编码（Percent-encoding）

示例：`http://localhost:8080/server.php?a=中文` 在最终 HTTP 发送时会编码成 `http://localhost:8080/server.php?a=%E4%B8%AD%E6%96%87`

顾名思义 urlencode 中包含 `url`，最开始是为 URL 编码而制定的。

urlencode 不只是用于 HTTP，urlencode 的 URL 是为了统一的命名网络中的一个资源，也可用于如 FTP 等其他协议

urlencode 有一些规范，不同软件、编程语言的实现可能不一样，参考：https://www.zhihu.com/question/19673368/answer/71537081

- 但不管哪个规范，[都没有规定如何编码：数组、对象等类似 JSON 格式的数据](https://stackoverflow.com/a/28590927/2752670)

## urlencode 允许的字符

urlencode 只允许出现以下字符（其他字符一律转换为以下字符串）：

- a-z
- A-Z
- 0-9
- 4 个特殊字符：`-`、`_`、`.`、`~`
- 其他保留字符：`! * ' ( ) ; : @ & = + $ , / ? # [ ]`
  - 即需要使用保留字作为字符串时应转义

## urlencode 编码规则

编码方式：

- `%` 后跟两个十六进制数
- 两个十六进制数 = 2^4 \* 2^4 = 2^8 = 8bit = 1bytes（1 字节）
- 即 `%` 后跟由两个十六进制数表示的 1 字节字符
- 非允许字符一律转成 **UTF-8** 字节序列，每个字节再转为 `%61` 这种形式

参考：https://zh.wikipedia.org/wiki/%E7%99%BE%E5%88%86%E5%8F%B7%E7%BC%96%E7%A0%81

实例验证方法：

- 在 Chrome 浏览器输入实例 URL，Enter，复制 URL 到文本编辑器
  - 若字符没变：说明是 urlencode 允许的字符
  - 若字符变了：说明不是允许的字符，也即被转码了

允许字符：见前面说明

实例：

- 字母 `a` 编码为 `%61`
- 解析：`a` 在 ASCII 规范中：`二进制 1100001` = `十进制 97` = `十六进制 61`
- 所以 `a` 的 urlencode 即 `百分号 %` + `十六进制 61` = `%61`
- 特别的，当字符本身是允许字符串，在 urlencode 中既可以直接写 `a`，也可以使用转义后的 `%61`，认为二者等价

## 为什么需要 urlencode，而不是直接原始字符编码或二进制发送到服务端？

答：

- 首先承认，urlencode 后，确实比原始二进制占用更多空间

- URL 是为了统一的命名网络中的一个资源（不只是 HTTP，可以是其他，如 FTP）
  > 这就要求 URL 有一些基本的特性
  >
  > - URL 是可移植的。（所有的网络协议都可以使用 URL）
  > - URL 的完整性。（不能丢失数据，比如 URL 中包含二进制数据时，如何处理）
  > - URL 的可阅读性。（希望人能阅读）
  > - 因为一些历史的原因 URL 设计者使用 US-ASCII 字符集表示 URL。（原因比如 ASCII 比较简单；所有的系统都支持 ASCII）

参考：

- [为什么要进行 url encode？](https://www.zhihu.com/question/19673368/answer/71537081)

# urlencode 中表示一个空格，应是 `%20`？还是 `+`？

实际使用是：一般接收端两者都能兼容。

// 空格实验 TODO

根据 [这里](https://stackoverflow.com/a/29948396/2752670) 建议，URL 的 `?` 前用 `%20`，`?` 后用 `+`。

但 Chrome 浏览器好像都统一转换为了 `%20`。

参考：

- https://stackoverflow.com/a/1634293/2752670
- https://stackoverflow.com/a/29948396/2752670

## urlencode 实验

实验证明：

- 服务端文件：[server.php](https://github.com/vikyd/note/blob/master/content-type-urlencode/server.php)
  - 启动：`php -S localhost:8080`
    > 后续客户端文件都需要用到这个服务端，具体见文件内的请求 URL
- 客户端文件：[form_submit.html](https://github.com/vikyd/note/blob/master/content-type-urlencode/form_submit.html)
  - 点击按钮 `POST array form 提交 （Click me）`
- Wireshark 监控回环网卡（如 Win 下：`Npcap Lookback Adapter`）
  - 过滤规则：`tcp.port == 8080`

Wireshark 抓包得 POST 请求的 HTTP Body 为：

```
a%5B0%5D=123&a%5B1%5D=1234&a%5Ba1%5D%5Bb1%5D=123&a%5Ba2%5D%5Bb2%5D=1234&b%5Bx1%5D=456&b%5Bx2%5D=4567&c=on
```

即 urlencode 的编码，实验得证。

再通过其他工具解码上述字符串得：

```
a[0]=123&a[1]=1234&a[a1][b1]=123&a[a2][b2]=1234&b[x1]=456&b[x2]=4567&c=on
```

整理格式看起来更直观：

```
a[0]=123&
a[1]=1234&
a[a1][b1]=123&
a[a2][b2]=1234&
b[x1]=456&
b[x2]=4567&
c=on
```

## HTTP Content-Type 与 urlencode 关系

## 关系

HTTP GET 时：

- 请求数据放在 URL 上
- 且请求数据是 urlencode 形式

HTTP POST 时：

- 当 HTTP Content-Type 是 `application/x-www-form-urlencoded` 时，HTTP Body 的数据应是 urlencode 形式
  - 字面意思：`urlencoded`
- 浏览器的原生 POST 表单提交默认 Content-Type 正是 `application/x-www-form-urlencoded`

## urlencode 编码数组（嵌套数组）

urlencode 编码数组、嵌套数组是否有统一、标准的编码方式？

答：

- 没有标准，[参考](https://groups.google.com/forum/#!topic/montrealpython/_vgurXuZu60)
- `application/x-www-form-urlencoded` 时，py requests 与 浏览器 jQuery、axios 的编码结果都不一样

### HTML form submit 嵌套数据的 urlencoded 编码方式

浏览器：Chrome 67

服务器文件：[server.php](https://github.com/vikyd/note/blob/master/content-type-urlencode/server.php)

> 服务端 PHP（启动：`php -S localhost:8080`）

客户端文件（浏览器打开）：[form_submit.html](https://github.com/vikyd/note/blob/master/content-type-urlencode/form_submit.html)

结果：

- 第 1 个 form

  - HTTP 操作：GET
    > form 不指定 method 属性时默认是 GET
  - 请求默认的 Content-Type：无

- 第 2 个 form

  - HTTP 操作：POST
  - 请求默认的 Content-Type：`application/x-www-form-urlencoded`

- 第 3 个 form

  - HTTP 操作：POST
  - 请求默认的 Content-Type：`application/x-www-form-urlencoded`
  - 请求的 HTTP Body 中的数据是：`a[0]=123&a[1]=1234&a[a1][b1]=123&a[a2][b2]=1234&b[x1]=456&b[x2]=4567&c=on`
  - PHP 服务端中得到的是：

    ```php
    $_POST:
    Array
    (
        [a] => Array
            (
                [0] => 123
                [1] => 1234
                [a1] => Array
                    (
                        [b1] => 123
                    )

                [a2] => Array
                    (
                        [b2] => 1234
                    )

            )

        [b] => Array
            (
                [x1] => 456
                [x2] => 4567
            )

        [c] => on
    )
    ```

  - 即第 3 个 form 的形式实现了嵌套数组在 Content-Type 为 `application/x-www-form-urlencoded` 时的传输
    - 因为 PHP 能正确还原网页发过来的请求数据

### jQuery 嵌套数据的 urlencoded 编码方式

浏览器打开文件：
[jquery_ajax.html](https://github.com/vikyd/note/blob/master/content-type-urlencode/jquery_ajax.html)

数据:

```json
{
  "a": 123,
  "b": [789, { "c": 456 }]
}
```

结果：

- 同样会采取与 HTML form 的方式编码嵌套数组
- jQuery AJAX GET

  - 默认不带 Content-Type
  - 数据被放到 URL 中：`a=123&b[]=789&b[1][c]=456`
  - 请求的 HTTP Body 中无数据

- jQuery AJAX POST
  - 默认 Content-Type：`application/x-www-form-urlencoded; charset=UTF-8`
  - 请求的数据被放到 HTTP Body 中
  - 数据格式也是：`a=123&b[]=789&b[1][c]=456`

结论：

- jQuery 默认的 GET、POST 编码行为与浏览器基本一致，也能被 PHP [`$_GET`](http://php.net/manual/en/reserved.variables.get.php)、[`$_POST`](http://php.net/manual/en/reserved.variables.post.php) 原生识别
  - PHP 的 `$_GE`、`$_POST` 本身也是针对 `application/x-www-form-urlencoded` 而设计的

### axios.js 嵌套数据的 urlencoded 编码方式

浏览器打开文件：[axios_ajax.html](https://github.com/vikyd/note/blob/master/content-type-urlencode/axios_ajax.html)

数据:

```json
{
  "a": 123,
  "b": [789, { "c": 456 }]
}
```

结果：

- axios AJAX GET

  - 默认不带 Content-Type
  - 数据被放到 URL 中：`/server.php?a=123&b[]=789&b[]={"c":456}`
  - 不同于 jQuery 的数据格式（jQuery 的是：`a=123&b[]=789&b[1][c]=456`）
  - 请求的 HTTP Body 中无数据

- axios AJAX POST

  - 默认 Content-Type：`application/json;charset=UTF-8`
  - 请求的数据被放到 HTTP Body 中
  - PHP `$_POST` 中无有任何数据
  - 数据格式区别于 GET，POST 是：`{"a":123,"b":[789,{"c":456}]}`

- axios AJAX POST
  - 手动设置 `Content-Type: application/x-www-form-urlencoded`
  - Content-Type 确实切换为：`application/x-www-form-urlencoded`
  - 编码结果与 jQuery POST 的默认 urlencode 一致

## PHP 嵌套数据的 urlencoded 编码方式

文件 `urlencode-build.php`：

浏览器打开：http://localhost:8080/urlencode-build.php

```php
$data =  [
    0 => "abc",
    "x" => 456,
    "z" => [
        "y" => 123,
    ],
];

$s1 = http_build_query($data);

$s2 = urldecode($s1);
```

结果：

- $s1：`0=abc&x=456&z%5By%5D=123`
- $s2：`0=abc&x=456&z[y]=123`

结论：与 jQuery 的默认编码方式一致

## Python urllib.urlencode 嵌套数据的 urlencoded 编码方式

`urllib.urlencode` 是 Python 自带的库

文件 `urllib-urlencode.py`：

```py
# coding: utf8

import urllib

data = {
  'x': 456,
  'z': {
    'y': 123
  }
}

s1 = urllib.urlencode(data)
s2 = urllib.unquote(s1).decode('utf8')
```

结果：

- $s1：`x=456&z=%7B%27y%27%3A+123%7D`
- $s2：`x=456&z={'y':+123}`

结论：Python 与 PHP 的默认 urlencode 编码方式不同

## py [requests](python-requests.org) 嵌套数据的 urlencoded 编码方式

> 嵌套数据 和 简单字符串

文件：见各个 `.py` 文件。

执行方式：`python 文件名.py`

结果：

- POST 的请求数据都是默认放在 HTTP Body

- 当 POST 的数据是简单字符串：`requests.post(url='yourUrl', data=yourString)`

  - Content-Type：无

- 当 POST 的数据是 dict：`requests.post(url='yourUrl', data=yourDict)`

  - Content-Type：`application/x-www-form-urlencoded`
  - 但编码后的字符串，丢失了部分数据（如 [requests-post-dict.py](https://github.com/vikyd/note/blob/master/content-type-urlencode/requests-post-dict.py)）

- 当 POST 手动设置 `Content-Type: application/json` 时，dict 数据应 `json=youDict`（而非 `data=youDict`）：
  ```py
  headers = {'Content-Type': 'application/json'}
  requests.post(url='yourUrl', data=yourDict, headers=headers)
  ```

结论：

- py requests 与 PHP 的编码 urlencode 嵌套数据的结果不一样
- py requests POST 为 `Content-Type: application/json` 时，dict 数据应 `json=dict`（而非 `data=dict`）
- py requests POST 不显示指定 Content-Type 时，`data=yourString` 和 `data=youDict` 默认的 Content-Type 是不一样的

# PHP 的 `php://input` 能否读取多次

## `php://input` 是什么？

答：根据 [官方文档](http://php.net/manual/en/wrappers.php.php)，`php://input` 得到的数据是 HTTP Body 里的所有数据（不管 `Content-Type` 是什么）。

## 能否读取多次

文件：

- 服务端 [server_phpinput_read_twice.php](https://github.com/vikyd/note/blob/master/content-type-urlencode/server_phpinput_read_twice.php)
- 客户端端 [requests-post-str-inputstream.py](https://github.com/vikyd/note/blob/master/content-type-urlencode/requests-post-str-inputstream.py)

- [官方文档](http://php.net/manual/en/wrappers.php.php#refsect1-wrappers.php-changelog) 说 PHP 5.6 及之后的版本才可以重复读取 `php://input`，但实际与 SAPI 实现有关
- 实际测试：
  - `Win7 64bit` + `PHP 5.4、5.5、5.6、7.2` + `PHP 内置 Server` 均能允许 `file_get_contents("php://input")` 重复读取

# Laravel

## 服务端

- 版本：Laravel 5.6.12
- 设置：
  - 自行下载 Laravel 部署
    - `composer install`
    - `.env.example` 复制为 `.env`
    - `php artisan key:generate`
  - `routes/web.php` 最后增加：
    ```php
    Route::get('/t1', 'Test01Controller@t1');
    Route::post('/t1', 'Test01Controller@t1');
    ```
  - `app/Http/Controllers` 内增加文件 [Test01Controller.php]() TODO
  - `app/Http/Middleware/VerifyCsrfToken.php` `protected $except` 数组内增加 `'/t1'`
- Laravel 根目录下启动 Server：`php -S localhost:8181 -t public`

## 客户端

和前面差不多，自行测试，这里不提供更多示例：

- `jquery_ajax_laravel.html`
- `requests-post-param_obj-content_type-json-laravel.py`

## 结论

- Laravel 的 `$request->input('paramName')` 能自动获取不同 HTTP Method 的参数

  - 与纯 PHP 一致的：
    - GET：从 URL 的 query string 部分获取
    - POST：从 HTTP Body 获取
    - `Content-Type: application/x-www-form-urlencoded` 解析嵌套数据方式与原生 PHP 一致
  - Laravel 比较智能：
    - `Content-Type: application/json` 时 `$request->input('paramName')` 也能获取到 [对应的值](https://laravel.com/docs/5.6/requests#retrieving-input)

- Laravel 的 `$request->query('paramName')` 只从 URL 的 query string 部分获取

参考：

- https://laravel.com/docs/5.6/requests#retrieving-input
  > Using a few simple methods, you may access all of the user input from your `Illuminate\Http\Request` instance without worrying about which HTTP verb was used for the request. Regardless of the HTTP verb, the `input` method may be used to retrieve user input

# Codeigniter

## 服务端

- 版本：Codeigniter 3.1.8
- 设置
  - 在 `application/controllers` 中新建文件 [test01.php]() TODO
- Codeigniter 根目录下启动 Server：`php -S localhost:8282`

## 客户端

和前面差不多，自行测试，这里不提供更多示例：

- `jquery_ajax_codeigniter.html`

## 结论

- Codeigniter `$this->input->post('paramName')` 替代纯 PHP 的 `$data = isset($_POST['paramName']) ? $_POST['paramName'] : NULL;`，即主要省去了 `isset` 的检查

- 其他与纯 PHP 一致

参考：

- [Codeigniter Input 类](https://codeigniter.org.cn/user_guide/libraries/input.html)

# urlencode 与 base64 的区别

[base64 是什么？为什么是 64 而非其他数字？](https://github.com/vikyd/note/tree/master/base64.md)

- base64 主要用于传输二进制内容（因为 base64 只关心输入的二进制内容，而不关心这些输入内容属于哪种编码）
  - 优点
    - ？
  - 缺点
    - 数据存在冗余
    - 难以大致看出原来的内容，因为在二进制内就被拆分了

* urlencode 主要用于编码特殊字符、歧义字符
  - 优点
    - 相对易读，能大致看出原始字符，是 1 对 1，或 1 对 n 的关系
  - 缺点
    - 凡是需编码的字符，都会变成 2 倍的大小，比 base64 大

# `Content-Type` vs `MIME`

根据 [这个回答](https://stackoverflow.com/a/17949292/2752670)：

- `MIME` 是 `Content-Type` 别名
- `Content-Type` 还可在后面附带编码信息，如 `text/html; charset=UTF-8`

在说 HTTP 时，`Content-Type` 和 `MIME` 基本可认为是同一个东西

根据 [这个回答](https://stackoverflow.com/a/3452833/2752670)：

- `MIME` 起源于 Email，后来 HTTP 借用过来叫 `Content-Type`

# 杂

- GET 的请求数据应尽量少，因 URL 有长度限制（不同浏览器、服务器不一样）
- URL 的长度限制，[参考](https://stackoverflow.com/a/417184/2752670)：
  - 建议不超过 2000 字节

# 总结

## HTTP Client（Py requests、浏览器、jQuery、axios）

- POST 请求且 `Content-Type: application/x-www-form-urlencoded` 时，采用的编码方式是 [urlencode](https://en.wikipedia.org/wiki/Percent-encoding)（与 URL 中的编码方式一致）

- `application/x-www-form-urlencoded`

  - 原用于 key-value 形式的数据
  - [只是事实标准（大家都这么干），不是成文明确标准](https://stackoverflow.com/a/42293222/2752670)
  - 对数组、嵌套数组的编码形式并无标准规定，这也是各个 Client 的实现方式不一样的根源

- 发送 HTTP 数据时对数据的编码形式不一样

- Content-Type 不同，Client 编码数据的最终形式也可能会不同

- `application/x-www-form-urlencoded` 是浏览器 POST 的默认 `Content-Type`

- PHP 的 `$_POST` 取自 `Content-Type: application/x-www-form-urlencoded` 时的 HTTP Body 的数据，且能自动转换为 PHP 的嵌套数组

- 请求数据：jQuery、axios 的 POST 默认编码格式、Content-Type 都不一样

- 请求数据（嵌套数组）：jQuery、axios 的 GET 编码结果不一样

- [application/x-www-form-urlencoded 原意用于 key-value 的数据](https://url.spec.whatwg.org/#application/x-www-form-urlencoded)

# HTTP 基础

- HTTP 由 Header、Body 组成

- 通常，GET 的数据都放在 URL 中，此时 HTTP Body 为空，即使数据很大

- 通常，POST 的数据都放在 Body 中，但 URL 可同时带 query string（类似这样：`a=123&b=xyz`）

- 特别的，GET 请求中也可在 Body 放数据，但绝大部分 Client 不会这么做，也不建议这么做

- URL 的尽管规范没说最大长度有限制，但实际不同 Client、Server 的限制不一样，有些还可配置最大长度

- [URL 的 Query String](https://en.wikipedia.org/wiki/Query_string)

- 抓实际 HTTP 的 TCP 包，建议使用 Wireshark

- py requests 可实现 GET 中 body 放数据：`requests.get(url='yourUrl', data=yourData)`

# 备注

本文的软件及版本

- Windows7 64bit
- Chrome 67
- Wireshark 2.4.2
- PHP 7.2
- Python 2.7.14

# 名词约定

- 嵌套数据
  - 就是 map 与 array 的混合、嵌套的数据
  - 以 JSON 举例就是
    ```json
    {
      "a": 123,
      "b": [789, { "c": 456 }]
    }
    ```
