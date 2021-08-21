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
- 若 local 命令行已切换 docker context，执行 `docker ps` 会提示
```
Cannot connect to the Docker daemon at http://docker. Is the docker daemon running?
```
- 若是 VSCode 可能看不出提示

原因：
- 忘记把 local ssh 到 remote host 的用户添加到 remote host 的 `docker` group 中。

解决：
- 在 remote host 登录 root，将你平时配置的 ssh 用户添加到名为 `docker` 的 group 中：
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


# 附录表格
VSCode 中如何显示远程 Docker container 列表？


当前打开目录 | Docker Context | 显示的 Contaienr 列表 |
---|---|---|
本机目录 | 本机 | 本机 |
本机目录 | 远程 | 远程 ★ |
远程目录 | 本机 | 远程 ★ |
远程目录 | 远程 | 远程 ★ |

结论：
- 只要打开了 `远程目录`，则 VSCode 的 Remote Explorer 显示的 Contaienr 列表必然是 `远程` 的
- 若打开了 `本机目录`，且本机 Docker Context 指向了远程，则 VSCode 的 Remote Explorer 显示的 Contaienr 列表也是 `远程` 的
- 全程貌似与 VSCode 的配置 `settings.json` 的 `docker.host` 项无关


