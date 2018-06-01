# 概述
本文只说 1 个点：
- WebDriver 与浏览器交互（Chrome 为例）是通过 Chrome 提供的 Chrome DevTools Protocol 协议进行的（我之前猜的是错的：以为通过 chrome.exe 支持的特殊命令）

> 其他都是为了解释这个点。


# 疑惑
WebDriver API 的使用方式比较明确，也基本不影响开始进行页面 UI（端到端，或叫 e2e: end to end）测试。

关于 WebDriver，网上很多文章的描述：
> 测试用例调用 WebDriver API 通过 HTTP 向各浏览器的 WebDriver 程序发送操作请求（`获取页面元素值`、`click 页面按钮`等），
WebDriver 再将操作请求`转换`为浏览器的操作。


但疑惑的是：WebDriver 是如何将操作请求 **`转换`**为浏览器的实际操作的？？？

处于懵逼状态 n 小时的我，Google、百度了好久并大致看了下 [selenium-webdriver.js](https://github.com/SeleniumHQ/selenium/tree/master/javascript/node/selenium-webdriver) 和 [chromedriver.exe](https://github.com/bayandin/chromedriver)  源码，希望我下面的理解可以为大家节省几个小时的搜索查找（有错请喷）。



# WebDriver 通讯过程（Chrome 为例）
WebDriver 下面 2 个流程二选一：
> 下面每个流程里按顺序向下执行

### 1. 简单流程（不经 Selenium-server）
- ↓ [A] 用户测试脚本
  > - 各语言（[JavaScript](https://github.com/SeleniumHQ/selenium/tree/master/javascript/node/selenium-webdriver)、[Py](https://github.com/SeleniumHQ/selenium/tree/master/py) 、Java 等）的 WebDriver 客户端 API
  > - WebDriver 客户端也可顺便启动下面步骤的 WebDriver 服务端
- ↓ [B] HTTP（[WebDriver 协议](https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol)）
- ↓ [C] chromedriver.exe
  > - Chrome 浏览器的 WebDriver 协议 HTTP 服务端
  > - 且是 `Chrome DevTools Protocol` 协议的 HTTP 客户端
- ↓ [D] HTTP（[Chrome DevTools Protocol 协议](https://chromedevtools.github.io/devtools-protocol/)）
- [E] Chrome 浏览器（即 chrome.exe）
  >  1. 是 `Chrome DevTools Protocol` 协议的 HTTP 服务端
  >  2. `Chrome DevTools Protocol` 协议可由命令行参数启动


串成一句话：

`用户测试脚本` 使用 `WebDriver 客户端 API` 通过 `WebDriver 协议` 发送 HTTP 请求到 `chromedriver.exe（WebDriver 服务端）`，`chromedriver.exe` 将 WebDriver 规范的浏览器各种操作转换成 `Chrome DevTools Protocol 协议` 的操作，继续通过 `Chrome DevTools Protocol` 发送 HTTP 请求到 `chrome.exe（即浏览器）（同时也是 Chrome DevTools Protocol 服务端）`，最后浏览器真正执行相应的操作。



### 2. 复杂流程（经 Selenium-server）（常用）
- 本流程多了一步：在上面简单流程的 `A` 和 `C` 之间增加了一层 `Selenium-server`，用来处理一些 WebDriver 之外的一些 [需求](https://stackoverflow.com/a/42130587/2752670)。

- `Selenium-server`实质是 WebDriver 的一个增强版代理，其必备功能就是将 WebDriver 客户端请求转发到真正的 WebDriver 服务端（如 ChromeDriver）：[证据 chromedriver.exe](https://github.com/SeleniumHQ/selenium/blob/master/javascript/node/selenium-webdriver/chrome.js#L152) 。



![](https://github.com/vikyd/note/blob/master/img/webdriver.png)




# 流程解释 & 其他疑惑
- WebDriver 是用来做什么的？
  - 主要用途：进行前端界面测试（或称 end to end 即 e2e 测试）
- WebDriver 是分客户端和服务端的：
  - 客户端：各语言的客户端 API （[Clients](http://docs.seleniumhq.org/download/) 里查找 `Selenium Client & WebDriver Language Bindings`）
  - 服务端：各浏览器的（[WebDriver 程序](http://docs.seleniumhq.org/download/) 里查找 `Third Party Drivers, Bindings, and Plugins`）
  
- WebDriver 与浏览器交互（Chrome 为例）是通过 Chrome 提供的 Chrome DevTools Protocol 协议进行的（我之前猜的是错的：以为通过 chrome.exe 支持的特殊命令）

- chromedriver.exe 等各浏览器 WebDriver 应加入到系统环境变量中（Windows 环境变量需重启生效）

- chromedriver.exe 使用了 `Chrome DevTools Protocol` 协议的证据：
  > 官网说明 [As of 2.x, ChromeDriver is now a DevTools debugging client](https://sites.google.com/a/chromium.org/chromedriver/help/devtools-window-keeps-closing)
  
- Selenium-server 并没有实现 WebDriver 的服务端，它只是一个增强版 WebDriver 客户端，WebDriver 服务端目前由各浏览器厂商自行维护，WebDriver 服务端程序通常是一个可执行文件，如 [chromedriver.exe](https://sites.google.com/a/chromium.org/chromedriver/downloads)。

- Chrome DevTools Protocol 协议与 WebDriver 无关，不需要 WebDriver 也照样可使用 Chrome DevTools Protocol 协议。

- chrome.exe 浏览器本身支持 `Chrome DevTools Protocol 协议`，所以 chrome.exe 本身也可以启动成为一个服务端：
   ```sh
   # http://localhost:9222 可用另外浏览器实例访问
   chrome.exe --remote-debugging-port=9222 --user-data-dir=abc_dir
   ```
   详细步骤：https://div.io/topic/1464

- 本文只说了 Chrome，至于 FireFox、Safari 等可能不一样，有空再说。



# 参考
- WebDriver 目前是 [W3C Candidate Recommendation](
https://www.w3.org/TR/webdriver/#h-compatibility) 阶段的规范（由 Selenium WebDriver 发展而来）


# 特别注明
Puppeteer（Headless Chrome Node API）：https://github.com/GoogleChrome/puppeteer

