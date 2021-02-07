# VSCode 在 Windows 编译遇到的坑

官方编译指南：https://github.com/Microsoft/vscode/wiki/How-to-Contribute

# 目录

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [源码 & 环境](#%E6%BA%90%E7%A0%81--%E7%8E%AF%E5%A2%83)
- [坑列表](#%E5%9D%91%E5%88%97%E8%A1%A8)
- [经验](#%E7%BB%8F%E9%AA%8C)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 源码 & 环境

[VSCode 源码](https://github.com/Microsoft/vscode/commit/c05e57d91e50d53d487a9113c1553ca73311fa6c)

系统：Win7 64bit

命令窗：[Cmder](http://cmder.net/)

# 坑列表

- 填坑大法：

  - 发现网络问题，如 `Error: connect ETIMEDOUT`，可能是你处于代理环境有关（如公司内网）
  - 有时 Google 半天了也得不到解决，你可能需要去看看出问题时提示的 js 文件，看看对应的库的源码，一般代码量不大，容易看懂，问题就容易出在这些地方，如 `vscode-ripgrep` 安装不成功，其原因是我设置了代理 `set http_proxy=proxyHost:port`，漏了 `http://`，正确应该是：`set http_proxy=http://proxyHost:port`，若无效，试试：`set proxy=http://proxyHost:port`

- Win 下编译，不一定需要安装庞大的 VS，可能只需安装官方文档提到的：https://github.com/felixrieseberg/windows-build-tools

  - `Windows Build Tools npm module` 在 Win7 中需额外安装 .Net Framework 4.5.1，之后此工具才会自动安装 `MSbuild 14` 等相关工具

- 若你的网络环境需要代理才能访问外网，请注意各种代理设置：

  - Git、npm、yarn、cmd

- 按照官方文档设置 Python 环境变量后，应重启 Windows

- node 版本一定要与官方说明的一致

- 配到 `vscode-ripgrep` 安装不成功的，可能原因：

  - CMD 命令行中要设置本身的代理 `set http_proxy=http://yourHost:port`
    - 因为 vscode-ripgrep 用到了 github-releases，而 github-releases 用到了 request.js，github-releases 中的 `lib/github.js` 文件有一句是检测系统命令行代理的 `proxy: process.env.http_proxy || process.env.https_proxy,`
    - 此问题同样适用于启动编译好的 vscode 时。
  - node 版本与官方文档的不一致（可尝试 [nvm](https://github.com/creationix/nvm) 来安装多个版本的 node）
  - 也可能是没有清空缓存 `yarn cache clean`
  - 需要为本地的 git 设置 github 的 `Personal access tokens`，参考：https://blog.csdn.net/nicolelili1/article/details/52606144
    - GitHub -> Profile -> Developer settings -> Personal access tokens
      - 这是一次性的 token，github 上可持续生效，但你不可再见此 token，除非你 copy 保存到本地
    - Git 设置：
      ```cmd
      git config --global github.user yourGithubName
      git config --global github.token yourGithubToken
      ```

- 执行 `yarn` 时，若发现类似错误 `Cannot create property`，应检查 yarn 的配置文件中是否有不正确的 key，删掉即可

- 执行 `yarn` 时

- 最后编译命令是 `yarn run watch` 是不会自动停止的，因为会自动根据源码变动而自动编译

  - 一旦看到 `Finished compilation` 字样即说明编译成功

- 运行 VSCode 是执行 `script/code.bat` 文件

- 是执行 `script/code.bat` 可能会出现 `Error: connect ETIMEDOUT`

  - 可能原因，代理：
    - 同样是代理问题，设置 CMD 代理即可：`set http_proxy=yourProxy:port`
    - 解决：https://github.com/Microsoft/vscode/issues/45714 中的 `Should be fixed by cc11eb0` 中的链接
  - 可能原因：`package.json` 中将 `"gulp-atom-electron": "^1.15.1",` 修改为 `"gulp-atom-electron": "^1.16.1",`
  - 可能原因：electron 没有安装：
    - `npm install electron -g`
    - 之后再运行 `script/code.bat`

- 其他可能用到
  - 查看 node-gyp 的信息 `node-gyp configure --verbose`

# 经验

- 编译貌似比下载依赖快，第一次编译成功大概用了 60s

  - 机器：SSD、CPU i7、16GB RAM

- 第 1 次打开编译好的 VSCode，会自动联网下载 ffmpeg、electron，此时需要设置 cmd 代理，其地址是 `http://` 开头的
