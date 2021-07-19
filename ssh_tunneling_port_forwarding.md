<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [SSH 端口转发（SSH Tunneling 、Port Forwarding) 的理解与实验](#ssh-%E7%AB%AF%E5%8F%A3%E8%BD%AC%E5%8F%91ssh-tunneling-port-forwarding-%E7%9A%84%E7%90%86%E8%A7%A3%E4%B8%8E%E5%AE%9E%E9%AA%8C)
- [SSH Tunneling 就是 Port Forwarding（参考）](#ssh-tunneling-%E5%B0%B1%E6%98%AF-port-forwarding%E5%8F%82%E8%80%83)
- [SSH 端口转发的 3 种主要类型](#ssh-%E7%AB%AF%E5%8F%A3%E8%BD%AC%E5%8F%91%E7%9A%84-3-%E7%A7%8D%E4%B8%BB%E8%A6%81%E7%B1%BB%E5%9E%8B)
- [实验假设](#%E5%AE%9E%E9%AA%8C%E5%81%87%E8%AE%BE)
- [端口转发实验](#%E7%AB%AF%E5%8F%A3%E8%BD%AC%E5%8F%91%E5%AE%9E%E9%AA%8C)
  - [本地转发（Local Forwarding）](#%E6%9C%AC%E5%9C%B0%E8%BD%AC%E5%8F%91local-forwarding)
  - [动态转发（Dynamic Forwarding）](#%E5%8A%A8%E6%80%81%E8%BD%AC%E5%8F%91dynamic-forwarding)
  - [远程转发（Remote Forwarding）](#%E8%BF%9C%E7%A8%8B%E8%BD%AC%E5%8F%91remote-forwarding)
  - [本地转发（转发到远程 host 的 container）](#%E6%9C%AC%E5%9C%B0%E8%BD%AC%E5%8F%91%E8%BD%AC%E5%8F%91%E5%88%B0%E8%BF%9C%E7%A8%8B-host-%E7%9A%84-container)
- [查看端口转发列表](#%E6%9F%A5%E7%9C%8B%E7%AB%AF%E5%8F%A3%E8%BD%AC%E5%8F%91%E5%88%97%E8%A1%A8)
- [停止指定的端口转发](#%E5%81%9C%E6%AD%A2%E6%8C%87%E5%AE%9A%E7%9A%84%E7%AB%AF%E5%8F%A3%E8%BD%AC%E5%8F%91)
- [编程语言启动 ssh 端口转发](#%E7%BC%96%E7%A8%8B%E8%AF%AD%E8%A8%80%E5%90%AF%E5%8A%A8-ssh-%E7%AB%AF%E5%8F%A3%E8%BD%AC%E5%8F%91)
- [辅助技巧](#%E8%BE%85%E5%8A%A9%E6%8A%80%E5%B7%A7)
- [参考](#%E5%8F%82%E8%80%83)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# SSH 端口转发（SSH Tunneling 、Port Forwarding) 的理解与实验
[TOC]



# SSH Tunneling 就是 Port Forwarding（[参考](https://www.ssh.com/academy/ssh/tunneling/example)）
- SSH Tunneling 就是 Port Forwarding
- 中文可译作：SSH 隧道、SSH 端口转发
- 有时 SSH Tunneling 也被写成 SSH Tunnel

> 后面将简称 `端口转发` 或 `SSH 端口转发`

典型用途：将本地端口转发到远程端口。

例如，将本地端口 8000 转发到远程 9000 端口，即可实现访问本地 http://localhost:8000 相当于访问远程的 http://10.10.10.11:9000 的服务。这在远程 IP 端口不能直接访问时特别有用。



# SSH 端口转发的 3 种主要类型
3 种情况：
- 本地转发（Local Forwarding）
  - 大致作用：转发本地端口到远程固定端口
- 动态转发（Dynamic Forwarding）
  - 大致作用：转发本地端口到远程任意端口
- 远程转发（Remote Forwarding）
  - 大致作用：转发远程端口到本地端口

大致原理可见下图：


![SSH Tunneling](https://raw.githubusercontent.com/vikyd/note-bigfile/master/img/ssh-port-forwarding.png)



# 实验假设
假设有 3 个机器：
- A：`10.10.10.11`
- B：`10.10.10.12`
- C：`10.10.10.13`

假设：
- A 与 B 可通讯
- B 与 C 可通讯
- A 与 C 不能通讯（能通讯也不影响实验）

```
A ---✓---> B ---✓---> C

A ---------x--------- C
```
- A 有 ssh 私钥（如 `~/.ssh/id_rsa`），可 ssh 登录 C
- A 已配置 `~/.ssh/config`（后续用到）：
```config
Host hostB
  # 请更换为 C 机器上的真正用户名
  User userC
  HostName 10.10.10.12
  Port 22
  IdentityFile ~/.ssh/id_rsa
```



# 端口转发实验
注意：只有 `-L` 参数时，默认会顺便登录到对方机器，所以一般会增加 `-fNT` 参数


## 本地转发（Local Forwarding）
在 A 执行，启动端口转发：
> 解释：在 A 启动转发，将 A 的指定端口 4001，经过 B ，转发给 C 的指定端口 6001

> 可选：当然也可无需 C：在 A 启动转发，将 A 的指定端口，经过 B ，转发给 B 的指定端口（自行修改本实验 C 的 IP端口 为 B 的 IP端口）

```sh
# ---- 常用方式：启动到后台 ----
# L: `本地转发` 模式
# f: 让 ssh 命令跑到后台（Requests ssh to go to background just before command execution）
# N: 只进行端口转发，不执行远程命令（Do not execute a remote command）
# T: 不分配终端
# 模式：ssh -fNT -L localPort:targetIP:targetPort tunnelHost
ssh -fNT -L 4001:10.10.10.13:6001 userB@10.10.10.12 -p 22
# 或：若 ~/.ssh/config 已配置过 10.10.10.12 为某个名称如 `hostB`，则可以简写成：
ssh -fNT -L 4001:10.10.10.13:6001 hostB

# ---- 不常用：启动并登录到 B ----
# ssh -L 4001:10.10.10.13:6001 hostB
```

在 C 执行，启动简单 HTTP 服务：
```sh
# 在 C 启动一个简单 HTTP 服务，监听 6001 端口
python2 -m SimpleHTTPServer 6001
```

在 A 执行，验证结果：
```sh
# 验证：应能得到 C（即 10.10.10.13:6001）的响应
curl localhost:4001
```



## 动态转发（Dynamic Forwarding）
在 A 执行，启动动态转发：
> 解释：在 A 启动转发，将 A 的指定端口，经过 B，转发到 B 可访问的任意端口

```sh
# D: `动态转发` 模式
# 模式：ssh -fNT -D localPort tunnelHost
ssh -fNT -D 4002 userB@10.10.10.12 -p 22
# 或
ssh -fNT -D 4002 hostB
```

在 B 执行，启动简单 HTTP 服务：
```sh
# 在 B 启动一个简单 HTTP 服务，监听 5001 端口
python2 -m SimpleHTTPServer 5001
```

在 C 执行，启动简单 HTTP 服务：
```sh
# 在 C 启动一个简单 HTTP 服务，监听 6001 端口
python2 -m SimpleHTTPServer 6001
# 在 C 启动一个简单 HTTP 服务，监听 6002 端口
python2 -m SimpleHTTPServer 6002
```

在 A 执行，验证结果：
```sh
# 验证：应能得到 B（10.10.10.12:5001）的响应
curl -x socks5://localhost:4002 10.10.10.12:5001
# 验证：应能得到 C（10.10.10.13:6001）的响应
curl -x socks5://localhost:4002 10.10.10.13:6001
# 验证：应能得到 C（10.10.10.13:6002）的响应
curl -x socks5://localhost:4002 10.10.10.13:6002
```



## 远程转发（Remote Forwarding）
在 A 执行，启动远程转发：
> 解释：在 A 启动转发，使得 B 将任何对 B 的指定端口的访问，转发到 A 的指定端口

```sh
# R: 远程转发模式
# 模式：ssh -fNT -R remotePort:targetHost:targetPort remoteHost
ssh -fNT -R 5002:localhost:4003 userB@10.10.10.12 -p 22
# 或
ssh -fNT -R 5002:localhost:4003 hostB
```

在 A 执行，启动简单 HTTP 服务：
```sh
python2 -m SimpleHTTPServer 4003
```

在 C 执行，验证结果：
```sh
# 验证：应能得到 A（10.10.10.11:4003）的响应
# 在 C 执行 curl 请求到 B 的 5002 端口，最终得到了 A 的 4003 端口的响应
curl 10.10.10.12:5002
```
> 只要能访问到 10.10.10.12:5002 的都可以验证，例如，也可就在 B 本地访问 localhost:5002



## 本地转发（转发到远程 host 的 container）
在 B 执行（假设 B 已安装 Docker），启动一个 container：
```sh
# 启动 container
docker run -it python bash
```

在刚启动的 container 内查看 IP：
```sh
ip a|grep inet
# 假设得到 eth0 的 IP 为 172.17.0.4
```

在 container 内启动一个简单 HTTP 服务：
```sh
# 在 C 启动一个简单 HTTP 服务，监听 6003 端口
python2 -m SimpleHTTPServer 6003
```

在 A 执行，启动端口转发：
> 解释：在 A 启动转发，将 A 的指定端口 4004，经过 B ，转发给 B 的 Docker 启动的 container 内的端口 6003

```sh
# 模式：ssh -fNT -L localPort:targetIP:targetPort tunnelHost
ssh -fNT -L 4004:172.17.0.4:6003 hostB
```


在 A 执行，验证结果：
```sh
# 验证：应能得到 B 容器内的响应（即 172.17.0.4:6003）的响应
curl localhost:4004
```

知识点：
- container 无需暴露端口，B host 可直接通过 `container IP` 访问 container 的任意端口
- `targetIP:targetPort` 是相对 B 来说的，而非相对 A

所以，猜测，VSCode 也是基于类似的机制将 container 内的端口转发到 local，而无需 container 绑定端口到其 host。



# 查看端口转发列表
> TODO，暂未找到快捷、精确的方式能列出所有 ssh 或非 ssh 进程启动的端口转发

在本地，查看由 ssh 进程列表（不一定是端口转发进程，且不会列出端口占用）：
```sh
lsof -i -n | egrep 'ssh'
```

在本地，根据本地端口，查看占用该端口（如 4001 端口）的进程：
```sh
lsof -i -P -n | grep 4001
```



# 停止指定的端口转发
在本地执行：
```sh
# ---- 方式 01 ：根据端口 kill 进程 ----
# 查看哪个进程占用了端口 4001
lsof -i -P -n | grep 4001
kill 查出来的PID

# 最粗暴的方式：kill 掉所有 ssh 进程
# 会 kill 掉：ssh 登录、ssh 端口转发进程
# 但不会 kill 掉非 ssh 进程启动的端口转发
pkill ssh
```


# 编程语言启动 ssh 端口转发
启动 ssh 端口转发，不一定必须 ssh 命令，也可以通过编程语言实现（只需遵循相关协议）：
- [Golang 启动 SSH 端口转发 - Hello World](https://github.com/vikyd/go-ssh-port-forwarding-example)
- [Nodejs 启动 SSH 端口转发 - Hello World](https://github.com/vikyd/nodejs-ssh-port-forwarding-example)



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
# 查看哪个进程占用了端口 5001
lsof -i -P -n | grep 5001
```



# 参考
- 文档：`man ssh`
- [阮一峰：SSH 端口转发](https://wangdoc.com/ssh/port-forwarding.html)
- [StackOverflow 图示 SSH 端口转发与反向转发](https://unix.stackexchange.com/a/115906/207518)
- [ssh端口转发的三种方式](https://segmentfault.com/a/1190000020743065)
- [Running SSH port forwarding in the background](https://mpharrigan.com/2016/05/17/background-ssh.html)


