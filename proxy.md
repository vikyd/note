# 常用代理设置汇总

设置代理是为了这几种情况：

- `翻墙`
- 从 `内网` 访问 `外网`
- 从 `内网` 访问 `内网镜像库`（npm、composer 等）

# 目录

<!-- START doctoc -->
<!-- END doctoc -->

# 代理方式

代理设置至少有以下几种方式：

- 设置目标代理机器（常用）
  > 如：`http://yourProxyServer:port`
- 设置 pac 自动匹配代理（常用于浏览器）
  > 如：`http://example/a.pac`

# 代理地址

假设你目前可用的代理是：`http://yourProxyServer:port`，后面例子均以此代理作为示范。

# Windows CMD 代理设置

当前 CMD 窗口有效：

```cmd
REM 设置代理
set http_proxy=http://yourProxyServer:port
set https_proxy=http://yourProxyServer:port

REM 查看代理
echo %http_proxy%
echo %https_proxy%

REM 取消代理(留空即可)
set http_proxy=
set https_proxy=
```

若想一直有效，设置系统环境变量：http_proxy、https_proxy，并重启你的 Windows。

注意：

- `http_proxy` 和 `https_proxy` 对应的都是 `http://yourProxyServer:port`，后者可能没有 `https` 的 `s`

# Linux 代理设置

同下面 Mac 代理设置 ↓

# Mac 代理设置

这里只说命令行配置代理的方式

在 `~/.bash_profile` 或 `~/.zshrc` 中填入设置代理的快捷方式：

```sh
# shadowsocks 翻墙用，不翻墙可不用
alias proxy_ss='export all_proxy=socks5://127.0.0.1:1086; export http_proxy=http://127.0.0.1:1087; export https_proxy=https://127.0.0.1:1087'

# 其他代理
alias proxy_dev='export http_proxy=http://yourProxyServer:port; export https_proxy=http://yourProxyServer:port'

# 取消所有代理设置
alias unproxy='unset all_proxy; unset http_proxy; unset https_proxy'
```

设置完，记得 source 一下配置文件。

使用，shell 中执行（开发机为例）：

```sh
# 设置代理
proxy_dev

# 取消代理
unproxy

```

---

单独命令：

```sh
# 临时设置代理
export http_proxy=http://yourProxyServer:port
export https_proxy=http://yourProxyServer:port

# 查看代理
echo $http_proxy
echo $https_proxy

# 取消代理
unset http_proxy
unset https_proxy
```

# Mac Homebrew 代理设置

同上面 Mac 命令行的代理设置。

[Brew 官方参考](https://docs.brew.sh/Manpage#using-homebrew-behind-a-proxy)

# Git 代理设置

[Git](https://zh.wikipedia.org/wiki/Git)

```sh
# 全局：设置 Git 访问外网（如 github）的代理
git config --global http.proxy http://yourProxyServer:port

# 全局：查看 Git 代理
git config --global --get http.proxy

# 全局：删除 Git 代理
git config --global --unset http.proxy



# ----------- 下面是针对每个项目局部的，非全局 -----------------
# 设置 Git 访问外网（如 github）的代理
git config http.proxy http://yourProxyServer:port

# 查看 Git 代理
git config --get http.proxy

# 删除 Git 代理
git config --unset http.proxy
```

# Git 用户名、邮箱设置

```sh
# 设置 Git 全局：用户名、邮箱 ↓
git config --global user.name "youName"
git config --global user.email yourEmail@example.com

# 下面是针对每个 Git 项目的，非全局 ↓
git config user.email yourEmail@example.com
git config user.name "youName"
```

哪个设为全局，哪个设为当前项目，按个人需求而定，并无绝对。

# npm 代理设置 + 镜像设置

[npm](https://www.npmjs.com/)

## 使用淘宝 npm 镜像（推荐）

此时需同时设置：淘宝镜像 +  你的代理（若有的话）

```sh
# ↓ 设置淘宝 npm 镜像
npm config set registry https://registry.npm.taobao.org
# ↓ 若本来即可访问外网，无需下面代理设置
npm config set https-proxy http://yourProxyServer:port
```

## 使用 npm 官方镜像

设置代理（若有的话）：

```sh
npm config set proxy http://yourProxyServer:port
npm config set https-proxy http://yourProxyServer:port
```

# npm 代理、镜像查看方式

```sh
# 查看 npm 所有设置
npm config list

# 查看代理
npm config get proxy
npm config get https-proxy

# 查看镜像
npm config get registry

# 取消代理
npm config rm proxy
npm config rm https-proxy
```

# yarn 代理设置 + 镜像设置

[yarn](https://yarnpkg.com/en/)

```sh
# 设置 registry 镜像
yarn config set registry https://registry.npm.taobao.org

# 设置代理（若有的话）
yarn config set proxy http://yourProxyServer:port

# 查看所有设置
yarn config list

# 查看镜像设置
yarn config get registry

# 查看某个设置
yarn config get proxy
```

yarn 全局配置： `用户目录/.yarnrc`

注意：

- 有时设置了代理也不生效，可能原因是 `yarn.lock` 文件的问题，删掉重来试试
  - 参考：https://github.com/yarnpkg/yarn/issues/4890

# nvm 代理设置

[nvm](https://github.com/creationix/nvm)

```sh
# 设置代理（永久）
nvm proxy "http://yourProxyServer:port"

# 设置代理（临时，非必须）
set http_proxy=http://yourProxyServer:port
set https_proxy=http://yourProxyServer:port

# 查看代理
nvm proxy

# 删除代理
nvm proxy "none"
```

参考：https://github.com/coreybutler/nvm-windows#usage

# Bower 代理设置

[Bower](https://bower.io/)

新建 `.bowerrc` 文件，
填入 `proxy` 和 `https-proxy`：

```json
{
  "directory": "bower_components",
  "proxy": "http://yourProxyServer:port/",
  "https-proxy": "http://yourProxyServer:port/"
}
```

支持三种设置方式：

- 当前项目：`当前目录（bower.json 的同级目录）`
- 当前用户目录
- 系统根目录（Linux 的 `/` 目录）

参考：https://bower.io/docs/config/#placement--order

# PHP Composer 代理设置

[Composer](https://getcomposer.org/)

安装完 Composer 后，使用 Composer 时是直接使用系统（如 Win 的 CMD）的代理，并无代理配置文件。

也即：Windows 下需设置 CMD 的代理，类似

```Batchfile
set http_proxy=yourProxyServer:port
set https_proxy=yourProxyServer:port
```

之后，才能进行 `composer require packageName`

系统配置了这两个环境变量的话，就相当于 Composer 的全局代理

# PhpStorm、IntelliJ IDEA、PyCharm、WebStorm、Android Studio（或 Jetbrains 系其他）代理设置

[Jetbrains](https://www.jetbrains.com/)

`File` -> `Settings` -> `Appearance & Behavior` -> `System Settings`

-> `HTTP Proxy` -> `Manual proxy configuration` -> `HTTP`

-> `Host name: yourProxyServer` -> `Port number: yourProxyPort`

-> `OK`

# Maven 代理、镜像设置

[Maven](https://maven.apache.org/)

Maven 的代理、镜像设置内容较多，详细见 [这里](https://github.com/vikyd/note/blob/master/maven_proxy.md)

# Gradle 代理设置

[Gradle](https://gradle.org/)

- 若设置当前项目：
  - 新建或编辑当前项目内的 `gradle.properties`
- 若设置全局项目：
  - 新建或编辑 `用户目录/.gradle/gradle.properties`

在 `gradle.properties` 文件中增加以下设置：

```
systemProp.http.proxyHost=yourProxyServer
systemProp.http.proxyPort=yourPort
systemProp.https.proxyHost=yourProxyServer
systemProp.https.proxyPort=yourPort
```

参考：https://docs.gradle.org/current/userguide/build_environment.html

## Python 的 pip 代理设置

pip 可用于安装 Python 的包。

[pip](https://pypi.org/project/pip/) 的代理设置有 3 种方式（n 选 1）：

- 系统环境变量
  - 就如 CMD 的代理设置，之后再 `pip install yourPackage`，Win ↓
  ```cmd
  set http_proxy=http://yourProxyServer:port
  set https_proxy=http://yourProxyServer:port
  ```
- `--proxy` 参数
  - `pip install yourPackage --proxy http://yourProxyServer:port`
- `pip.ini` 配置文件（推荐，永久）
  - 以 Win 为例，在用户目录新建目录和文件 ` %HOME%\pip\pip.ini`，填入：
    ```ini
    [install]
    proxy=http://yourProxyServer:port
    ```
  - 查看设置是否成功：`pip config list`

pip 设置代理的官方文档：https://pip.pypa.io/en/stable/user_guide/#using-a-proxy-server

# VSCode 代理设置

[VSCode](https://code.visualstudio.com/) 默认从 `http_proxy` 和 `https_proxy` 环境变量获取代理。

但也可手动设置：
`File` -> `Preference` -> `Settings`，在右侧 `User Settings` 里粘贴以下代码：

```json
"http.proxy": "http://yourProxyServer:port",
```

# Notepad++ 代理设置

[Notepad++](https://notepad-plus-plus.org/)

菜单栏 -> 最右侧问号 `?` -> `设置更新代理服务器` ->

- `Proxy server`：yourProxyServer
- `Port`：yourPort

# Sublime 代理设置

[Sublime](https://www.sublimetext.com/) 默认使用系统的 `PAC` 设置。浏览器能上网，Sublime 基本就能联网。

也可在配置文件自定义代理：

- `菜单栏` -> `Preferences` -> `Settings` -> `在左右任意一侧填入`：

```json
"http_proxy": "http://yourProxyServer:port",
"https_proxy": "http://yourProxyServer:port",
```

# Eclipse 代理设置

[Eclipse](https://www.eclipse.org/) 代理设置方式：

- `Window` -> `Preferences` -> `General` -> `Network Connections` -> 右侧 `Active Provider` 选择 `Manual` -> `Proxy entries 表格` 中双击第 1 行的 `HTTP` -> `Host` 填 `yourProxyServer` -> `Port` 填 `yourPort` -> `OK`
- `HTTPS`、`SOCKS` 同理设置

# Atom 编辑器 代理设置

[Atom](https://atom.io/)

见下面命令：

```sh
# 设置代理
apm config set https-proxy https://yourProxyServer:port

# 查看代理
apm config get https-proxy

# 查看所有配置（显示的结果的 `userconfig` 就是配置文件所在位置）
apm config get
```

参考：https://github.com/atom/apm#using-a-proxy

# wget 代理设置

[wget Win](https://eternallybored.org/misc/wget/)

[wget Linux](https://www.gnu.org/software/wget/)

方法 01（临时）：

- 先设置 Windows CMD 的代理：
  ```cmd
  set http_proxy=http://yourProxyServer:port
  set https_proxy=http://yourProxyServer:port
  ```
- 或 Linux shell 的代理：
  ```sh
  export http_proxy=http://yourProxyServer:port
  export https_proxy=http://yourProxyServer:port
  ```
- 然后可以直接使用 wget 命令

方法 02（永久，推荐！）：

- 直接使用 wget 配置文件，在当前用户主目录下新建文件 `.wgetrc`（或 Linux 的 `/etc/wgetrc`）：
  ```ini
  http-proxy = yourProxyServer:port
  https-proxy = yourProxyServer:port
  ftp-proxy = yourProxyServer:port
  ```
- 然后可以直接使用 wget 命令

方法 03（临时）：

- 直接在 wget 命令中添加参数，如
  - `wget https://www.baidu.com -e https-proxy=yourProxyServer:port`
  - 或 （都是 http ，而非 https）
  - `wget http://www.baidu.com -e http-proxy=yourProxyServer:port`

# curl 代理设置

[curl](https://curl.haxx.se/)

方法 01（临时）：

- 先设置 Windows CMD 的代理：
  ```cmd
  set http_proxy=yourProxyServer:port
  set https_proxy=yourProxyServer:port
  ```
- 或 Linux shell 的代理：
  ```sh
  export http_proxy=yourProxyServer:port
  export https_proxy=yourProxyServer:port
  ```
- 然后可以直接使用 curl 命令，如
  - `curl http://www.baidu.com -o baidu.html`

方法 02（永久，推荐！）：

- 直接使用 curl 配置文件，在当前用户主目录下新建配置文件（Win：`_curlrc`）（Linux：`.curlrc`）：
  ```ini
  proxy = yourProxyServer:port
  ```
- 然后可以直接使用 curl 命令，如
  - `curl http://www.baidu.com -o baidu.html`

方法 03（临时）：

- 直接在 curl 命令中添加参数，如
  - `curl https://www.baidu.com -o baidu.html -x yourProxyServer:port`
    > `-x` 小写 x 代表 `proxy` 的意思

# Golang 的 go get 代理

[Golang](https://golang.org/) 的 `go get` 使用系统的 `http_proxy`，但拉取代码时会使用 Git 的代理，
所以两步都要做：

1. 设置系统代理（或说 CMD 代理）

```cmd
set http_proxy=yourProxyServer:port
```

2. 设置 Git 代理，参考前面的 `Git 代理设置`

```cmd
git config --global http.proxy http://yourProxyServer:port
```

参考：

- https://stackoverflow.com/a/10385612/2752670
- 官方参考：https://github.com/golang/go/wiki/GoGetProxyConfig

若使用 VSCode，要想 VSCode 自动下载 Go 的依赖工具，则也应设置 VSCode 的 settings.json 中的代理：

```json
"http.proxy": "http://yourProxyServer:port",
```

# Navicat 连外网数据库

[Navicat](https://www.navicat.com) 貌似必须同时配置 `通道地址` 和 `代理服务器`。

注意：此方法不太安全，慎重使用！

- 步骤 01：
  Navicat 安装目录找到文件： `C:\Program Files\PremiumSoft\Navicat Premium\ntunnel_mysql.php` （或对应语言的 php），放置到你外网 Web 服务目录下（浏览器可打开 `http://IP:port/abc/ntunnel_mysql.php` 看到一个页面）

- 步骤 02：
  `右键某个数据库连接` -> `HTTP` -> 勾选 `使用 HTTP 通道` -> `通道地址` 填 `http://IP:port/abc/ntunnel_mysql.php` -> 下面 `代理服务器` -> 勾选 `使用代理服务器` -> `主机` 填 `yourPorxyServer` -> `端口` 填 `yourPort` -> `测试连接` -> `确定`

# Virtual Box、VMware 代理设置

普通用户虚拟机都采用 NAT 模式吧。

代理设置：虚拟机内的系统与外部物理机一样的代理设置，才能上网。

# Xshell 代理设置

打开某个 session 的属性设置

- Connection
- Proxy
- Browse
- Add
  - **Name**：anyName（或随意名字）
  - **Type**：HTTP 1.1
  - **Host**：yourProxyServer
  - **Port**：yourPort
  - OK
  - Close
- Proxy Server 选择刚新建的代理
- 完毕

# SecureCRT 代理设置

分 2 步走，先全局添加代理项，再在每个连接中选择对应的代理项。

1.  全局添加代理项

- Options
- Global Options
- Firewall
  - Add
    - **Name**：anyName（或随意名字）
    - **Type**：HTTP (no authentication)
    - **Hostname or IP**：yourProxyServer
    - **Port**：yourPort
    - OK

2.  在你的连接中选中刚刚新建的代理项

- 你的连接 -> 属性
- Connection
- SSH2
- Firewall
- 选择 `刚新建的代理项`

# Proxifier 为其他软件设置代理

[Proxifier](https://www.proxifier.com/)

与前面各个软件为各自设置代理不同，Proxifier 是另一种思路：统一为别的软件设置代理。

优点：

- 不用按照每个软件的不同方式设置各自的代理
- 部分没有代理设置界面的软件很适合使用 Proxifier
- 可查看被代理软件的实际流量情况
- Windows、Mac 都可使用

缺点：

- 代理设置有时不够个性化（如 Git 的全局代理与当前 Git 项目代理）

步骤：

1.  `菜单栏 Profile` -> `Proxy Servers` -> `Add`
    -> `Address` 填 `yourProxyServer` -> `Port` 填 `yourPort` -> `Protocol` 填 `HTTPS` -> `OK`

1.  `菜单栏 Profile` -> `Proxification Rules` -> `Add` -> `Name` 随意填- > `Applications` 通过 `Browse` 按钮选择你想代理的软件的 exe 文件 -> `Action` 选择前面步骤设置的 `yourProxyServer` -> `OK`

# 注意：上述例子均为虚拟代理，请自行替换为你自己的代理
