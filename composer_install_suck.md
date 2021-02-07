# PHP Composer 安装踩坑记（代理设置）

# 目录

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [概述](#%E6%A6%82%E8%BF%B0)
- [方式 01：Composer-Setup.exe 一键安装 Composer（不推荐）](#%E6%96%B9%E5%BC%8F-01composer-setupexe-%E4%B8%80%E9%94%AE%E5%AE%89%E8%A3%85-composer%E4%B8%8D%E6%8E%A8%E8%8D%90)
- [方式 02：命令行安装 Composer（推荐）](#%E6%96%B9%E5%BC%8F-02%E5%91%BD%E4%BB%A4%E8%A1%8C%E5%AE%89%E8%A3%85-composer%E6%8E%A8%E8%8D%90)
- [使用 Composer 安装 PHP 第三方库](#%E4%BD%BF%E7%94%A8-composer-%E5%AE%89%E8%A3%85-php-%E7%AC%AC%E4%B8%89%E6%96%B9%E5%BA%93)
- [为什么不直接设置 http_proxy 和 https_proxy 到系统环境变量中？](#%E4%B8%BA%E4%BB%80%E4%B9%88%E4%B8%8D%E7%9B%B4%E6%8E%A5%E8%AE%BE%E7%BD%AE-http_proxy-%E5%92%8C-https_proxy-%E5%88%B0%E7%B3%BB%E7%BB%9F%E7%8E%AF%E5%A2%83%E5%8F%98%E9%87%8F%E4%B8%AD)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 概述

Windows 下，且在需要代理才能访问外网的环境下（如公司内），的安装方式。

根据 Composer 官方文档：https://getcomposer.org/download/ ，有两种安装方式：

- `Composer-Setup.exe` 一键安装
- 命令行安装（推荐！）

# 方式 01：Composer-Setup.exe 一键安装 Composer（不推荐）

1. 下载：https://getcomposer.org/Composer-Setup.exe
1. 双击打开，填入代理（如 http://yourProxyServer:port）（因需连外网下载 composer 真正的安装包）：
   - 注意：`Use a proxy server to connect to internet` 中填入的是 **http**，不是 https
     - 原因：未知。猜是因为 OpenSSL
1. Over

注意：

- 此方式默认会添加 Composer 命令到环境变量：`Add to System path: C:\ProgramData\ComposerSetup\bin`
- 此方式默认会在当前用户环境变量中新建一项 `http_proxy`，后续若有副作用，自行移除即可。

# 方式 02：命令行安装 Composer（推荐）

前提：已安装 php，并设置 php.exe 到系统环境变量。

命令行安装方法来自：https://getcomposer.org/download/ ：

```cmd
REM ↓ 注释：不用此命令下载 composer-setup.php，因 PHP 的 copy 命令不知如何设置代理
REM        可手动下载 https://getcomposer.org/installer，并重命名为 composer-setup.php
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

REM ↓ 注释：校验文件（可不做此步骤，请从官网获取最新的 hash 命令）
php -r "if (hash_file('SHA384', 'composer-setup.php') === '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"

REM ↓ 注释：设置下载 Composer 时使用的代理
set http_proxy=http://yourProxyServer:port
set https_proxy=http://yourProxyServer:port

REM ↓ 注释：执行后当前目录将会产生一个文件 composer.phar，建议将此文件放到与 php.exe 相同目录中
php composer-setup.php

REM ↓ 注释：删除已经没用的 composer-setup.php，也可手动直接删除
php -r "unlink('composer-setup.php');"
```

命令行安装默认不会设置 Composer 系统环境变量，若需要，继续往下看：

1. 参考：https://getcomposer.org/doc/00-intro.md#installation-windows
1. 在 `composer.phar` 相同目录下新建文件 `composer.bat`
1. `composer.bat` 中的内容：
   ```cmd
   @php "%~dp0composer.phar" %*
   ```
1. 添加 `composer.bat` 所在目录到系统环境变量 PATH 中
1. Windows 环境变量需重启生效 Over

# 使用 Composer 安装 PHP 第三方库

使用 Composer 安装 PHP 第三方库时也需要在命令行设置代理。

假设已有 `composer.json` 文件：

```json
{
  "name": "yourPHPProject",
  "require": {
    "nesbot/carbon": "^1.22"
  },
  "config": {
    "vendor-dir": "vendor"
  }
}
```

下载 `composer.json` 中包含的依赖库 `nesbot/carbon`：

```cmd
set http_proxy=http://yourProxyServer:port
set https_proxy=http://yourProxyServer:port

REM ↓ 注释：安装一个时间库： http://carbon.nesbot.com/
composer install
```

若想继续安装其他库，如 PHP 的 HTTP 客户端 `guzzlehttp/guzzle`：

```cmd
set http_proxy=http://yourProxyServer:port
set https_proxy=http://yourProxyServer:port

composer require guzzlehttp/guzzle
```

# 为什么不直接设置 http_proxy 和 https_proxy 到系统环境变量中？

那样对其他软件有麻烦，具体忘了。
