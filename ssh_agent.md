# SSH Agent Forwarding 的理解与配置
SSH Agent Forwarding 的基本作用可网上搜索，这里不再描述，只说些踩过的坑。



# 实验环境
- OS：Mac
- Server：CentOS



# 原理
3 台机器：
- A：`10.10.10.11` 本机（Mac 或 Win）
- B：`10.10.10.12` Linux 服务器
- C：`10.10.10.13` 另一台 Linux 服务器

前提：
- A 上有 ssh 私钥（如 `id_rsa`）
- A 已可直接 ssh 到 B
- A 已可直接 ssh 到 C
- B 本身不能 ssh 到 C（无 C 信任的私钥）


SSH Agent Forwarding **指的是**：A ssh 到 B 后，再从 B ssh 到 C 时，B 能自动利用 A 的 ssh agent 的信息来 ssh 到 C。（而不是指单纯的 B ssh 到 C，因为需先从 A ssh 到 B））


# 配置
先做以下配置，再继续后面的 `步骤`。
## A 的配置
- 启动 ssh agent，并加载所需的 ssh 私钥：
```sh
# 查看 ssh agent 是否已启动或是否已加载 ssh 私钥（非必须）
# 若未启动会提示  ：`Could not open a connection to your authentication agent.`
# 若已启动但无 key：`The agent has no identities.`
# 若已启动且有 key：`2048 SHA256:一长串字符串 email地址 (RSA)`
ssh-add -l

# 启动 ssh agent 到后台
eval "$(ssh-agent -s)"

# 加载所需的 ssh 私钥（按需修改为你的私钥位置）
ssh-add ~/.ssh/id_rsa

# 可再次确认加载的 key（非必须）
ssh-add -l


# ---- ↓ 下面命令仅供参考，没问题时无需执行 ↓ -----
# 停止 ssh agent
# https://stackoverflow.com/a/56284336/2752670
# 先找到 ssh-agent 的进程
ps x | grep ssh-agent
# 再 kill 找到的 pid
kill pid
# 若想停止全部 ssh agent 实例
pkill ssh-agent
```
- `~/.ssh/config`


## B 的配置
- `/etc/ssh/sshd_config` 里的 `AllowAgentForwarding` 设置为：`yes`
- 然后重启 sshd：`systemctl restart  sshd.service`

> 题外话：对于 VSCode remote host 的 container 内无需此配置 ↑


## C 的配置
C 无需配置。



# 实验
分两个步骤：
- 步骤 01 ：从 A ssh 到 B
- 步骤 02 ：在步骤 01 基础上继续从 B ssh 到 C

## 步骤 01 ：从 A ssh 到 B
从 A ssh 到 B 时，需在 A 中配置启用 ssh agent forwarding。

有两种方式（二选一）：
- 一种是 ssh 命令中增加 `-A` 参数
- 一种是修改 A 的 `~/.ssh/config` 对应 B 的 Host 块中里增加 `ForwardAgent yes`。

### 方式 01 ：ssh 命令中增加 `-A` 参数
```sh
# 从 A（10.10.10.11） ssh 到 B（10.10.10.12）
# `-A`：
#   - Enables forwarding of the authentication agent connection.  
#   - This can also be specified on a per-host basis in a configuration file.
# `-A`：表示启用 ssh agent forwarding
ssh -A userabc@10.10.10.12 -p 22
```

### 方式 02 ：修改 A  `~/.ssh/config` 对应 B 的 Host 块
```config
Host serverB
  User userabc
  HostName 10.10.10.12
  Port 22
  IdentityFile ~/.ssh/id_rsa
  # ↓ 增加下面这行
  ForwardAgent yes
```

此时 ssh 命令应为（就是下面精确字符串）：
```sh
ssh serverB
```

### 步骤 01 小结
- 方式 01 和 方式 02 二选一即可。
- 注意：即使已配置 `~/.ssh/config` 对应 B 的 Host 块增加 `ForwardAgent yes`，若此时使用不带 `-A` 的命令如 `ssh userabc@10.10.10.12 -p 22`，则不会启用 ssh agent forwarding。
  - 因为 `~/.ssh/config` 对应 B 的 Host 块名称需精确匹配字符串 `serverB`，若不是 `ssh serverB`，则 `serverB` 中的 `ForwardAgent yes` 不会生效。
- 技巧：此时在 B 执行 `ssh-add -l` 查看 A 中 ssh agent 已加载的 key 列表
  - 此时若在 A 中清空已加载的 key：`ssh-add -D`，再回来 B 执行 `ssh-add -l` 已看不到曾出现的 key
  - 此时若在 A 重新加载 key：`ssh-add ~/.ssh/id_rsa`，再回来 B 执行 `ssh-add -l` 又能看到 key 了


## 步骤 02 ：继续从 B ssh 到 C
在上一步得到 B 命令行中，执行下面命令即可从 B ssh 到 C ：
```sh
ssh userdef@10.10.10.13 -p 22
```

注意：
- B 此时是没有 C 的 ssh 私钥的，原理是：C 向 B 询问私钥相关验证信息时，B 再去问 A 拿到对应信息，再返回给 C（不是私钥本身） ，C 即可让 B ssh 到 C。
- B ssh 到 C 的命令可无需 ssh agent forwarding 参数



# 其他：踩坑列表
- ssh agent 可以有多个实例，但：
  - 实例之间不共享加载的 key
  - 各实例的 `SSH_AGENT_PID`、`SSH_AUTH_SOCK` 等环境变量不同
  - 当前命令行窗口生效的通常是最后启动的 ssh-agent 实例
  - 跨命令窗 **默认** 不共享 ssh agent，实验：
    - 在命令窗 a 启动 ssh agent（`eval "$(ssh-agent -s)"`），并加载 key（`ssh-add ~/.ssh/id_rsa`），此时在 a 执行 `ssh-add -l` 能看到加载的列表
    - 此时再开命令窗 b，在 b 执行 `ssh-add -l` 看不到 a 的 key 列表
    - 若需在 b 使用 a 的 ssh agent 实例，则需：
      - 在 a 找到 `SSH_AUTH_SOCK`：`echo $SSH_AUTH_SOCK`，假设得到输出为 str1
      - 在 b 执行 `export SSH_AUTH_SOCK=str1`（注意 `str1` 应替换为上一步得到的输出结果）
      - 此时 b 已共享了 a 的 ssh agent，在 b 执行 `ssh-add -l` 应能看得 a 加载过的 key
- 多次启动 ssh agent 会得到不同实例，如多次执行 `eval "$(ssh-agent -s)"` 就会得到不同的实例（pid 不一样）
  - 也可通过 `ps x | grep ssh-agent` 查看当前的 ssh agent 实例进程列表
- 对于 VSCode 打开 remote host 的 container 时，若需在远程的 container 也能复用本机 ssh agent，则需（以 Mac 为例）（二选一）：
  - 方式 01 ：VSCode 貌似是能自动识别 Mac 默认启动的 ssh agent，此时 Mac 默认启动的 ssh agent 加载 key 了，则 VSCode 能感知到
  - 方式 02 ：Mac 默认的 ssh agent 曾被 kill 掉，则需在命令行启动新的 ssh agent，加载 key，并从此命令行启动 VSCode：`code targetDir` 或单纯 `code` 命令不指定目录
  - 说明：
    - Mac 默认会启动 ssh agent，但不会默认加载 key
    - Mac 默认启动的 ssh agent 的 `SSH_AUTH_SOCK` 值形似：`/private/tmp/com.apple.launchd.CBa7idWY89/Listeners`
    - 手动启动的 ssh agent 的 `SSH_AUTH_SOCK` 形似：`/var/folders/0t/yzb0gynd37q_6tkyj87td4h80000gn/T//ssh-UFsZ80NlGoXz/agent.4935`
    - 如果你没手动启动过 ssh agent，则可直接加载 key：`ssh-add ~/.ssh/id_rsa` 到默认 ssh agent，此时 VSCode 已能复用此默认的 ssh agent
    - 如果你当前命令行启动过新的 ssh agent，则需新开一个命令窗，新的命令窗得到的是默认的 ssh agent，在新命令窗中执行 `ssh-add ~/.ssh/id_rsa` 即可加载 key 到默认 ssh agent
    - 如果你已把 Mac 默认启动的 ssh agent kill 掉（如 `pkill ssh-agent`），则可能只能在当前命令行启动新的 ssh agent `eval "$(ssh-agent -s)"`，加载 key `ssh-add ~/.ssh/id_rsa`，然后退出 VSCode 通过类似 `code targetDir` 或单纯 `code` 命令启动 VSCode，此时的 VSCode 会承认当前命令新启动的 ssh agent



# 疑问 TODO
- `SSH_AGENT_PID`、`SSH_AGENT_SOCK`、`SSH_AUTH_SOCK` 的区别？
- VSCode 具体是如何将 Mac 的 ssh agent forward 到 remote host 的 container 的？（且此时 container 没有配置 `/etc/ssh/sshd_config`）




# 参考
- `man ssh-agent`
- `man ssh-add`

