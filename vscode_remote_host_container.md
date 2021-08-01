<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [VSCode 打开 remote host 的 Docker container 的踩坑之旅](#vscode-%E6%89%93%E5%BC%80-remote-host-%E7%9A%84-docker-container-%E7%9A%84%E8%B8%A9%E5%9D%91%E4%B9%8B%E6%97%85)
- [目录](#%E7%9B%AE%E5%BD%95)
- [名词约定](#%E5%90%8D%E8%AF%8D%E7%BA%A6%E5%AE%9A)
- [踩过的坑](#%E8%B8%A9%E8%BF%87%E7%9A%84%E5%9D%91)
  - [问题：忘记把 ssh 用户加入到 docker](#%E9%97%AE%E9%A2%98%E5%BF%98%E8%AE%B0%E6%8A%8A-ssh-%E7%94%A8%E6%88%B7%E5%8A%A0%E5%85%A5%E5%88%B0-docker)
  - [问题：VSCode `REMOTE EXPLORER` -> `Containers` 无内容（VSCode 应先打开 remote host 目录）](#%E9%97%AE%E9%A2%98vscode-remote-explorer---containers-%E6%97%A0%E5%86%85%E5%AE%B9vscode-%E5%BA%94%E5%85%88%E6%89%93%E5%BC%80-remote-host-%E7%9B%AE%E5%BD%95)
  - [问题：VSCode `REMOTE EXPLORER` -> `Containers` 无内容（local 命令行应先切换 docker context 到 remote）](#%E9%97%AE%E9%A2%98vscode-remote-explorer---containers-%E6%97%A0%E5%86%85%E5%AE%B9local-%E5%91%BD%E4%BB%A4%E8%A1%8C%E5%BA%94%E5%85%88%E5%88%87%E6%8D%A2-docker-context-%E5%88%B0-remote)
  - [问题：`"docker.host"`？](#%E9%97%AE%E9%A2%98dockerhost)
  - [其他问题](#%E5%85%B6%E4%BB%96%E9%97%AE%E9%A2%98)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# VSCode 打开 remote host 的 Docker container 的踩坑之旅
通过 VSCode 打开远程服务器内的 docker container 作为开发环境，是个挺有意思的事。

> 介绍可看 [官方文档](https://code.visualstudio.com/docs/remote/containers-advanced#_a-basic-remote-example)。


有时会碰到这样的坑：**VSCode 能打开 remote host 的目录，但显示不了、也打开不了 remot host 上的 container**。


# 目录
[TOC]


# 名词约定
为精确简便，约定以下名词：
- `local`：本地机器，如你面前的 Mac、Win
- `remote`：远程机器
- `remote host`：远程机器的宿主机本身（相对容器来说）
- `container`：容器
- `remote host 的 container`：指远程机器安装了 Docker，里面的 container



# 踩过的坑
VSCode 连接 remote host 的 container 会有很多坑，因为涉及 ssh 配置、用户组添加、操作姿势、docker 概念等。

- 有些错误可能不只是 1 个原因导致的，所以不一定看到某个错误就一定是某个原因



## 问题：忘记把 ssh 用户加入到 docker 
详细错误：
- 若是 local 命令行已切换 docker context，执行 `docker ps` 会提示
```
Cannot connect to the Docker daemon at http://docker. Is the docker daemon running?
```
- 若是 VSCode 可能看不出提示

原因：
- 忘记把从 local ssh 到 remote host 的用户添加到 remote host 的 `docker` group 中。

解决：
- 在 remote host 登录 root，将平时你平时配置的 ssh 用户添加到名为 `docker` 的 group 中：
```sh
# 将 yourUserName 添加到 docker 这个 group 中
usermod -aG docker yourUserName
```

备注：
- 若想回头看看从 docker group 删除该用户的情况，可参考命令：
```sh
# 表示从 docker 这个 group 移除用户 yourUserName
gpasswd -d yourUserName docker
```


## 问题：VSCode `REMOTE EXPLORER` -> `Containers` 无内容（VSCode 应先打开 remote host 目录）
详细错误：
- 明明在 remot host 命令行能 `docker ps` 看到 container 列表，但VSCode `REMOTE EXPLORER` -> `Containers` 看不到 remote host 的任何 container，只看到：
```
Get started with containers by installing Docker or by visiting the help view. 
Refresh after installation and startup.
```

原因：
- 可能 VSCode 当前打开的是本地目录，或未打开任何目录

解决：
- VSCode 先打开 remote host 的目录（这是关键步骤），再点开左侧栏 `REMOTE EXPLORER` -> `Containers` 才能看到 remote host 里的 container 列表（可以理解为 VSCode 故意的）。

参考：
- [其他人也碰到过此问题](https://stackoverflow.com/questions/60425053/vs-code-connect-a-docker-container-in-a-remote-server/67131056#67131056)



## 问题：VSCode `REMOTE EXPLORER` -> `Containers` 无内容（local 命令行应先切换 docker context 到 remote）
详细错误：
- 与上一问题的症状一致

原因：
- 可以考虑切换 docker context 指向 remote 的 docker

解决：
- 在 local 命令行中将 docker context 切换到 remote host
  - 在 local 命令行执行：
```sh
# 创建指向 remote 的 docker context
docker context create my-remote-context --docker "host=ssh://userName@remoteIP:port"

# 查看当前的 context 列表（非必须）
# 第 1 列有星星符号 `*` 的表示当前 context
docker context ls

# 切换到 remote host 的 context
docker context use my-remote-context
  
# 切换回 local 的 docker context（非必须）
docker context use default
```
> 本解决方式与前一问题的解决办法可二选一

解释：
- 可将 docker 大致理解为客户端与服务端
  - 客户端是 `docker` 命令
  - 服务端是 `dockerd` 进程 
  - `docker context` 用于方便 docker 客户端切换到不同的服务端


参考：
- [VS Code: connect a docker container in a remote server](https://stackoverflow.com/a/63814363/2752670)


## 问题：`"docker.host"`？
不管如何，貌似都与 VSCode 的此 [配置](https://code.visualstudio.com/docs/remote/containers-advanced#_a-basic-remote-example) （`settings.json`）无关：
```json
{
   "docker.host":"ssh://your-remote-user@your-remote-machine-fqdn-or-ip-here"
}
```


## 其他问题
VSCode + remote host 的 container 作为开发环境还有不少问题需解决，如：如何在 remote host 的 container 内拥有 git pull/push 等权限？这是题外话了。


