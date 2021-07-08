<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [SSH 端口转发（SSH Tunneling 、Port Forwarding) 的理解](#ssh-%E7%AB%AF%E5%8F%A3%E8%BD%AC%E5%8F%91ssh-tunneling-port-forwarding-%E7%9A%84%E7%90%86%E8%A7%A3)
- [SSH Tunneling 就是 Port Forwarding（参考）](#ssh-tunneling-%E5%B0%B1%E6%98%AF-port-forwarding%E5%8F%82%E8%80%83)
- [SSH 端口转发主要的 3 种情况](#ssh-%E7%AB%AF%E5%8F%A3%E8%BD%AC%E5%8F%91%E4%B8%BB%E8%A6%81%E7%9A%84-3-%E7%A7%8D%E6%83%85%E5%86%B5)
- [实验假设](#%E5%AE%9E%E9%AA%8C%E5%81%87%E8%AE%BE)
- [端口转发实验](#%E7%AB%AF%E5%8F%A3%E8%BD%AC%E5%8F%91%E5%AE%9E%E9%AA%8C)
- [查看端口转发列表](#%E6%9F%A5%E7%9C%8B%E7%AB%AF%E5%8F%A3%E8%BD%AC%E5%8F%91%E5%88%97%E8%A1%A8)
- [停止指定的端口转发](#%E5%81%9C%E6%AD%A2%E6%8C%87%E5%AE%9A%E7%9A%84%E7%AB%AF%E5%8F%A3%E8%BD%AC%E5%8F%91)
- [辅助技巧](#%E8%BE%85%E5%8A%A9%E6%8A%80%E5%B7%A7)
- [参考](#%E5%8F%82%E8%80%83)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# SSH 端口转发（SSH Tunneling 、Port Forwarding) 的理解

# SSH Tunneling 就是 Port Forwarding（[参考](https://www.ssh.com/academy/ssh/tunneling/example)）
- SSH Tunneling 就是 Port Forwarding
- 中文可译作：SSH 隧道、SSH 端口转发
- 有时 SSH Tunneling 也被写成 SSH Tunnel

本文后面将简称为 `端口转发` 或 `SSH 端口转发`。



# SSH 端口转发主要的 3 种情况

- 本地转发（Local Forwarding）
- 动态转发（Dynamic Forwarding）
- 远程转发（Remote Forwarding）

大致原理可见下图：


![SSH Tunneling](https://raw.githubusercontent.com/vikyd/note-bigfile/master/img/ssh-forwarding.png)


# 实验假设
有 3 台机器：
- A：`10.10.10.11`
- B：`10.10.10.12`
- C：`10.10.10.13`

前提：
- A 上有 ssh 私钥（如 `id_rsa`）
- A 已可直接 ssh 到 B
- A 与 C 可能不能直接互相通讯（能访问也不影响实验）
- A 与 B 可直接通讯
- B 与 C 可直接通讯
- A 上已配置 `~/.ssh/config` 类似下面的块，以便后续命令更简单调用：
```config
Host hostB
  # 请更换为 C 机器上的真正用户名
  User userC
  HostName 10.10.10.12
  Port 22
  IdentityFile ~/.ssh/id_rsa
```



# 端口转发实验
有几个问题需注意：
- 是否顺便登录到对方机器
- 命令跑到后台或前台

命令示例（如无说明，均在 A 执行）：
```sh
# ---- 本地转发（Local Forwarding） ↓ ---------------------------
# ---- 常用方式：启动到后台 ----
# L: `本地转发` 模式
# f: 让 ssh 命令跑到后台（Requests ssh to go to background just before command execution）
# N: 只进行端口转发，不执行远程命令（Do not execute a remote command）
# T: 不分配终端
ssh -fNT -L localPort:targetIP:targetPort tunnelHost
ssh -fNT -L 4001:10.10.10.11:6001 userB@10.10.10.12 -p 22
# 若 ~/.ssh/config 已配置过 10.10.10.12 为某个名称如 `hostB`，则可以简写成：
ssh -fNT -L 4001:10.10.10.11:6001 hostB

# ---- 不常用：启动并登录到 B ----
ssh -L 4001:10.10.10.11:6001 hostB

# 验证：应能得到 C 的 6001 端口的响应
curl localhost:4001




# ---- 动态转发（Dynamic Forwarding） ↓ ---------------------------
# D: `动态转发` 模式
ssh -fNT -D localPort tunnelHost
ssh -fNT -D 4002 hostB

# 验证：应能得到 B（10.10.10.12） 的 5001 端口的响应
curl -x socks5://localhost:4002 10.10.10.12:6001
# 验证：应能得到 C（10.10.10.13） 的 6001 端口的响应
curl -x socks5://localhost:4002 10.10.10.13:6001
# 验证：应能得到 C（10.10.10.13） 的 6002 端口的响应
curl -x socks5://localhost:4002 10.10.10.13:6002




# ---- 远程转发（Remote Forwarding） ↓ ---------------------------
# R: 远程转发模式
ssh -fNT -R remotePort:targetHost:targetPort remoteHost
ssh -fNT -R 5002:localhost:4003 hostB

# 验证（在 C 执行下面命令）：应能得到 A（10.10.10.11） 的 4003 端口的响应
curl 10.10.10.12:5002
```



# 查看端口转发列表
> TODO



# 停止指定的端口转发
```sh
# ---- 方式 01 ：根据端口 kill 进程 ----
# 查看哪个进程占用了端口 4001
lsof -i -P -n | grep 4001
kill 4001

# 最粗暴的方式：kill 掉所有 ssh 进程
pkill ssh


# ---- 方式 02 ：进入 ssh prompt 操作
# 参考：https://superuser.com/questions/87014/how-do-i-remove-an-ssh-forwarded-port/1245530
# 此方式暂无试验成功
```


# 辅助技巧
Python 启动简易 HTTP 服务器：
```sh
# Python 2，端口：5001
python -m SimpleHTTPServer 5001


# Python 3，端口：6001
python3 -m http.server 6001
```

查看占用端口的进程：
```sh
# 查看哪个进程占用了端口 4001
lsof -i -P -n | grep 4001
```


# 参考
- 文档：`man ssh`
- [阮一峰：SSH 端口转发](https://wangdoc.com/ssh/port-forwarding.html)
- [StackOverflow 图示 SSH 端口转发与反向转发](https://unix.stackexchange.com/a/115906/207518)
- [ssh端口转发的三种方式](https://segmentfault.com/a/1190000020743065)
- [Running SSH port forwarding in the background](https://mpharrigan.com/2016/05/17/background-ssh.html)


