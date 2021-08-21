# Mac VSCode 打开远程 Docker container 时 git 授权问题（ssh-agent）
先上结论：
- Mac 的 ssh agent 应已启动
- Mac 的 ssh agent 应已加载 ssh key
  - 若未加载，则通过 `ssh-add ~/.ssh/id_rsa` 加载即可

> 本文主要讲述 Mac 中的情况。


# 目录
[TOC]



# 概述
VSCode 的 [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) 官方插件可以打开本机 Docker 的 container 内的目录，也可以打开远程服务器的 container 内的目录。很方便，嗯。

若 Mac 能以 ssh 方式（如 `git@` 开头的 clone） clone git 私有库（已配置 ssh key），此时 VSCode 打开的远程 contaienr 里，应也能 git clone 私有库。



# 问题
有时会发现 Mac 能 git clone，但到了 VSCode 打开的远程 container 里不能 git clone。

本文主要介绍这个问题的来源与解决办法。



# 实验环境
- OS：macOS Big Sur 11.5.1
- VSCode：Version: 1.59.1



# 解决
## 简单版解决
- Mac 的 ssh agent 应已启动
- Mac 的 ssh agent 应已加载 ssh key
  - 若未加载，则通过 `ssh-add ~/.ssh/id_rsa` 加载即可

常用命令：
```sh
# 查看 ssh agent 是否已启动，或已加载哪些 ssh key
ssh-add -l

# 加载 ssh key 到 ssh agent
ssh-add
# 等效于带上默认 ssh key 位置
ssh-add ~/.ssh/id_rsa

# 查看 SSH_AUTH_SOCK 变量值
echo $SSH_AUTH_SOCK

# 查看 Mac 默认的 ssh agent 是否存在
lsof $SSH_AUTH_SOCK

# 清空已加载的 ssh key
ssh-add -D
```





## 详细版解决
### Mac 查看 ssh agent 是否已启动
Mac 中执行命令查看 ssh agent 已加载的 key（也可用于查看 ssh agent 是否已启动）：
```sh
ssh-add -l
```

若 ssh agent 未启动，会输出：
```
Could not open a connection to your authentication agent.
```

若 ssh agent 已启动，但未加载任何 ssh key，会输出：
```
The agent has no identities.
```

若 ssh agent 已启动，且已加载 ssh key，会输出类似：
```
2048 SHA256:8BIVnVYou3RTIeXQeeZFMCJBcdmuCXoewmTkvPuhfgf
```

若 ssh agent 已启动，可通过下面命令查看其进程 pid：
```sh
➜  ~ lsof $SSH_AUTH_SOCK
COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
ssh-agent 39842 viky    3u  unix 0x3da6f7988c416321      0t0      /private/tmp/com.apple.launchd.sv3OfdBSaM/Listeners
```
> 环境变量 SSH_AUTH_SOCK 与 ssh agent 间的关系，可见 [这篇小文](https://github.com/vikyd/note/blob/master/ssh_agent_forwarding.md)



### Mac 启动 ssh agent
根据经验，Mac 的 ssh agent 启动逻辑有些不一样，表现为：

- Mac 开机时默认不会启动 ssh agent（Linux 也不会）
- 但 Mac 开机时默认会自动设置环境变量 `SSH_AUTH_SOCK`，形如：
```sh
➜  ~ echo $SSH_AUTH_SOCK
/private/tmp/com.apple.launchd.sv3OfdBSaM/Listeners
```
- 环境变量 `SSH_AUTH_SOCK` 存在，不代表 ssh agent 进程存在，可这样检查：
```sh
# 无输出，说明 ssh agent 进程不存在
➜  ~ lsof $SSH_AUTH_SOCK
➜  ~
```
```sh
# 有输出，说明 ssh agent 进程存在
➜  ~ lsof $SSH_AUTH_SOCK
COMMAND    PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
ssh-agent 7977 viky    3u  unix 0xdee865b973b41e11      0t0      /private/tmp/com.apple.launchd.xUvbWhPn74/Listeners
➜  ~
```
- 只要执行 `ssh-add` 相关命令，Mac 就会自动启动 ssh agent（而 Linux 不会，且一般通过 `ssh-agent` 命令启动），并复用 `SSH_AUTH_SOCK` 这个 UNIX Socket，例如：
```sh
# 第一次查询，无 ssh agent 进程
➜  ~ lsof $SSH_AUTH_SOCK
# 查询当前 agent 加载的 key
➜  ~ ssh-add -l
The agent has no identities.
# 再次查询，ssh agent 进程出现了
➜  ~ lsof $SSH_AUTH_SOCK
COMMAND    PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
ssh-agent 9223 viky    3u  unix 0xdee865b973b41e11      0t0      /private/tmp/com.apple.launchd.xUvbWhPn74/Listeners
➜  ~
```
- `SSH_AUTH_SOCK` 这个固定值在重启系统后才会变化，譬如重启后变为这个值了：
```sh
➜  ~ echo $SSH_AUTH_SOCK
/private/tmp/com.apple.launchd.xUvbWhPn74/Listeners
```
- 若手动查询 ssh agent 的 pid，并将其 kill 掉，再次查看 ssh agent 状态，会发现 ssh agent 复活了，并且依然复用了原 `SSH_AUTH_SOCK` 的值：
```sh
# 查询 ssh agent 进程，存在，pid 为 9677
➜  ~ lsof $SSH_AUTH_SOCK
COMMAND    PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
ssh-agent 9677 viky    3u  unix 0xdee865b973b41e11      0t0      /private/tmp/com.apple.launchd.xUvbWhPn74/Listeners

# kill 掉 ssh agent 进程
➜  ~ kill 9677

# 再次查看 ssh agent 进程，已不存在
➜  ~ lsof $SSH_AUTH_SOCK

# 查看 ssh agent 是否有加载 ssh key，发现无加载 key
➜  ~ ssh-add -l
The agent has no identities.

# 注意了，此时再看 ssh agent 进程已经复活了，但 pid 不一样了
➜  ~ lsof $SSH_AUTH_SOCK
COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
ssh-agent 10972 viky    3u  unix 0xdee865b973b41e11      0t0      /private/tmp/com.apple.launchd.xUvbWhPn74/Listeners
➜  ~
```
- 若手动 [启动 ssh agent](https://github.com/vikyd/note/blob/master/ssh_agent_forwarding.md#%E5%90%AF%E5%8A%A8%E6%96%B0%E7%9A%84-ssh-agent)，则当前命令中，系统环境变量 `SSH_AUTH_SOCK` 的值会被覆盖：
```sh
# Mac 自动配置的 SSH_AUTH_SOCK
➜  ~ echo $SSH_AUTH_SOCK
/private/tmp/com.apple.launchd.xUvbWhPn74/Listeners

# 手动启动 ssh agent
➜  ~ eval "$(ssh-agent -s)"
Agent pid 9851

# 再次查看环境变量，出现了一个形式不太一样的值
➜  ~ echo $SSH_AUTH_SOCK
/var/folders/0t/yzb0gynd37q_6tkyj87td4h80000gn/T//ssh-c4yPxlD0YGL2/agent.9850
➜  ~
```
- 通过 `ssh-agent` 命令手动启动的 ssh agent 的环境变量 `SSH_AUTH_SOCK` 只会在当前命令窗生效，而不会在未来新开的命令窗生效；未来新开命令窗生效的 `SSH_AUTH_SOCK` 依然会指向 Mac 默认的位置；而 VSCode 默认只认 Mac 默认的 `SSH_AUTH_SOCK`。
- 两种形式的区别：
```sh
# Mac 自配置的 `SSH_AUTH_SOCK` 形式：
/private/tmp/com.apple.launchd.xUvbWhPn74/Listeners

# 用户通过 `ssh-agent` 手动启动得到的 `SSH_AUTH_SOCK` 形式：
/var/folders/0t/yzb0gynd37q_6tkyj87td4h80000gn/T//ssh-c4yPxlD0YGL2/agent.9850
```


### VSCode 的默认行为
- 打开第一个 VSCode 实例时，会自动启动 Mac 的 ssh agent 进程
  - 不是已有 VSCode 窗口再打开新 VSCode 窗口，而是系统刚打开第一个 VSCode 窗口时
  - 此时 VSCode 并未让 ssh agent 加载 ssh key
  - 验证方式：
    - 关闭所有 VSCode 窗口
    - 并在命令行 kill `lsof $SSH_AUTH_SOCK` 找到的 pid
    - 然后再次打开 VSCode
    - 之后再次执行 `lsof $SSH_AUTH_SOCK` 会发现 ssh agent 进程又出来了
    - 只是 `ssh-add -l` 时发现并未加载任何 ssh key。
- 不管 Mac ssh agent 是否已加载 key，此时 VSCode 打开远程 contaienr，并在 VSCode 的命令行中执行 `echo $SSH_AUTH_SOCK`，会输出类似结果：`/tmp/vscode-ssh-auth-9f065a7c36ed9e81e25daf7a37572f3c731ed3f4.sock`。这是 VSCode 自动设置的。
- 若你的 contaienr 已包含 ssh client 相关程序，则可继续执行 `ssh-add -l` 看看 contaienr 内的 ssh agent 情况（Ubuntu 可通过 `apt update && apt install openssh-client -y` 安装）
  - 若 Mac 本身 ssh agent 未启动，且未加载任何 key，则 contaienr 中执行 `ssh-add -l` 会输出：`The agent has no identities.`；并且此时拉起了 Mac 的 ssh agent（通过 Mac 执行 `lsof $SSH_AUTH_SOCK` 可知）
  - 若 Mac 已加载 ssh key，则从 contaienr 执行 `ssh-add -l` 可看到类似输出：`2048 SHA256:8BIVnVYou3RTIeXQeeZFMCJBcdmuCXoewmTkvPuhffg vikydzhang@tencent.com (RSA)`



### 解决
根据 [VSCode 官方文档 - Developing inside a Container](https://code.visualstudio.com/docs/remote/containers#:~:text=the%20extension%20will%20automatically%20forward%20your%20local%20SSH%20agent%20if%20one%20is%20running.)，VSCode 打开远程 contaienr 时，会自动转发本机的 ssh agent 到远程 container 中。

前提是：
- 本机的 ssh agent 已启动
- 本机的 ssh agent 已加载 ssh key
- 本机能让 VSCode 知道环境变量 `SSH_AUTH_SOCK` 的存在

若你刚启动 Mac，此时 Mac 默认已自动配置环境变量 `SSH_AUTH_SOCK`，但并未自动启动 ssh agent 进程。

此时你需要做的是在 Mac 加载 ssh key 即可：
```sh
ssh-add ~/.ssh/id_rsa
```

Mac 再次查看 ssh key 是否已加载：
```sh
# 显示已加载 ssh key
➜  ~ ssh-add -l
2048 SHA256:8BIVnVYou3RTIeXQeeZFMCJBcdmuCXoewmTkvPuhffg
➜  ~
```

此时再在 VSCode 打开的 contaienr 的命令行中查看：
```sh
# 也能看到已加载 ssh key
root@a0a494fa152e:~# ssh-add -l
2048 SHA256:8BIVnVYou3RTIeXQeeZFMCJBcdmuCXoewmTkvPuhffg 
root@a0a494fa152e:~# 
```

也即，此时 VSCode 打开的 contaienr 已复用了 Mac 本机的 ssh 权限了；也即能在 contaienr 内 git clone 你的私有仓库了；也即 git 在 contaienr 内通了。

> 对于本机的 contaienr 或 远程的 contaienr，效果都一样。



# 小结
本文主要讲述 `Mac` + `VSCode` + `远程 Docker Container` + `ssh agent` 的一些潜规则。

- 若想进一步了解 SSH Agent 更详细使用方式，可参考：[SSH Agent Forwarding 的理解与实验](https://github.com/vikyd/note/blob/master/ssh_agent_forwarding.md) 
- 若发现本机 VSCode 发现不了远程 Docker 的 contaienr 列表？可参考 [VSCode 打开 remote host 的 Docker container 的踩坑之旅](https://github.com/vikyd/note/blob/master/vscode_remote_host_container.md)


