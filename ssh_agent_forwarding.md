<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [SSH Agent Forwarding 的理解与实验](#ssh-agent-forwarding-%E7%9A%84%E7%90%86%E8%A7%A3%E4%B8%8E%E5%AE%9E%E9%AA%8C)
- [实验](#%E5%AE%9E%E9%AA%8C)
  - [实验环境](#%E5%AE%9E%E9%AA%8C%E7%8E%AF%E5%A2%83)
  - [配置](#%E9%85%8D%E7%BD%AE)
    - [A 的配置](#a-%E7%9A%84%E9%85%8D%E7%BD%AE)
    - [B 的配置](#b-%E7%9A%84%E9%85%8D%E7%BD%AE)
    - [C 无需配置](#c-%E6%97%A0%E9%9C%80%E9%85%8D%E7%BD%AE)
  - [分两个步骤](#%E5%88%86%E4%B8%A4%E4%B8%AA%E6%AD%A5%E9%AA%A4)
  - [步骤 01 ：从 A ssh 登录到 B](#%E6%AD%A5%E9%AA%A4-01-%E4%BB%8E-a-ssh-%E7%99%BB%E5%BD%95%E5%88%B0-b)
    - [方式 01 ：ssh 命令中增加 `-A` 参数](#%E6%96%B9%E5%BC%8F-01-ssh-%E5%91%BD%E4%BB%A4%E4%B8%AD%E5%A2%9E%E5%8A%A0--a-%E5%8F%82%E6%95%B0)
    - [方式 02 ：修改 A 中 `~/.ssh/config` 对应 B 的 Host 块](#%E6%96%B9%E5%BC%8F-02-%E4%BF%AE%E6%94%B9-a-%E4%B8%AD-sshconfig-%E5%AF%B9%E5%BA%94-b-%E7%9A%84-host-%E5%9D%97)
  - [步骤 02 ：验证](#%E6%AD%A5%E9%AA%A4-02-%E9%AA%8C%E8%AF%81)
    - [验证 B 能 ssh 到 C](#%E9%AA%8C%E8%AF%81-b-%E8%83%BD-ssh-%E5%88%B0-c)
    - [验证 B 能基于 ssh clone Github](#%E9%AA%8C%E8%AF%81-b-%E8%83%BD%E5%9F%BA%E4%BA%8E-ssh-clone-github)
    - [验证不转发 ssh agent 时的情况](#%E9%AA%8C%E8%AF%81%E4%B8%8D%E8%BD%AC%E5%8F%91-ssh-agent-%E6%97%B6%E7%9A%84%E6%83%85%E5%86%B5)
- [ssh agent 的环境变量](#ssh-agent-%E7%9A%84%E7%8E%AF%E5%A2%83%E5%8F%98%E9%87%8F)
  - [SSH_AUTH_SOCK](#ssh_auth_sock)
  - [SSH_AGENT_PID](#ssh_agent_pid)
- [ssh agent 的命令列表](#ssh-agent-%E7%9A%84%E5%91%BD%E4%BB%A4%E5%88%97%E8%A1%A8)
  - [查看当前 ssh agent 已加载的 key](#%E6%9F%A5%E7%9C%8B%E5%BD%93%E5%89%8D-ssh-agent-%E5%B7%B2%E5%8A%A0%E8%BD%BD%E7%9A%84-key)
  - [启动新的 ssh agent](#%E5%90%AF%E5%8A%A8%E6%96%B0%E7%9A%84-ssh-agent)
  - [ssh agent 加载私钥](#ssh-agent-%E5%8A%A0%E8%BD%BD%E7%A7%81%E9%92%A5)
  - [ssh agent 取消已加载的私钥](#ssh-agent-%E5%8F%96%E6%B6%88%E5%B7%B2%E5%8A%A0%E8%BD%BD%E7%9A%84%E7%A7%81%E9%92%A5)
  - [停止 ssh agent](#%E5%81%9C%E6%AD%A2-ssh-agent)
  - [查看 ssh agent 列表](#%E6%9F%A5%E7%9C%8B-ssh-agent-%E5%88%97%E8%A1%A8)
- [Mac、Linux 的 ssh agent](#maclinux-%E7%9A%84-ssh-agent)
  - [Mac 中 ssh agent 默认行为](#mac-%E4%B8%AD-ssh-agent-%E9%BB%98%E8%AE%A4%E8%A1%8C%E4%B8%BA)
  - [Linux 中 ssh agent 的默认行为](#linux-%E4%B8%AD-ssh-agent-%E7%9A%84%E9%BB%98%E8%AE%A4%E8%A1%8C%E4%B8%BA)
  - [Mac：如果 kill 掉默认启动的 ssh agent](#mac%E5%A6%82%E6%9E%9C-kill-%E6%8E%89%E9%BB%98%E8%AE%A4%E5%90%AF%E5%8A%A8%E7%9A%84-ssh-agent)
  - [Mac：手动启动新 ssh agent](#mac%E6%89%8B%E5%8A%A8%E5%90%AF%E5%8A%A8%E6%96%B0-ssh-agent)
  - [Mac：VSCode 基于 ssh agent 授权远程机器 git clone](#macvscode-%E5%9F%BA%E4%BA%8E-ssh-agent-%E6%8E%88%E6%9D%83%E8%BF%9C%E7%A8%8B%E6%9C%BA%E5%99%A8-git-clone)
- [踩坑、疑问列表](#%E8%B8%A9%E5%9D%91%E7%96%91%E9%97%AE%E5%88%97%E8%A1%A8)
  - [踩坑：以为 ssh agent 进程是全局唯一的](#%E8%B8%A9%E5%9D%91%E4%BB%A5%E4%B8%BA-ssh-agent-%E8%BF%9B%E7%A8%8B%E6%98%AF%E5%85%A8%E5%B1%80%E5%94%AF%E4%B8%80%E7%9A%84)
  - [踩坑：以为启动 ssh agent 时的输出是结果](#%E8%B8%A9%E5%9D%91%E4%BB%A5%E4%B8%BA%E5%90%AF%E5%8A%A8-ssh-agent-%E6%97%B6%E7%9A%84%E8%BE%93%E5%87%BA%E6%98%AF%E7%BB%93%E6%9E%9C)
  - [踩坑：Mac 启动的 VSCode 基于哪个 ssh-agent 实例？](#%E8%B8%A9%E5%9D%91mac-%E5%90%AF%E5%8A%A8%E7%9A%84-vscode-%E5%9F%BA%E4%BA%8E%E5%93%AA%E4%B8%AA-ssh-agent-%E5%AE%9E%E4%BE%8B)
  - [踩坑：`AllowAgentForwarding` 应配置到有私钥还是没私钥的一端？](#%E8%B8%A9%E5%9D%91allowagentforwarding-%E5%BA%94%E9%85%8D%E7%BD%AE%E5%88%B0%E6%9C%89%E7%A7%81%E9%92%A5%E8%BF%98%E6%98%AF%E6%B2%A1%E7%A7%81%E9%92%A5%E7%9A%84%E4%B8%80%E7%AB%AF)
  - [踩坑：以为 `~/.ssh/config` 配置的 host 与 `ssh user@ip` IP端口一致就会复用参数](#%E8%B8%A9%E5%9D%91%E4%BB%A5%E4%B8%BA-sshconfig-%E9%85%8D%E7%BD%AE%E7%9A%84-host-%E4%B8%8E-ssh-userip-ip%E7%AB%AF%E5%8F%A3%E4%B8%80%E8%87%B4%E5%B0%B1%E4%BC%9A%E5%A4%8D%E7%94%A8%E5%8F%82%E6%95%B0)
  - [疑问：如何在 B 的其他命令窗复用 B 中曾转发过的 `SSH_AUTH_SOCK`？](#%E7%96%91%E9%97%AE%E5%A6%82%E4%BD%95%E5%9C%A8-b-%E7%9A%84%E5%85%B6%E4%BB%96%E5%91%BD%E4%BB%A4%E7%AA%97%E5%A4%8D%E7%94%A8-b-%E4%B8%AD%E6%9B%BE%E8%BD%AC%E5%8F%91%E8%BF%87%E7%9A%84-ssh_auth_sock)
  - [疑问：即使没有 ssh、ssh-agent、ssh-add 工具，git 能用起 `SSH_AUTH_SOCK`？](#%E7%96%91%E9%97%AE%E5%8D%B3%E4%BD%BF%E6%B2%A1%E6%9C%89-sshssh-agentssh-add-%E5%B7%A5%E5%85%B7git-%E8%83%BD%E7%94%A8%E8%B5%B7-ssh_auth_sock)
  - [疑问：ssh-agent 加载私钥后，若将私钥文件删除，ssh agent 能否继续用？](#%E7%96%91%E9%97%AEssh-agent-%E5%8A%A0%E8%BD%BD%E7%A7%81%E9%92%A5%E5%90%8E%E8%8B%A5%E5%B0%86%E7%A7%81%E9%92%A5%E6%96%87%E4%BB%B6%E5%88%A0%E9%99%A4ssh-agent-%E8%83%BD%E5%90%A6%E7%BB%A7%E7%BB%AD%E7%94%A8)
- [TODO](#todo)
- [参考](#%E5%8F%82%E8%80%83)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# SSH Agent Forwarding 的理解与实验

SSH Agent Forwarding 又可叫 SSH Agent 转发、SSH 代理转发，可用于让没有 SSH 私钥的机器 B 也能通过拥有私钥的 A 里的 SSH Agent 来获取授权。

- ssh-agent 是 A 的本地进程
- ssh agent `转发` 是指从 A ssh 登录到 B 时附带了转发 ssh agent 的参数


SSH Agent Forwarding 的更详细作用可网上搜索，这里不再描述，只说些实验过程和踩过的坑。

[TOC]



# 实验
SSH Agent Forwarding：A ssh 到 B 后，再从 B ssh 到 C 时，B 能自动利用 A 的 ssh agent 的信息来 ssh 到 C。（而不是指单纯的 B ssh 到 C，因为需先从 A ssh 到 B））


## 实验环境
> `ssh 到` 指：ssh 登录、基于 ssh 的 git clone 等

> 下面 IP 仅为了易于理解示例，不一定必须这样地址

3 台机器：
- A：`10.10.10.11` 本机（如 Mac 或 Win）
- B：`10.10.10.12` Linux 服务器（用户名 `userAbc`）
- C：`10.10.10.13` 另一台 Linux 服务器（用户名 `userDef`）

1 个外部网站：
- D：`github.com` （用于基于 ssh 的 git clone）

前提（重要）：
- A 上有 ssh 私钥（如 `~/.ssh/id_rsa`）
- A 已可基于私钥直接 ssh 到 B
- A 已可基于私钥直接 ssh 到 C
- A 已可基于私钥 clone Github 的仓库
- B 本身不能 ssh 到 C（无 C 信任的私钥）
- B 本身不能基于 ssh clone Github 的仓库


## 配置
先做以下配置，再继续后面的实验步骤。
### A 的配置
先查看 ssh agent 否已加载 ssh 私钥（非必须）：
```sh
ssh-add -l
```
- 若已启动且已加载私钥会输出：`2048 SHA256:一长串字符串 (RSA)`
  - 此时无需继续往下执行
- 若未启动会提示   ：`Could not open a connection to your authentication agent.`
  - 此时需先启动 ssh agent
- 若已启动但未加载私钥：`The agent has no identities.`
  - 此时需加载私钥


若已启动，则忽略本步，若未启动，则启动 ssh agent：
> 会自动跑到后台，即使关闭当前窗口，ssh-agent 进程也不会退出。后面有小节会解释此命令。

```sh
eval "$(ssh-agent -s)"
```

若已加载私钥，则忽略本步，若未加载，则加载所需的私钥（按需修改私钥位置）：
```sh
ssh-add ~/.ssh/id_rsa
```


再次确认加载的 key（非必须）：
```sh
ssh-add -l
```
> 此时应能看到类似 `2048 SHA256:一长串字符串 (RSA)` 的已加载 key



### B 的配置
- `/etc/ssh/sshd_config` 里的 `AllowAgentForwarding` 设置为：`yes`
```
AllowAgentForwarding yes
```
- 然后重启 sshd：`systemctl restart  sshd.service`



### C 无需配置
嗯。


## 分两个步骤
- 步骤 01 ：从 A ssh 登录到 B
- 步骤 02 ：在步骤 01 基础上继续从 B ssh 登录到 C，或 clone  Github 仓库

## 步骤 01 ：从 A ssh 登录到 B
从 A ssh 登录到 B 时，需在 A 中配置启用 ssh agent forwarding。

有两种方式（二选一，而非两者都需要）：
1. ssh 命令中增加 `-A` 参数
1. 修改 A 的 `~/.ssh/config` 对应 B 的 Host 块中里增加 `ForwardAgent yes`。

### 方式 01 ：ssh 命令中增加 `-A` 参数
在前面 A 启动 ssh-agent 的命令窗中执行：
```sh
ssh -A userAbc@10.10.10.12 -p 22
```
> `-A`：表示启用 ssh agent forwarding

> 表示从 A（10.10.10.11） ssh 登录到 B（10.10.10.12）时带上 ssh-agent


### 方式 02 ：修改 A 中 `~/.ssh/config` 对应 B 的 Host 块
`~/.ssh/config`：
```config
Host serverB
  User userAbc
  HostName 10.10.10.12
  Port 22
  IdentityFile ~/.ssh/id_rsa
  # ↓ 增加下面这行，等价于命令行参数 `-A`
  ForwardAgent yes
```

此时 ssh 命令应为（不用再填 IP 端口那么麻烦了）：
```sh
ssh serverB
```
> 因为 `~/.ssh/config` 配置了 `Host serverB`，所以命令就是 `ssh serverB`



## 步骤 02 ：验证
此时，在 B 中：
- 执行 `ssh-add -l` 应该能看到 A 的私钥列表
- 能看到 B 有了：
  - 环境变量 `SSH_AUTH_SOCK`
- 能发现 B 没有：
  - 没有环境变量 `SSH_AGENT_PID`
  - 没有 `ssh-agent` 进程，只存在于 A 里

### 验证 B 能 ssh 到 C
在 `步骤 01` 得到的 B 命令行中，执行下面命令即可从 B ssh 登录到 C ：
> 此时不用带参数 `-A`
```sh
ssh userDef@10.10.10.13 -p 22
```

注意：
- B 没有可登录 C 的 ssh 私钥
  - 原理是：C 向 B 询问需私钥验证信息时，B 再去问 A 拿到对应信息，再返回给 C（不是私钥本身） ，C 即可允许 B ssh 到 C。
- B ssh 登录到 C 的命令可无需 ssh agent forwarding 参数（即不带参数 `-A`）


### 验证 B 能基于 ssh clone Github
> 假设 A 的私钥对应的公钥也已 [放到 Github](https://github.com/settings/keys)，即 A 本身可基于 ssh clone Github 的仓库。

在 `步骤 01` 得到的 B 命令行中，执行下面命令即可从 B 基于 ssh clone  Github 仓库：
```sh
git clone git@github.com:google/uuid.git
```

### 验证不转发 ssh agent 时的情况
假设 A ssh 登录到 B 时没带上转发参数 `-A`：
```sh
ssh userAbc@10.10.10.12 -p 22
```

此时已从 A ssh 登录到 B，并继续在此命令窗尝试从 B ssh 登录 C，会发现不能登录了，可能会得到类似下面的输出：
```
userDef@10.10.10.13's password:
```




# ssh agent 的环境变量
ssh agent 涉及的环境变量主要包括：
- `SSH_AUTH_SOCK`
- `SSH_AGENT_PID`

`ssh-add`、`ssh-agent` 的一些行为会基于这两个环境变量，后面会有说明。


## SSH_AUTH_SOCK
环境变量 `SSH_AUTH_SOCK` 的值指向一个 [Unix Socket 文件](https://blog.csdn.net/z2066411585/article/details/78966434/)，用于其他程序与 ssh agent 在同一系统内通讯。

例如：
```sh
➜  ~ echo $SSH_AUTH_SOCK   
/tmp/ssh-BsVvOavKm87T/agent.1251330
➜  ~ 
```




## SSH_AGENT_PID
环境变量 `SSH_AGENT_PID` 的值指向 ssh agent 的进程 PID。

例如:
```sh
➜  ~ echo $SSH_AGENT_PID 
1251331
➜  ~ 
```

> 一个系统内允许多个 ssh agent 进程，互相独立


# ssh agent 的命令列表
ssh agent 相关的命令列表：
- `ssh`：用于 ssh 登录等
- `ssh-agent`：用于启动、停止 ssh agent
- `ssh-add`：用于添加/移除 key 到 agent、查看已加载 key 列表

## 查看当前 ssh agent 已加载的 key
```sh
ssh-add -l
```
- 若 ssh agent 已启动且有 key 会输出：`2048 SHA256:一长串字符串 (RSA)`
- 若未启动会提示   ：`Could not open a connection to your authentication agent.`
- 若已启动但无 key ：`The agent has no identities.`

注意：
- `ssh-add -l` 显示的是当前命令行的环境变量 `SSH_AUTH_SOCK` 指向的 ssh agent
  - `echo $SSH_AUTH_SOCK` 可查看当前 ssh agent 的 unix socket 文件位置
- `ssh-add -l` 与环境变量 `SSH_AGENT_PID` 无关


## 启动新的 ssh agent
启动新 ssh agent 的命令：
```sh
eval "$(ssh-agent -s)"
```

若启动成功，会有类似输出：
```
Agent pid 1509834
```

解释：
- 若只执行 `ssh-agent`，而非 `eval "$(ssh-agent -s)"`：
  ```sh
  ➜  ~ ssh-agent
  SSH_AUTH_SOCK=/tmp/ssh-qsedlTZTnJLS/agent.1565122; export SSH_AUTH_SOCK;
  SSH_AGENT_PID=1565123; export SSH_AGENT_PID;
  echo Agent pid 1565123;
  ➜  ~ 
  ```
  - 此时也启动了新 ssh agent 进程，其 pid 为 `1565123`
  - 但此时不会自动修改环境变量 `SSH_AUTH_SOCK`、`SSH_AGENT_PID` 的值
  - 可看到输出有 3 行信息，是 3 行可执行的命令
    - 用户可执行或不执行
    - 只有执行了这 3 行命令，才能真正修改环境变量 `SSH_AUTH_SOCK`、`SSH_AGENT_PID` 的值
- `ssh-agent -s` 中的 `-s` 表示输出的上述 3 行命令应是 [bash](https://man7.org/linux/man-pages/man1/ssh-agent.1.html#top_of_page) 风格，而非 [C shell](https://en.wikipedia.org/wiki/C_shell) 风格。`-s` 参数可要可不要，因为 ssh-agent 会自动检测 shell 类型
- `eval "$(ssh-agent -s)"` 中的 `eval "$( )"` 表示会将 `ssh-agent` 输出的上述 3 行文本作为命令执行
- 多次启动 ssh agent，最终会怎样？
  - 答：会得到多个互相对立的 ssh agent 进程。
- 当前命令行最终会使用哪个 ssh agent 进程？
  - 答：最终会使用环境变量 `SSH_AUTH_SOCK` 指向的那个 ssh agent，若 `SSH_AUTH_SOCK` 为空，则不管后台有多少个 ssh agent 都没用
- `SSH_AUTH_SOCK` 的值 `/tmp/ssh-qsedlTZTnJLS/agent.1565122` 的解释：
  - 格式：`$TMPDIR/ssh-XXXXXXXXXX/agent.<ppid>`
  - `qsedlTZTnJLS` 是随机字符串，感觉 ssh agent 机制本身故意不想让 ssh agent 实例被其他命令窗复用。
  - 安全问题，`SSH_AUTH_SOCK` 指向的 unix socket 文件可被以 root 登录 B 的任意使用者使用。若想更安全，可考虑使用 [ProxyJump 机制](https://www.infoworld.com/article/3619278/proxyjump-is-safer-than-ssh-agent-forwarding.html)。
  - `agent.1565122` 与 `SSH_AGENT_PID=1565123` 的关系是：pid 与 ppid 的关系
- `ssh-agent -a my-agent-sock-file` 命令：
  - 表示把 `SSH_AUTH_SOCK` 存放为指定文件 `my-agent-sock-file`（`ls -lah` 查看可知是一个 `s` 开头的文件类型，表示 [unix socket file](https://linuxconfig.org/identifying-file-types-in-linux)）
  - 注意：此时若 kill 对应的 ssh agent 进程，也不会自动删除该文件，可手动删除
- 新的 ssh agent 进程启动后，不会自动加载任何私钥
- 关闭当前命令，是否会自动结束此命令行曾启动过的 ssh agent？
  - 答：不会。ssh agent 依然在后台跑着，除非被手动 kill 掉。



## ssh agent 加载私钥
添加私钥到 ssh agent 的命令：
```sh
ssh-add ~/.ssh/id_rsa
```

解释：
- 注意：此时只会添加私钥到 `SSH_AUTH_SOCK` 指向的 ssh agent，不影响其他 ssh agent 加载的私钥。
- 也可以不添加参数 `~/.ssh/id_rsa`，直接 `ssh-add` 命令
  - 因为不指定私钥位置时，[默认](https://linux.die.net/man/1/ssh-add) 会加载这些私钥（存在的话）：
    - `~/.ssh/id_rsa`
    - `~/.ssh/id_dsa`
    - `~/.ssh/id_ecdsa`
    - `~/.ssh/id_ed25519`
    - `~/.ssh/identity`
- 若你的私钥文件名不一样，也可以：`ssh-add ~/.ssh/你的私钥文件名`


## ssh agent 取消已加载的私钥
取消所有已加载到当前 ssh agent 的私钥的命令：
```sh
ssh-add -D
```

若是取消单个私钥：
```sh
ssh-add -d ~/.ssh/id_rsa
```

解释：
- 注意：此时针对的是 `SSH_AUTH_SOCK` 指向的 ssh agent，对其他 ssh agent 不影响
- `ssh-add -d` 不带私钥路径参数，则会取消加载默认位置的私钥



## 停止 ssh agent
停止 ssh agent 的命令：
```sh
eval "$(ssh-agent -k)"
```

解释：
- 此时会 kill 掉当前环境变量 `SSH_AGENT_PID` 指向的 ssh agent 进程，不影响其他 ssh agent 进程
- 若只执行 `ssh-agent`，而非 `eval "$(ssh-agent -k)"`：
  ```sh
  ➜  ~ ssh-agent -k
  unset SSH_AUTH_SOCK;
  unset SSH_AGENT_PID;
  echo Agent pid 1565123 killed;
  ➜  ~ 
  ```
  - 参数 `-k` 表示停止 ssh agent 的意思
  - 此时不会自动修改环境变量 `SSH_AUTH_SOCK`、`SSH_AGENT_PID` 的值
  - 可看到输出有 3 行文本，是 3 行可执行的命令
    - 用户可执行或不执行
    - 只有执行了前 2 行命令，才能真正取消环境变量 `SSH_AUTH_SOCK`、`SSH_AGENT_PID` 的值
    - 若不执行，则 `SSH_AUTH_SOCK`、`SSH_AGENT_PID` 的值维持不变，但实际其指向的 ssh agent 进程已经不存在了
- `eval "$(ssh-agent -k)"` 中的 `eval "$( )"` 表示将 `ssh-agent -k` 输出的上述 3 行命令执行了
  - 也即表示除了 kill ssh agent 进程外，还会同时取消环境变量 `SSH_AUTH_SOCK`、`SSH_AGENT_PID` 的值
- `ssh-agent -k` 本质是 kill ssh agent 进程，也可以自行 kill：
  ```sh
  ➜  ~ echo $SSH_AGENT_PID 
  1874024
  ➜  ~ kill 1874024
  ➜  ~ 
  ```



## 查看 ssh agent 列表
若想查看当前命令行的 ssh agent：
```sh
echo $SSH_AUTH_SOCK
echo $SSH_AGENT_PID
```

若想查看系统全部的 ssh agent，暂未找到明确的办法，因为 ssh agent 进程有可能由编程语言自行启动，而不一定是 `ssh-agent` 命令启动。

参考：https://stackoverflow.com/questions/40549332/how-to-check-if-ssh-agent-is-already-running-in-bash



# Mac、Linux 的 ssh agent
## Mac 中 ssh agent 默认行为
> Mac 是指苹果的 macOS，当前测试版本是 macOS Big Sur 11.4

Mac 关于 ssh agent 的默认行为（[参考](https://code.visualstudio.com/docs/remote/containers#:~:text=macOS%20typically%20has%20it%20running%20by%20default)）：
- 开机会默认启动一个 ssh agent 进程
- 会默认设置环境变量 `SSH_AUTH_SOCK` 指向 ssh agent，其值类似 `/private/tmp/com.apple.launchd.CBa7idWY89/Listeners`
- 不会默认设置 `SSH_AGENT_PID` 环境变量
- 默认启动的 ssh agent 不加载任何私钥
- 查看默认 ssh agent 进程 的 pid：`lsof /private/tmp/com.apple.launchd.CBa7idWY89/Listeners`
- 一键查看 Mac ssh agent 的 pid：`lsof $SSH_AUTH_SOCK`


## Linux 中 ssh agent 的默认行为
Linux 关于 ssh agent 的默认行为：
- 开机默认不会启动 ssh agent 进程，需手动启动
- 也不会设置 `SSH_AGENT_PID`、`SSH_AUTH_SOCK` 环境变量


## Mac：如果 kill 掉默认启动的 ssh agent
Mac 里如果 kill 掉默认启动的 ssh agent 后，会发生这样的事情：
> 如 `pkill ssh-agent` kill 掉所有 ssh agent 进程
- 再次查看默认 ssh agent 进程 的 pid：`lsof /private/tmp/com.apple.launchd.CBa7idWY89/Listeners`，会看不到任何进程
- 若执行 `ssh-add -l` 或 `ssh-add ~/.ssh/id_rsa` 等 `ssh-add` 命令，Mac 会默默再次启动一个 ssh agent 进程（进程 pid 肯定也不一样了），而且依然是指向上面看到的 `/private/tmp/com.apple.launchd.CBa7idWY89/Listeners`
  - 挺神奇的机制


## Mac：手动启动新 ssh agent
Mac 里手动启动新 ssh agent 的特点：
- 可以 `eval "$(ssh-agent -s)"` 启动
- `SSH_AUTH_SOCK` 的 unix socket 文件位置区别：
  - Mac 默认启动的：`/private/tmp/com.apple.launchd.CBa7idWY89/Listeners`
  - 手动启动的：`/var/folders/0t/yzb0gynd37q_6tkyj87td4h80000gn/T//ssh-yrnpNFPwFloR/agent.23124`
- 基本行为与 Linux 一致



## Mac：VSCode 基于 ssh agent 授权远程机器 git clone
> 由于 VSCcode Remote Development 系列插件 [不开源](https://code.visualstudio.com/docs/remote/faq#_why-arent-the-remote-development-extensions-or-their-components-open-source)，所以下面结论均为实验经验而得

VSCode 官方的 [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) 插件支持一键打开远程服务器内运行的 container（按前面实验的说法就是 B 中装了 Docker，且跑起了一个 container），且能默认把 A 中的 ssh agent 转发到 container，使得 contianer 内能拥有与 A 一致的 git clone、push 等权限，方便在 container 内进行项目开发。

但曾经踩过一些坑，故事有些啰嗦：
- 环境：本机 A 是 MacBook Pro，B 是一个远程 Linux 服务器，B 中装了 Docker，并启动了一个 container
- 最初，不知道 ssh agent 为何物。当知道 ssh agent 为何物时，在 Mac 中手动启动了 ssh agent，且配置了 `SSH_AUTH_SOCK`，发现 VSCode 打开的远程 container 内依然不能 git clone
- 再摸索，发现原来在手动启动 ssh agent 的命令窗中以此命令 `code`（这个命令就是 `code` 四个字母）打开 VSCode ，然后再在 VScode 打开远程 container ，终于 container 内可以 git clone 了
- 总觉得每次 `code` 打开 VSCode 很麻烦，应该还有更简单方法，于是继续搜搜搜
- 后来发现，Mac 开机默认会启动 ssh agent，只需打开新命令窗执行 `ssh-add ~/.ssh/id_rsa` 把私钥加载到默认 ssh agent 中，而且此时无需手动启动 ssh agent。然后按正常方式点开 VSCode，并打开远程 container，发现也能 git clone 了，问题解决了。
  - 也即 VSCode 默认会识别 Mac 的默认启动的 ssh agent（猜测是通过默认的环境变量 `SSH_AUTH_SOCK` 识别的）
- VSCode 打开远程 container 后，可在 container 执行 `ssh-add -l`（命令存在的话）查看 Mac 的私钥列表
  - 由于 Mac 默认启动 ssh agent 且多个命令窗默认共享同一个 `SSH_AUTH_SOCK`，此时若在 Mac 的命令窗增删私钥，再查看远程 container 的私钥列表也同步发生了变化
- 故事结束



# 踩坑、疑问列表
## 踩坑：以为 ssh agent 进程是全局唯一的
答：ssh agent 并非全局唯一，可以有多个不同的进程，进程间互相独立。


## 踩坑：以为启动 ssh agent 时的输出是结果
答：输出的不是结果，输出的是待继续执行的命令。

假设直接跑起命令 `ssh-agent`，而非 `eval "$(ssh-agent -s)"`：
```sh
➜  ~ ssh-agent
SSH_AUTH_SOCK=/tmp/ssh-qsedlTZTnJLS/agent.1565122; export SSH_AUTH_SOCK;
SSH_AGENT_PID=1565123; export SSH_AGENT_PID;
echo Agent pid 1565123;
➜  ~ 
```
得到的这 3 行是命令，主要作用是设置相关命令行，可手动复制这 3 行执行。

这就是为什么建议使用 `eval "$(ssh-agent -s)"`，因为这样会在启动 ssh agent 的同时把打印出来的命令也执行了，也就把环境变量设置了。


## 踩坑：Mac 启动的 VSCode 基于哪个 ssh-agent 实例？
答：基于 Mac 开机默认启动的 ssh agent 进程，其 `SSH_AUTH_SOCK` 在类似这样的位置：`/private/tmp/com.apple.launchd.CBa7idWY89/Listeners`


## 踩坑：`AllowAgentForwarding` 应配置到有私钥还是没私钥的一端？
答：应配置到没有私钥的那一端，即配置到 B 的 `/etc/ssh/sshd_config`，且需重启 sshd 服务：`systemctl restart sshd.service`。


## 踩坑：以为 `~/.ssh/config` 配置的 host 与 `ssh user@ip` IP端口一致就会复用参数
答：是互相独立的。

即使已配置 `~/.ssh/config` 对应 B 的 Host 块增加 `ForwardAgent yes`，此时若使用不带 `-A` 的命令如 `ssh userabc@10.10.10.12 -p 22`，则不会启用 ssh agent forwarding。
  - 因为 `~/.ssh/config` 对应 B 的 Host 块名称需精确匹配字符串 `serverB`，若不是 `ssh serverB`，则 `serverB` 中的 `ForwardAgent yes` 不会生效。


## 疑问：如何在 B 的其他命令窗复用 B 中曾转发过的 `SSH_AUTH_SOCK`？
答：个人不建议复用，重启起一个 Forward 登录好了。


## 疑问：即使没有 ssh、ssh-agent、ssh-add 工具，git 能用起 `SSH_AUTH_SOCK`？
答：可以的。


## 疑问：ssh-agent 加载私钥后，若将私钥文件删除，ssh agent 能否继续用？
答：可以的。

ssh agent 中的私钥估计是加载到内存了，即使原来的私钥文件被删除，ssh agent 也能继续用。举例来说，此时即使原来的私钥文件被删除，也能依然 git clone。





# TODO
- 如何不依靠 VSCode，将 A 的 ssh agent 转发到 B 内的 container 中？[跟踪问题](https://stackoverflow.com/questions/68450287/how-does-vscode-remote-containers-ssh-agent-forwarding-work)
  - VSCode 貌似不依赖 `/etc/ssh/sshd_config`
- 是否必须开启 B 的 `/etc/ssh/sshd_config` 的 `AllowAgentForward`？
  - 反思 VSCode 的行为


# 参考
- 文档：`man ssh-agent`
- 文档：`man ssh-add`
- [SSH Agent Explained](https://smallstep.com/blog/ssh-agent-explained/)

