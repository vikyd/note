# 原来 ifconfig 的字段是这样的含义

# 目录

<!-- START doctoc -->
<!-- END doctoc -->

# ifconfig 里的疑问

每次看 `ifconfig` 输出信息都似懂非懂。

- 每个字段英文全称是什么？
- 数字对应的单位是什么？
- 数字分别对应哪个网络分层？
- 数字从何计算而来？
- 为什么有些数字貌似常量？
- 枚举值的全部列表是什么？
- 等等

本文尝试回答上述问题。

这里主要讨论 Linux 的 `ifconfig`，而非 Mac 的 `ifconfig`。

> 若有错漏，请指正，本文会持续更新。

# ifconfig 输出示例

服务员，先上示例。

## Linux 示例

> 后面字段说明均以此输出作为示例

```
➜  ~ ifconfig
eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.10.10.11  netmask 255.255.240.0  broadcast 10.10.10.255
        inet6 fe80::4001:aff:feaa:3  prefixlen 64  scopeid 0x20<link>
        ether 42:01:0a:aa:00:03  txqueuelen 1000  (Ethernet)
        RX packets 69426519  bytes 20960261647 (19.5 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 73886979  bytes 15013465511 (13.9 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

... 其他网卡
```

## Mac 示例

> 后面 Mac 字段说明均以此输出作为示例

```
➜  ~ ifconfig
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=400<CHANNEL_IO>
	ether ac:bc:32:8f:f0:e1
	inet6 fe80::db:1ff8:6292:fb96%en0 prefixlen 64 secured scopeid 0x4
	inet 192.168.0.101 netmask 0xffffff00 broadcast 192.168.0.255
	nd6 options=201<PERFORMNUD,DAD>
	media: autoselect
	status: active

... 其他网卡
```

## 区别

Linux 与 Mac 的 `ifconfig` 输出很不一样，如 Mac 通常不会输出 `RX`、`TX` 的值，且会输出些其他字段值；`flags` 值的计算貌似也不一样。

这与 Mac 系统内核来源于 [BSD 系统](https://en.wikipedia.org/wiki/Berkeley_Software_Distribution) 有关。

# 过时的 ifconfig

`ifconfig` 已是相对过时的工具，参考其文档 [`man ifconfig`](https://linux.die.net/man/8/ifconfig)：

```
This program is obsolete!
For replacement check ip addr and ip link.
```

建议用 `ip` 命令（如 `ip addr`、`ip link`）替代 `ifconfig`。

虽然过时，但估计依然不少人在使用这个旧工具。

# ifconfig 用途

`ifconfig` 命令用于 `查看` 或 `设置` 网络设备（常见为 `网卡`）。

> [ifconfig - configure a network interface](https://linux.die.net/man/8/ifconfig)

本文主要讨论 `ifconfig`（即不带任何参数） 输出信息，不讨论如何修改网络配置。

# ifconfig 源码

Linux 的 `ifconfig` 属于 [net-tools](https://github.com/giftnuss/net-tools) 的一部分。

# `man ifconfig` 不香吗？

`man ifconfig` 文档主要介绍如何修改网络配置，并未介绍 `ifconfig` 输出各字段的信息。

所以，`man ifconfig` 还不够香。

# ifconfig 全称

可通过 `man ifconfig` 命令查看全称：

- Linux `ifconfig`：`configure a network interface`
- Mac `ifconfig`：`configure network interface parameters`

所以 `if` 应是 `InterFace` 的缩写。

# ifconfig 与 ipconfig 区别

- `ifconfig`：是 Linux、Mac 等类 Unix 家族的命令
- `ipconfig`：是 Windows 的命令
  - 全称：[Internet Protocol configuration](https://en.wikipedia.org/wiki/Ipconfig)

参考：[Difference between ifconfig and ipconfig? ](https://unix.stackexchange.com/a/39502/207518)

# 网络分层模型

## 表格、图示

在理解 `ifconfig` 输出的每个字段前，建议回顾下网络分层模型。

参考：[阮一峰 - 互联网协议入门](http://www.ruanyifeng.com/blog/2012/05/internet_protocol_suite_part_i.html)

| 实际大致五层模型     | 功能                           | TCP/IP 协议族                | Protocol Data Unit 协议数据单位（[参考](https://stackoverflow.com/a/31464376/2752670)） |
| -------------------- | ------------------------------ | ---------------------------- | --------------------------------------------------------------------------------------- |
| 5 应用层 Application | 各式应用服务                   | HTTP，FTP，SMTP，DNS，Telnet | -                                                                                       |
| 4 传输层 Transport   | 提供端对端的接口               | TCP，UDP                     | Segment（段）（也有称为 [Message](https://tools.ietf.org/html/rfc1122#page-17)）        |
| 3 网络层 Network     | 为数据包选择路由               | IP，ICMP，IGMP               | Packet（包）                                                                            |
| 2 链路层 Data Link   | 传输有地址的帧以及错误检测功能 | Ethernet（以太网），PPP，ARP | Frame（帧）                                                                             |
| 1 物理层 Phsical     | 二进制数据形式在物理上传输数据 | ISO2110，IEEE802，IEEE802.2  | Bit（比特）                                                                             |

> [表格部分参考](https://developer.aliyun.com/article/222535)

![网络分层](https://i.stack.imgur.com/Zknbj.png)

> [图片来源](https://stackoverflow.com/a/62208683/2752670)

参考：

- [可互动操作的协议地图](http://www.023wg.com/message/message/cd_feature_cover.html)
- 标准 I 描述的分层模型 - [RFC 1122 - Internet Protocol Suite](https://tools.ietf.org/html/rfc1122)
- [你学习的 TCP/IP 协议栈到底是几层？教科书上的标准答案都在变](https://network.51cto.com/art/201910/604277.htm)

## 每层的单位（unit）

> 下面单位可能会因具体实现而有差别

- Segment（段）：属第 4 层传输层，如 [TCP 的 Segment](https://en.wikipedia.org/wiki/Transmission_Control_Protocol#TCP_segment_structure)、[UDP 的 datagram](https://en.wikipedia.org/wiki/User_Datagram_Protocol#UDP_datagram_structure)
- Packet（包）：属第 3 层网络层，如 [IP 的包](https://en.wikipedia.org/wiki/IPv4#Packet_structure)
- Frame（帧）：属第 2 层数据链路层，如 [以太网 Ethernet 的帧](https://en.wikipedia.org/wiki/Ethernet_frame)
- Bit（比特）：属第 1 层物理层，就是原始的二进制信号传播。（[物理层包括如：电气特性电压、机械特性网线水晶头等](https://www.cnblogs.com/zhangyinhua/p/7607633.html)）

上述单位就像洋葱被逐步包裹（见上图），越往底层，Header 越多。下一层的 payload（负载）就是上一层的 Header + Payload。分层概念本身不难理解，难的可能是实际应用时搞清楚各数据对应哪一层。

![](https://i.stack.imgur.com/6dKkj.gif)

> [图片来源](https://networkengineering.stackexchange.com/a/50098)

# ifconfig 各字段：简述

先简述，后详述。

本小节按 `ifconfig` 输出信息自上而下的顺序逐一列举每个字段的全称、含义。

> 不同 Linux 的 ifconfig 字段可能有差别，本文以 CentOS 为例

## 字段：`eth1`

含义：网卡名，常见的网卡名：`eth1`、`lo`、`docker0`、`en0`、`veth20782fd`、`br-e06065d96cd9` 等，这里 `eth1` 通常是一个物理网卡

详细：见后面 [常见网卡命名](#常见网卡名) 小节

## 字段：`flags`

- 示例：`flags=4163<UP,BROADCAST,RUNNING,MULTICAST>`
- 含义：表示当前网卡的状态（此列表并非可操作的命令）
- 详细：`4163` 从何而来？`UP,BROADCAST` 等还可能有哪些值？见后面 [flags](#flags) 小节

## 字段：`mtu`

- 示例：`mtu 1500`
- 全称：
  - Linux 文档中称为：[Maximum Transfer Unit](https://www.kernel.org/doc/html/latest/networking/netdevices.html#mtu)
  - 维基百科中称为：[Maximum Transmission Unit](https://en.wikipedia.org/wiki/Maximum_transmission_unit)
- 含义：最大传输单元；指链路层（第 2 层）的 frame 的 payload（负载）的最大大小；[Linux 中 MTU 对发送和接收都起作用](https://www.kernel.org/doc/html/latest/networking/netdevices.html#mtu)
- 单位：Byte
- 详细：为什么 mtu 通常是 1500？见后面 [mtu](#mtu) 小节

## 字段：`inet`

- 示例：`inet 10.10.10.11 netmask 255.255.240.0 broadcast 10.10.10.255` 中的 `10.10.10.11`
- 全称：[Internet](https://unix.stackexchange.com/questions/545462/what-does-inet-stand-for-in-the-ip-utility/545467#545467)
- 含义：TCP/IP 的 IPv4 地址（IPv6 的字段为 `inet6`）
- 理解：互联网基于 TCP/IP 协议族（[protocol family](https://unix.stackexchange.com/a/545467/207518)），所以通常 `inet` 指 IP 地址
- 类型：除了 `inet` ，还可能会有：[`inet6`、`ax25`、`ddp`、`ipx`、`netrom`](https://www.man7.org/linux/man-pages/man8/ifconfig.8.html#Address_Families) 等类型
- 字段：`netmask`
  - 示例：`netmask 255.255.240.0`
  - 全称：`IP network mask`
  - 中文：子网掩码
- 字段：`broadcast`
  - 示例：`broadcast 10.10.10.255`
  - 全称：`IP broadcast address`
  - 中文：广播地址

## 字段：`inet6`

- 示例：`inet6 fe80::4001:aff:feaa:3 prefixlen 64 scopeid 0x20<link>` 中的 `fe80::4001:aff:feaa:3`
- 全称：类似前面 `inet`
- 含义：TCP/IP 的 IPv6 地址
- 字段：`prefixlen`
  - 示例：`prefixlen 64`
  - 全称：`prefix length`
  - 含义：表示此地址的前 64 位是网络前缀，[作用类似于 IPv4 的子网掩码](https://www.omnisecu.com/tcpip/ipv6/what-is-prefix-in-ipv6.php)
- 字段：`scopeid`
  - 示例：`scopeid 0x20<link>`
  - 全称：`scope id`
  - 含义：`0x20<link>` 表示 [IPv6 的 Link-Local 类型地址](https://packetlife.net/blog/2011/apr/28/ipv6-link-local-addresses/)
  - 详细：见后面 [inet6](#inet6) 小节

## 字段：`ether`

- 示例：`ether 42:01:0a:aa:00:03`
- 全称：[Ethernet](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/lib/ether.c#L2)
- 中文：以太网
- 含义：表示网卡的 [MAC 地址](https://zh.wikipedia.org/wiki/MAC%E5%9C%B0%E5%9D%80)
- 理解：[对应第 2 层链路层的 Ethernet 协议](https://superuser.com/a/623558/724539)

## 字段：`txqueuelen`

- 示例：`txqueuelen 1000`
- 全称：[transmit queue length](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/include/interface.h#L37)
- 理解：发送数据时 [qdisc（Queuing Disciplines）队列](https://www.coverfire.com/articles/queueing-in-the-linux-network-stack/) 的大小
- 单位：[sk_buff（socket buffer）](http://vger.kernel.org/~davem/skb.html)
- 详细：`txqueuelen` 是一个比较长的话题，见后面 [txqueuelen](#txqueuelen) 小节

## 字段：`RX` 与 `TX`

示例：

```
RX packets 69426519  bytes 20960261647 (19.5 GiB)
RX errors 0  dropped 0  overruns 0  frame 0
TX packets 73886979  bytes 15013465511 (13.9 GiB)
TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

这两个大字段数据主要 [来源于](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/iptunnel.c#L473-L522) `/proc/net/dev`（查看：`cat /proc/net/dev`）

参考：Linux 输出 `/proc/net/dev` 的 [源码](https://github.com/torvalds/linux/blob/v5.8/net/core/net-procfs.c#L102-L117)

## 字段：`RX`

- 示例：
  ```
  RX packets 69426519  bytes 20960261647 (19.5 GiB)
  RX errors 0  dropped 0  overruns 0  frame 0
  ```
- 全称：[`Received`](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/include/interface.h#L2)
- 含义：网卡接收数据的统计
- 字段：
  - `packets 69426519`：成功接收到的数据包数量
    - 单位：[sk_buff](http://vger.kernel.org/~davem/skb.html)（与第 2 层链路层的 `frame` 的数量相等）
    - 注意：这不是第 3 层网络层的单位 `packet`
  - `bytes 20960261647 (19.5 GiB)`：数据 + 各层 header 的字节数量
    - 换算：CentOS 貌似常按 1024 换算成 `GiB`，Ubuntu 貌似常按 1000 换算成 `GB`，参考 [`man 7 units`](https://man7.org/linux/man-pages/man7/units.7.html)
  - `errors`：出错的包数量
    - 单位：[sk_buff](http://vger.kernel.org/~davem/skb.html)
    - 注意：此数值不等于后面 `dropped`、`overruns`、`frame` 字段的总和，原因见后面 [RX 和 TX](#rx和tx) 小节
  - `dropped`：Linux 内核对应的 sk_buff 满了导致的丢包
    - 单位：[sk_buff](http://vger.kernel.org/~davem/skb.html)
    - 可能原因之一：Linux 系统内存不足，[导致从网卡拷贝数据到系统内存时丢包](https://plantegg.github.io/2019/05/08/%E5%B0%B1%E6%98%AF%E8%A6%81%E4%BD%A0%E6%87%82%E7%BD%91%E7%BB%9C--%E7%BD%91%E7%BB%9C%E5%8C%85%E7%9A%84%E6%B5%81%E8%BD%AC/#ifconfig-%E7%9B%91%E6%8E%A7%E6%8C%87%E6%A0%87)
  - `overruns`：Linux 内核对应的 Ring Buffer 满了导致的丢包
    - 单位：[sk_buff](http://vger.kernel.org/~davem/skb.html)
    - 可能原因之一：CPU 很忙无法及时处理网卡申请的中断
    - 对应 Linux Kernel 的 [rx_fifo_errors](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/lib/interface.c#L915-L917)
    - 注意：详细见后面 [dropped 与 overruns 的区别](#dropped与overruns的区别) 小节
  - `frame`：指第 2 层链路层的 `frame` 的 bit 数不能 [被 8 整除](https://www.veritas.com/support/en_US/article.100004082)，不符合帧的定义，的错误
    - 单位：[sk_buff](http://vger.kernel.org/~davem/skb.html)
    - 可能原因之一：网卡、交换机等硬件故障导致
    - 参考：[`include/uapi/linux/if_link.h`](https://github.com/torvalds/linux/blob/v5.8/include/uapi/linux/if_link.h#L25)：`__u32 rx_frame_errors; /* recv'd frame alignment error */`
    - 参考：[What's the difference between “errors:” “dropped:” “overruns:” and “frame:” fields in ifconfig RX packets output?](https://unix.stackexchange.com/a/184675/207518)
- 详细：见后面 [RX 和 TX](#rx和tx) 小节

## 字段：`TX`

- 示例：

```
TX packets 73886979  bytes 15013465511 (13.9 GiB)
TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

- 全称：[`Transmitted`](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/include/interface.h#L3)
- 含义：网卡发送数据的统计
- 字段：
  - 与 `RX` 同名的字段：略过
  - `errors`：与前面 `RX` 的 `errors` 包含的错误类型有些不一样
  - `carrier`：硬件调制信号（[modulation of signal](https://serverfault.com/a/325801)）导致的出错包数量
    - 参考：[CSMA/CD](https://zhuanlan.zhihu.com/p/20731045)
  - `collisions`：冲突的包数量

# Linux 收发网络数据大致流程

更详细介绍 `ifconfig` 各字段前，建议先了解 Linux 收发网络数据的大致流程。

## 名词解释

> 以下名词解释均指 Linux 环境下的含义

- NIC
  - 全称：[Network Interface Controller](https://en.wikipedia.org/wiki/Network_interface_controller)
  - 含义：指网卡硬件本身
- NIC Driver
  - 含义：Driver 即驱动的意思，指 Linux 网卡驱动程序，运行在 Linux 内，而非运行在网卡硬件中
- FIFO
  - 全称：First In First Out
  - 含义：指先进先出的队列
- DMA
  - 全称：Direct Memory Access
  - 含义：直接内存访问。譬如网卡硬件的内存可以复制到主机的内存，而无需经过主机 CPU 处理
- 阮一峰：[Linux Kernel Space 与 User Space](http://www.ruanyifeng.com/blog/2016/12/user_space_vs_kernel_space.html)

## 接收数据流程

硬件角度：

```
外部网络 -> 网卡硬件 -> Linux 主机（CPU、内存）
```

软件角度：

```
外部网络
-> 网卡
-> Linux 内存的 [Ring Buffer 队列] 和 [Socket Buffer 区域]
-> 上层协议栈 -> User Space
```

软件角度的解疑：

> 具体流程可见下面各图的来源文章，这里只说之前疑惑的地方

- Ring Buffer 是一个 FIFO 队列，不存包数据，存指向数据的位置信息
- Socket Buffer 是实际存储包数据的地方
- Ring Buffer 和 Socket Buffer 都属于 Linux 的内存

![](https://i.stack.imgur.com/HignO.png)

> [↑ 接收数据时：Linux 网络 Ring Buffer、Socket Buffer 与网卡（NIC）的关系](https://stackoverflow.com/a/59491902/2752670)

## 发送数据流程

硬件角度：

```
Linux 主机（CPU、内存）-> 网卡硬件 -> 外部网络
```

软件角度：

```
User Space
-> 上层协议栈
-> qdisc 队列规则
-> Linux 内存的 [Ring Buffer 队列] 和 [Socket Buffer 区域]
-> 网卡
-> 外部网络
```

软件角度的解疑：

> 具体流程可见各图的来源文章，这里只说曾疑惑的地方

- 发送数据的流程大致就是接收数据流程的反转
- 不同主要在于发送的流程多了一个 qdisc（为了控制网络流量）

![](http://www.linuxjournal.com/files/linuxjournal.com/ufiles/imagecache/large-550px-centered/u1002061/11476f2.jpg)

> [↑ 发送数据时：Queueing Disciplines（Qdisc） 与 Driver Queue（Ring Buffer）与 SKB（Socket Buffer 或 sk_buff）与 NIC（网卡）的关系](https://www.linuxjournal.com/content/queueing-linux-network-stack)

## sk_buff

- 又称：SKB、Socket Buffer
- 全称：[Socket Buffer](http://vger.kernel.org/~davem/skb.html)
- 定义：[`include/linux/skbuff.h`](https://github.com/torvalds/linux/blob/v5.8/include/linux/skbuff.h)
- 对应层：对应第 2 层链路层的 frame。理由：观察下图 `(f)` 最后填充的是 Ethernet header，也即对应链路层。
- 含义：sk_buff 是贯穿整个 Linux Network 栈的 [最基础的数据结构](http://vger.kernel.org/~davem/skb.html)
  - [内核中 sk_buff 结构体在各层协议之间传输不是用拷贝 sk_buff 结构体，而是通过增加协议头和移动指针来操作的。](https://blog.csdn.net/YuZhiHui_No1/article/details/38666589)
- Ring Buffer 与 Socket Buffer 的区别在于 Ring Buffer 不存实际数据，而只是指向存实际数据的 Socket Buffer 而已
- [网卡在启动时会申请一个接收 Ring Buffer，其条目都会指向一个 skb 的内存](https://cloud.tencent.com/developer/article/1400834)
- sk_buff 既用在发送，也用在接收中

```
The socket buffer, or "SKB",
is the most fundamental data structure in the Linux networking code.
Every packet sent or received is handled using this data structure.
```

> ↑ [How SKBs work](http://vger.kernel.org/~davem/skb.html)

![](https://github.com/vikyd/note-bigfile/blob/master/ifconfig/understanding_linux_network_internals_figure2-8_sk_buff.png?raw=true)

> [↑ 发送数据时：sk_buff 从 TCP 层到链路层的变化 -《Understanding Linux Network Internals》](https://doc.lagout.org/operating%20system%20/linux/Understanding%20Linux%20Network%20Internals.pdf)

此外，从 [`sk_buff.h`](https://github.com/torvalds/linux/blob/v5.8/include/linux/skbuff.h#L699-L701) L699-L701 源码看，每个 sk_buff 包含 1 个传输层（TCP、UDP）header、 1 个网络层（IP）header、 1 个链路层（Ethernet）mac header：

```h
 *	@transport_header: Transport layer header
 *	@network_header: Network layer header
 *	@mac_header: Link layer header
```

## Ring Buffer

见前 [接收数据流程](#接收数据流程) 小节的图中的 `Descriptor Ring`。

## qdisc

- 全称：[Queueing Discipline](https://tldp.org/HOWTO/Traffic-Control-HOWTO/classless-qdiscs.html)
- 含义：Linux 中的用于 [控制发送数据的流量]() 的队列（可能这种队列不止一个），见 [tc](https://man7.org/linux/man-pages/man8/tc.8.html) 命令 （[Traffic Control](https://tldp.org/HOWTO/html_single/Traffic-Control-HOWTO/#c-qdisc)）
- qdisc 存在于 Linux 内存中，与前面的 Ring Buffer 无关（或说是，发送数据时，先经过 qdisc 规则处理，才到 Ring Buffer）
- qdisc 队列的内容与 Ring Buffer 类似，也是类似指向 sk_buff 数据的指针（猜）
- 图，见前面 [发送数据流程](#发送数据流程) 小节图中的 `Queueing Discipline`

# ifconfig 各字段：详述

## 常见网卡命名

除了前面示例的 `eth1`，`ifconfig` 的输出经常不止一个网卡的信息，这些网卡有些是物理网卡，有些是虚拟网卡。通过分析网卡名字，可以帮助大致了解该网卡的类型、来源等含义。

### 网卡命名类型

大致可分为几个命名类型（非标准）：

- 回环网卡
  - 如：`lo`、`lo0`
- 虚拟网卡
  - 如 `veth0`、`veth1` 等
- 物理网卡（`"Predictable Names" Scheme` 命名规范）

```
1. 如果固件或者 BIOS 提供的板载设备的索引号可用，就用此命名. 例如 eno1
2. 如果固件或者 BIOS 提供的 PCI-E 扩展插槽索引号可用，就用此命名. 例如 ens1
   > 可用 `lspci` 查看 PCI 设备列表和序号
3. 如果硬件接口的物理或者位置信息可用，就用此命名. 例如 enp2s0
4. 如果网络接口的 MAC 地址可用就用此命名. 例如 enx78e7d1ea46da
5. 传统的内核原生命名方式. 例如 eth0
```

> ↑ 参考 [Red Hat - 一致网络设备命名](https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/html/networking_guide/ch-consistent_network_device_naming)

默认地，systemd v197 使用策略 1，如果策略 1 条件不满如则使用策略 2，如果策略 2 条件不满足使用策略 3，如果其它条件都不满足使用策略 5。 策略 4 默认不使用，允许用户选择是否启用。
上述提到的 `o`、`p`、`s`、`x`、`f` 等的含义：

| 格式                                                                         | 描述             |
| ---------------------------------------------------------------------------- | ---------------- |
| `o`<index>                                                                   | 板载设备索引号   |
| `s`<slot>[`f`<function>][`d`<dev_id>]                                        | 热插拔插槽索引号 |
| `x`<MAC>                                                                     | MAC 地址         |
| `p`<bus>`s`<slot>[`f`<function>][`d`<dev_id>]                                | PCI 地理位置     |
| `p`<bus>`s`<slot>[`f`<function>][`u`<port>][..][`c`<config>][`i`<interface>] | USB 端口链       |

> 表格来源：[Predictable Network Interface for Red Hat Enterprise Linux 7.0](https://h50146.www5.hpe.com/products/software/oe/linux/mainstream/support/whitepaper/pdfs/4AA5-4073ENW.pdf)

详细参考：

- [更多网卡名实例：systemd.net-naming-scheme — Network device naming schemes](https://www.freedesktop.org/software/systemd/man/systemd.net-naming-scheme.html#Examples)
- [CentOS7 网卡一致性命名规则
  ](https://linuxgeeks.github.io/2015/11/03/105011-CentOS7%E7%BD%91%E5%8D%A1%E4%B8%80%E8%87%B4%E6%80%A7%E5%91%BD%E5%90%8D%E8%A7%84%E5%88%99/)
- Mac 命令行查看所有物理网络设备：`networksetup -listallhardwareports`

### 常见网卡名

> 下面内容，部分来自经验所见，不代表必然性

- `lo`
  - 全称：`Loopback`
  - 含义：本地回环网卡，不是实际硬件，而是软件模拟的本地网卡；回环网络上最常用的地址是 IPv4：`127.0.0.1`，IPv6：`::1`，[常用于本地服务测试](https://askubuntu.com/a/247626/1042664)。Linux network namespace 默认包含一个 Loopback。
  - 此名称常见于 Linux 系统
- `lo0`
  - 全称：`Loopback` + 数字
  - 含义：与前面 `lo` 相同
  - 此名称常见于 macOS 系统
- `en1`、`en2`
  - 全称：`Ethernet` + 数字
  - 含义：物理网卡
  - 此类名称常见于 macOS 系统
- `eth0`、`eth1`
  - 全称 `Ethernet` + 数字
  - 含义：物理网卡
  - 这是传统的 Linux 网卡命名，[这种命名方法的结果不可预知的，即可能第二块网卡对应 eth0，第一块网卡对应 eth1](https://blog.csdn.net/hzj_001/article/details/81587824)
  - 此名称常见于 Linux 系统
- `veth` 开头（如 `veth1104e53`、`veth1`）
  - 全称：[Virtual Ethernet Device](https://man7.org/linux/man-pages/man4/veth.4.html)
  - 含义：通常指虚拟 Ethernet 网卡，常用于 [将从一个 network namespace 发出的数据包转发到另一个 namespace](https://blog.csdn.net/sld880311/article/details/77650937)。`veth` 总是成对出现，类似于一根网线的两端，且两端各有一个网卡。常见于装有 Docker 的 host。
  - [其他虚拟网卡类型列表，如 Bridge、XLAN、MACVLAN 等](https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/)
  - 与 Docker 的关系，见后面 [`veth`开头网卡与 Docker 的关系](#veth开头网卡与docker的关系) 小节
- `br-e06065d96cd9`
  - `br-` 开头的网卡通常是 Docker 创建的虚拟网卡（如 `docker network create abc` 默认会创建一个 `bridge` 类型的网卡）
    - 验证确实是 `bridge` 类型：`ip -details link`
    - 得到：对应网卡信息最后一行均显示为 `bridge` 类型
- `docker0`
  - 含义：安装 Docker 后 [默认创建](https://docs.docker.com/engine/reference/commandline/network_create/#extended-description) 的一个 [bridge](https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/#bridge) 类型的虚拟网卡

### veth 开头网卡与 Docker 的关系

Docker 每启动一个 container，host 的网卡列表就会多一个名称以 `veth` 开头的虚拟网卡，与 container 内的 `eth0` 形成一对，用于将 container 连接到 Docker 的 `docker0` 网桥中。

验证步骤：

- 创建 container 并 start，以这个 [image](https://hub.docker.com/r/sdnvortex/ethtool) 为例（里含 `ethtool` 工具，方便验证）
- host 执行：`ip link`
  - 得到：`1635784: veth1104e53: <BROADCAST,MULTICAST,UP,LOWER_UP> ...`
  - 含义：`1635784` 为网卡 id 号（这是在 host 看见的）
- host 执行：`ethtools -S veth1104e53`
  - 得到：`NIC statistics: peer_ifindex: 1635783`
  - 含义：表示 veth 的另一端（即 container 内）的 veth id 号为 `1635783`
- container 内执行：`ip link`
  - 得到：`1635783: eth0: <BROADCAST ...`
  - 含义：container 内的 `eth0` 的 id 号为 `1635783`，这正是 host 的 `peer_ifindex` 所指向的 id（得证 host 的 `veth1104e53` 指向了 container 的 `eth0`，待证反方向）
- container 内执行：`ethtool -S eth0`
  - 得到：`NIC statistics: peer_ifindex: 1635784`
  - 含义：表示 veth 的另一端（即 host 中）的 veth id 号为 `1635784`，即对应 host `veth1104e53` 的 id（得证 container 的 `eth0` 指向了 host 的 `veth1104e53`）

验证：host 的 `veth1104e53` 和 container 的 `eth0` 确实是 `veth` 类型的虚拟网卡：

- host、container 分别执行：`ip -details link show`
  - 得到：对应网卡信息最后一行均显示是 `veth` 类型

验证：host 的 `veth1104e53` 是否挂在 Docker 的 `docker0` bridge？

- host 执行：`brctl show`
  - 得到：最后一列 `docker0` 开头的行中显示 `interfaces veth1104e53`，得证

参考：[veth 与 bridge 实验：Step-by-Step Guide: Establishing Container Networking](https://dzone.com/articles/step-by-step-guide-establishing-container-networki)

## `flags`

### `flags` 状态列表 - Linux

示例：`flags=4163<UP,BROADCAST,RUNNING,MULTICAST>`

含义：表示当前网卡的状态（此列表并非可操作的命令）

字段解释：

- `UP`：表示网卡已启动（[interface is up](https://github.com/torvalds/linux/blob/v5.8/include/uapi/linux/if.h#L59)）
  > 无 `UP` 则表示网卡未启动（`ifconfig -a` 显示未启动网卡）
- `BROADCAST`：网卡的广播地址有效（[broadcast address valid. Volatile](https://github.com/torvalds/linux/blob/v5.8/include/uapi/linux/if.h#L60)）
- `RUNNING`：网卡已连接到路由器等设备（[interface RFC2863 OPER_UP. Volatile](https://github.com/torvalds/linux/blob/v5.8/include/uapi/linux/if.h#L66)）
  > 与 `UP` 的区别：`UP` 表示网卡本身启动了，`RUNNING` 表示是否连接到了路由器等设备
- `MULTICAST`：可以发送组播包（或说多播）（[Supports multicast](https://github.com/torvalds/linux/blob/v5.8/include/uapi/linux/if.h#L73)）

`UP`、`BROADCAST` 等的全部定义（[Linux 源码](https://github.com/torvalds/linux/blob/v5.8/include/uapi/linux/if.h#L59-L105)）：

```c
enum net_device_flags {
/* for compatibility with glibc net/if.h */
#if __UAPI_DEF_IF_NET_DEVICE_FLAGS
	IFF_UP				    = 1<<0,  /* sysfs */
	IFF_BROADCAST			= 1<<1,  /* volatile */
	IFF_DEBUG		    	= 1<<2,  /* sysfs */
	IFF_LOOPBACK			= 1<<3,  /* volatile */
	IFF_POINTOPOINT			= 1<<4,  /* volatile */
	IFF_NOTRAILERS			= 1<<5,  /* sysfs */
	IFF_RUNNING		    	= 1<<6,  /* volatile */
	IFF_NOARP		    	= 1<<7,  /* sysfs */
	IFF_PROMISC		    	= 1<<8,  /* sysfs */
	IFF_ALLMULTI			= 1<<9,  /* sysfs */
	IFF_MASTER		    	= 1<<10, /* volatile */
	IFF_SLAVE		    	= 1<<11, /* volatile */
	IFF_MULTICAST			= 1<<12, /* sysfs */
	IFF_PORTSEL		    	= 1<<13, /* sysfs */
	IFF_AUTOMEDIA			= 1<<14, /* sysfs */
	IFF_DYNAMIC		    	= 1<<15, /* sysfs */
#endif /* __UAPI_DEF_IF_NET_DEVICE_FLAGS */
#if __UAPI_DEF_IF_NET_DEVICE_FLAGS_LOWER_UP_DORMANT_ECHO
	IFF_LOWER_UP			= 1<<16, /* volatile */
	IFF_DORMANT		    	= 1<<17, /* volatile */
	IFF_ECHO		    	= 1<<18, /* volatile */
#endif /* __UAPI_DEF_IF_NET_DEVICE_FLAGS_LOWER_UP_DORMANT_ECHO */
};
```

状态值列表：

```
flag             位运算     十进制       二进制
------------------------------------------------------------------------------------------------------
UP               1<<0       1          0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
BROADCAST        1<<1       2          0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0
DEBUG            1<<2       4          0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0
LOOPBACK         1<<3       8          0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0
POINTOPOINT      1<<4       16         0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0
NOTRAILERS       1<<5       32         0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0
RUNNING          1<<6       64         0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0
NOARP            1<<7       128        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0
PROMISC          1<<8       256        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0
ALLMULTI         1<<9       512        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0
MASTER           1<<10      1024       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0
SLAVE            1<<11      2048       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0
MULTICAST        1<<12      4096       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0
PORTSEL          1<<13      8192       0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0
AUTOMEDIA        1<<14      16384      0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0
DYNAMIC          1<<15      32768      0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
LOWER_UP         1<<16      65536      0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
DORMANT          1<<17      131072     0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ECHO             1<<18      262144     0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
```

辅助理解：

- 每个值是 32 bit（C 语言的 int 类型在 64 位系统下的大小通常是 4 Byte = 4 \* 8 bit = 32 bit）
- 二进制：`00000001` 表示 1，`10000000` 表示 80

生成上述二进制列表的简单 C 程序：[flags_all_in_binary.c](https://github.com/vikyd/ifconfig-experiment/blob/main/README.md) 。

> 文件内已包含执行命令

### `flags=4163` 计算方式 - Linux

以 Linux `ifconfig` 的这段输出为例：

```
eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
```

简述：

```
4163 = UP + BROADCAST + RUNNING + MULTICAST
     =  1 +     2     +   64    +   4096
```

> 每个值参考前面 `状态值列表` 表格

用位运算（`或` 运算 `|`）：

```
UP       ：0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
BROADCAST：0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0
RUNNING  ：0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0
MULTICAST：0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0
    =    ：0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 1 1
换算十进制 ：4163
```

小结：

- 计算方式为所有 flag 值相加即可
- 实际操作时，通常做 [`或` 运算](https://networkengineering.stackexchange.com/a/57925)（`|`），[效率更高](https://github.com/torvalds/linux/blob/v5.8/drivers/net/eql.c#L152)
- 疑惑：Mac 的 flags 值貌似不是这样计算的？
  > 后面小节有解答

### `flags=8863` 计算方式 - Mac

Mac `ifconfig` 中 `flags` 值的计算方式与 Linux 不同。

以 Mac `ifconfig` 的这段输出为例：

```
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
```

先上结论：Mac 的 flags 数字是十六进制数字（Linux 的是十进制数字）。

#### 不正确的摸索

首先，查看 Mac 本地自带文件 `/Library/Developer/CommandLineTools/SDKs/MacOSX10.15.sdk/usr/include/net/if.h`（为方便查看，可参考 GitHub 版非官方 MacOSX-SDK 源码镜像，约[第 88-104 行](https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX10.15.sdk/usr/include/net/if.h#L86-L105)），里面状态值列表与 Linux 有相同也有不同：

> `MacOSX10.15.sdk` 目录可能需修改为你 Mac 实际路径

```c
#define	IFF_UP	    	0x1		    /* (n) interface is up */
#define	IFF_BROADCAST	0x2		    /* (i) broadcast address valid */
#define	IFF_DEBUG   	0x4		    /* (n) turn on debugging */
#define	IFF_LOOPBACK	0x8	    	/* (i) is a loopback net */
#define	IFF_POINTOPOINT	0x10		/* (i) is a point-to-point link */
#define	IFF_KNOWSEPOCH	0x20		/* (i) calls if_input in net epoch */
#define	IFF_DRV_RUNNING	0x40		/* (d) resources allocated */
#define	IFF_NOARP   	0x80		/* (n) no address resolution protocol */
#define	IFF_PROMISC 	0x100		/* (n) receive all packets */
#define	IFF_ALLMULTI	0x200		/* (n) receive all multicast packets */
#define	IFF_DRV_OACTIVE	0x400		/* (d) tx hardware queue is full */
#define	IFF_SIMPLEX 	0x800		/* (i) can't hear own transmissions */
#define	IFF_LINK0   	0x1000		/* per link layer defined bit */
#define	IFF_LINK1   	0x2000		/* per link layer defined bit */
#define	IFF_LINK2   	0x4000		/* per link layer defined bit */
#define	IFF_ALTPHYS	IFF_LINK2	    /* use alternate physical connection */
#define	IFF_MULTICAST	0x8000		/* (i) supports multicast */
#define	IFF_CANTCONFIG	0x10000		/* (i) unconfigurable using ioctl(2) */
#define	IFF_PPROMISC	0x20000		/* (n) user-requested promisc mode */
#define	IFF_MONITOR 	0x40000		/* (n) user-requested monitor mode */
#define	IFF_STATICARP	0x80000		/* (n) static ARP */
#define	IFF_DYING   	0x200000	/* (n) interface is winding down */
#define	IFF_RENAMING	0x400000	/* (n) interface is being renamed */
#define	IFF_NOGROUP	    0x800000	/* (n) interface is not part of any groups */
```

> ↑ 类似代码在 FreeBSD 也能 [见到](https://github.com/freebsd/freebsd/blob/397745991e468233fefde8cadf34966ea8f0a33b/sys/net/if.h#L120-L165)

根据上述代码对照 Mac `ifconfig` 的输出，可发现：

| Mac ifconfig 输出 | 上述源码定义    | 十六进制值 | 十进制值 |
| ----------------- | --------------- | ---------- | -------- |
| UP                | IFF_UP          | 0x1        | 1        |
| BROADCAST         | IFF_BROADCAST   | 0x2        | 2        |
| SMART             | ?               | ?          | ?        |
| RUNNING           | IFF_DRV_RUNNING | 0x40       | 64       |
| SIMPLEX           | IFF_SIMPLEX     | 0x800      | 2048     |
| MULTICAST         | IFF_MULTICAST   | 0x8000     | 32768    |

> C 语言中 `0x` 开头是十六进制值

Mac `ifconfig` 输出的 `flags=8863` 明显小于上表的 `32768`，所以 Mac 计算 `flags` 的方式依然存疑问。

有 2 个疑问：

- `SMART` 到底定义在何处？
- `8863` 如何计算得到？

#### 貌似正确的摸索

经搜索，在 [苹果官网](https://opensource.apple.com/source/network_cmds/network_cmds-543/ifconfig.tproj/ifconfig.c.auto.html) 找到以下定义（此定义终于包含 `SMART` 的定义了）：

```c
#define	IFFBITS \
"\020\1UP\2BROADCAST\3DEBUG\4LOOPBACK\5POINTOPOINT\6SMART\7RUNNING" \
"\10NOARP\11PROMISC\12ALLMULTI\13OACTIVE\14SIMPLEX\15LINK0\16LINK1\17LINK2" \
"\20MULTICAST"
```

> 这本质是一个字符串，只是里面有些转义值而已

> 为方便查看，可参考 GitHub 版 Mac 非官方 ifconfig 源码镜像，`ifconfig.tproj/ifconfig.c` 的约[第 1205-1208 行](https://github.com/apple-opensource-mirror/network_cmds/blob/b4ac2ac03f0af8ed3bf575bae9ca9a8d9adecb11/ifconfig.tproj/ifconfig.c#L1205-L1208)

可整理出下面表格：

| Mac ifconfig 输出 | 上述源码定义 | C 语言转义八进制值 | 十进制值 | 本质也是向左移位 | 十六进制值 |
| ----------------- | ------------ | ------------------ | -------- | ---------------- | ---------- |
| UP                | \1UP         | \1                 | 1        | 1<<0             | 0x1        |
| BROADCAST         | \2BROADCAST  | \2                 | 2        | 1<<1             | 0x2        |
| SMART             | \6SMART      | \6                 | 6        | 1<<5             | 0x20       |
| RUNNING           | \7RUNNING    | \7                 | 7        | 1<<6             | 0x40       |
| SIMPLEX           | \14SIMPLEX   | \14                | 12       | 1<<11            | 0x800      |
| MULTICAST         | \20MULTICAST | \20                | 16       | 1<<15            | 0x8000     |

解释：

- `本质也是向左移位`：来自 [`ifconfig.tproj/ifconfig.c`](https://github.com/apple-opensource-mirror/network_cmds/blob/b4ac2ac03f0af8ed3bf575bae9ca9a8d9adecb11/ifconfig.tproj/ifconfig.c#L1808-L1837) 约第 1808-1837 行
- C 语言中 `\1-3位数字` [表示八进制值转义](https://en.wikipedia.org/wiki/Escape_sequences_in_C#Table_of_escape_sequences)，例如 `IFFBITS` 中开头的 `\020` 是八进制，对应十进制 `16`；八进制 `\1` 表示十进制 `1`；八进制 `\20` 表示十进制 `16`

观察上表右侧列 `十六进制值`，貌似：

```
8863 = UP + BROADCAST + SMART + RUNNING + SIMPLEX + MULTICAST
      0x1 +    0x2    + 0x20  +  0x40   + 0x800   +  0x8000
```

> 注意：上面是十六进制相加（非十进制相加）

`8863`，这不就是 Mac `ifconfig` 输出的 `flags=8863` 值！

假设 Mac 的 `en0` 网卡的 `flags` 为 `8863`，执行此 [简单 C 程序](https://github.com/vikyd/ifconfig-experiment/blob/main/mac_get_int_flags.c) 可获取 Mac 执行网卡的 `flags` 值，可得输出：

```
NIC name         : en0
flags as decimal : 34915
flags as hex     : 8863
```

可知：`8863` 实际是十进制值 `34915` 的十六进制表示方式。

观察输出的 `34915`，也就是前面 [不正确的摸索](#不正确的摸索) 小节里表格十进制值之和：`1 + 2 + 32 + 64 + 2048 + 32768 = 34915`（因为之前漏了 `SMART=0x40` 的定义）。

#### 结论

- Mac `ifconfig` 输出的 `flags=8863` 实际是十六进制表示方式（`0x8863` 可能更适当）
- Linux `ifconfig` 输出的 `flags=4163` 是十进制表示方式
- Mac 与 Linux 的 `flags` 定义的状态列表不一致，所以不管十进制还是十六进制，`flags` 显示的数字都必然不同
- 之所以开始容易对 Mac 的 flags 值误解，是因为以为也是类似 Linux 的 flags 的十进制值

参考：

- 苹果官方打包下载包含 `ifconfig` 源码的 [network_cmds](https://opensource.apple.com/tarballs/network_cmds/) 工具集
- [Mac 获取网卡 `flags` 数值（C 程序）](https://github.com/vikyd/ifconfig-experiment/blob/main/mac_get_int_flags.c)
- [Mac 根据 `flags` 数值还原出状态列表程序（C 程序）](https://github.com/vikyd/ifconfig-experiment/blob/main/mac_parse_int_flags.c)

## `mtu`

通常，mtu：指第 2 层链路层的 payload 的大小。链路层通常是 Ethernet 协议，所以通常指 `frame（帧）` 的 payload。

> 当然 mtu 有时也会指其他网络传输含义，但常见的说法就是指链路层的 payload 大小

### mtu 指 `发送`？还是 `发送`和`接收`？

首先，再次看看 mtu 的全称是什么？

- Linux 文档：[Maximum Transfer Unit](https://www.kernel.org/doc/html/latest/networking/netdevices.html#mtu)
- 维基百科：[Maximum Transmission Unit](https://en.wikipedia.org/wiki/Maximum_transmission_unit)
- RFC 1042 - A Standard for the Transmission of IP Datagrams over IEEE 802 Networks：[Maximum Transmission Unit](https://www.ietf.org/rfc/rfc1042.txt)
- `man ifconfig`：[Maximum Transfer Unit](https://linux.die.net/man/8/ifconfig)

看看单词含义，貌似既有 `发送`，也有 `发送`+`接收` 的含义：

- Transfer：转移、传播
- Transmission：传输、传播
  - transmit：传输、**发送**

再来看看 Linux 如何 [设置 mtu 大小](https://www.cyberciti.biz/faq/centos-rhel-redhat-fedora-debian-linux-mtu-size/) 的方式（假设网卡名为 `eth1`）。

CentOS 设置 mtu：

```sh
# 填写：MTU="1400"
➜  vim /etc/sysconfig/network-scripts/ifcfg-eth1

# 重启服务生效
➜  service network restart
```

Ubuntu 设置 mtu：

```sh
# 填写：
# iface eth1 inet static
# mtu 1400
➜  vim /etc/network/interfaces

# 重启服务生效
➜  /etc/init.d/networking restart
```

[ifconfig 命令](https://linux.die.net/man/8/ifconfig) 设置 mtu：

```sh
ifconfig ${Interface} mtu ${SIZE} up
ifconfig eth1 mtu 1400 up
```

[ip 命令](https://linux.die.net/man/8/ip) 设置 mtu：

```sh
ip link set dev eth1 mtu 1400
```

观察可知，这些设置都没区分发送或接收，所以，这里暂且认为 mtu 既是指 `发送`，同时也是指 `接收` 的大小限制。

> 相对的也有 MRU（Maximum Receive Unit） 的说法，但 Linux 中貌似不常见，[参考 01](https://www.networkers-online.com/blog/2016/03/understand-mtu-and-mru-the-full-story/)，[参考 02](https://hamy.io/post/000c/how-to-find-the-correct-mtu-and-mru-of-your-link/#gsc.tab=0)

### 为什么 `1500`？

`1500` 是链路层 Ethernet 协议常见的 mtu 大小，单位 Byte。

这篇文章通俗易懂回答了这个问题：[什么是 MTU？为什么 MTU 值普遍都是 1500？](https://developer.aliyun.com/article/222535)

个人理解：

- 有一定理论依据（如 payload 整个 frame 中应占较大比例提高传输效率，且，不应造成应用间网络延时大）
- 但更多是历史原因

参考：

- [通俗易懂解释 mtu 1500 来源 - 车小胖谈网络：Ethernet Frame](https://zhuanlan.zhihu.com/p/21318925)
- [Ethernet Ⅱ 以太帧的结构](http://www.023wg.com/message/message/cd_feature_eth_II.html)

### 为什么 `lo` 的 mtu 是 65536

`ifconfig` 通常还会输出本地回环网卡（[Loopback](https://en.wikipedia.org/wiki/Loopback)）的信息：

```
lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        loop  txqueuelen 0  (Local Loopback)
        RX packets 16709647  bytes 7809029174 (7.2 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 16709647  bytes 7809029174 (7.2 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

为什么此时 mtu 是 65536？

> 2^16 = 65536

答：

- 估计是因为回环地址无需经过第 2 层链路层的 Ethernet 协议，只需遵循第 3 层网络层的 [IP 协议](https://en.wikipedia.org/wiki/Internet_Protocol) 即可
- 回环网卡是软件模拟的网卡，速度很快
- 而 IP 协议的传输单元最大允许总大小（Header + Payload）为 [65535 Byte](http://www.023wg.com/message/message/cd_feature_ip_message_format.html)（话说为什么不是 65536？）
- 所以回环网卡的 mtu 就采用了最大的 65536

实例程序：此 [简单 C 程序](https://github.com/vikyd/ifconfig-experiment/blob/main/get_mtu_ioctl.c) 可通过 Linux 的 [ioctl 函数](https://www.cnblogs.com/Lxk0825/p/10216662.html) 获取指定网卡名的 `mtu` 值。

参考：

- [Linux Kernel 将默认 mtu 从 16436 byte 修改为 65536 byte 的 commit 信息](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=0cf833aefaa85bbfce3ff70485e5534e09254773)

### jumbo frames

[jumbo frame](https://en.wikipedia.org/wiki/Jumbo_frame)，中文译作巨型帧或巨帧。

当网卡及相关网络设备的速度越来越快时，标准的 mtu `1500` 就显得有些小了，此时即使将 mtu 设置到更大，也不会导致多个应用之间网络延时太大。于是有了 jumbo frame。

jumbo frame 对应 mtu 最大可到 9000 Byte。

背景：[在 1998 年，Alteon Networks 公司提出把 Data Link Layer 最大能传输的数据从 1500 bytes 增加到 9000 bytes，这个提议虽然没有得到 IEEE 802.3 Working Group 的同意，但是大多数设备厂商都已经支持。](https://www.cnblogs.com/h2zZhou/p/10715095.html)

### 修改 mtu 会重启网卡？

参考 [修改 MTU 会发生什么？](http://km.oa.com/articles/show/256023)，修改 mtu 时，大部分网卡会重启，可能会引起业务系统丢包。

以此网卡驱动为例 [`drivers/net/ethernet/realtek/8139cp.c`](https://github.com/torvalds/linux/blob/v5.8/drivers/net/ethernet/realtek/8139cp.c#L1274-L1290)：

```c
static int cp_change_mtu(struct net_device *dev, int new_mtu)
{
	struct cp_private *cp = netdev_priv(dev);

	/* if network interface not up, no need for complexity */
	if (!netif_running(dev)) {
		dev->mtu = new_mtu;
		cp_set_rxbufsize(cp);	/* set new rx buf size */
		return 0;
	}

	/* network IS up, close it, reset MTU, and come up again. */
	cp_close(dev);
	dev->mtu = new_mtu;
	cp_set_rxbufsize(cp);
	return cp_open(dev);
}
```

可见，流程是：先关闭网卡 `cp_close(dev)`，再修改 mtu `dev->mtu = new_mtu`，最后再启动网卡 `cp_open(dev)`。

## `inet6`

`ifconfig` 中的 `inet6` 字段表示 IPv6 的相关信息。

回顾前面的这行输出：

```
inet6 fe80::4001:aff:feaa:3  prefixlen 64  scopeid 0x20<link>
```

> 这是一个 [链路本地地址（Link-local address）](https://en.wikipedia.org/wiki/Link-local_address#IPv6)，注意不是 [本地回环地址（Loopback address）](https://en.wikipedia.org/wiki/Localhost#Loopback)，具体后面小节详说。

### IPv6 格式

IPv6 地址 `fe80::4001:aff:feaa:3` 实际代表：`fe8000000000000040010afffeaa0003`。

解释：

- IPv6 允许采用缩写方式表示网址
- IPv6 地址通常以十六进制表示
- 1 个十六进制 = 4 bit
- 32 个十六进制 = 128 bit
- 一个 IPv6 地址为 128bit

### Link Local 地址

名称：[`Link Local`](https://en.wikipedia.org/wiki/Link-local_address) 中文又称为 `链路本地地址`，后面描述统一表述为 `Link Local`。

用途：Link Local 地址可理解为无需 DHCP 也能让每个网卡拥有在内网唯一的 IPv6 地址。

区别于回环地址（Loopback）：回环地址在 IPv6 的形式为 `::1/128`，在 IPv4 为 `127.0.0.0/8`。回环地址是机器内部使用的，Link Local 是内网其他机器识别本机器用的。

- 根据 [分类](https://www.ripe.net/participate/member-support/lir-basics/ipv6_reference_card.pdf)，IPv6 的 Link Local 地址为：`fe80::/10`，即 128 bit 的前 10 bit 为 `1111 1110 10`
- 通常 Link Local 地址中间的第 11-64 bit 这 54 bit 均为 `0`，第 65-128 bit 这 64 bit 填充为网卡 [Mac 地址](https://en.wikipedia.org/wiki/MAC_address)
- 网卡 Mac 地址一般只有 48bit（如：`42:01:0a:aa:00:03`），可转换为 64bit 的 EUI-64
  - 转换过程简述
  - 将 Mac 48bit 拆开两部分，得前段 24bit，后段 24bit
  - 在前段、后段之间插入固定的 16bit：`1111 1111 1111 1110`，十六进制 `FFFE`，得共 64 bit
  - 最后将第 7 bit 取反（若为 `0` 则设置为 `1`，若为 `1` 则设置为 `0`）
    - 原因：[IEEE802 或者 EUI-64 地址的该位为 0，而全球唯一的 IPv6 接口标识的该位为 1](https://blog.csdn.net/Neo233/article/details/70336471)
- 最终得 `10bit + 54bit + 64bit = 128bit` 的 Link Local 地址

> 转换 Mac 为 IPv6 Link Local 的 [在线工具](https://www.vultr.com/resources/mac-converter/?mac_address=42%3A01%3A0a%3Aaa%3A00%3A03)

转换过程大致可见下面 3 个图。

![](https://packetlife.net/media/blog/attachments/69/eui64_step1.png)

> ↑ 48bit 拆开为两部分 - [来源](https://packetlife.net/blog/2008/aug/4/eui-64-ipv6/)

![](https://packetlife.net/media/blog/attachments/69/eui64_step1.png)

> ↑ 第 7 bit 取反 - [来源](https://packetlife.net/blog/2008/aug/4/eui-64-ipv6/)

![](https://mrncciew.files.wordpress.com/2013/04/ipv6-05.png)

> ↑ 48bit Mac 转换到 64bit EUI-64 - [来源](https://mrncciew.com/2013/04/05/ipv6-basics/)

### `scopeid`

用途（或说 scope）：用于区分不同的 IPv6 网址类型。

本质：

- 对于多播地址（[Multicast](https://en.wikipedia.org/wiki/Multicast_address#IPv6)），其第 13-16 bit 用于指定 scope 值
- 而对于 Link-Local（`fe80::/10`）、Global 等地址类型而言，128bit 中并无任何 1 bit 指明 scope 值，所以估计此时 scope 的值来源于对地址前缀的理解，而非地址的某些 bit（有错请指正）

从 `ifconfig` 输出看，貌似 Link-Local、Global 等地址类型也是与多播地址定义的 scope 范围值一致。

多播地址 scope 可选值包括：

| 值  | 含义                                  |
| --- | ------------------------------------- |
| 0x1 | 回环地址 Loopback                     |
| 0x2 | 链路本地地址 Link Local               |
| 0x5 | 站点本地地址 Site Local（据说废弃了） |
| 0x8 | 组织本地地址 Organization Local       |
| 0xe | 全球唯一地址 Global                   |

表格参考：

- [维基百科 - IPv6 address](https://en.wikipedia.org/wiki/IPv6_address#Multicast)
- [Linux Kernel 中对应的定义](https://github.com/torvalds/linux/blob/v5.8/include/net/ipv6.h#L124-L128)（基本能对应）
- [`ifconfig` 中对应的定义](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/lib/interface.c#L70-L85)（貌似对应不上）

所以，对于本实例 `inet6 fe80::4001:aff:feaa:3 prefixlen 64 scopeid 0x20<link>` 来说，`0x20` 大致可对应 Link Local 类型（为何是 `0x20` 而非 `0x2`？）；若是 Loopback 回环地址，则通常会是 `inet6 ::1 prefixlen 128 scopeid 0x10<host>`。

参考：

- [【IP，滴水穿石，基石】IPv6 简单走两步 · 第二回 认识认识 IPv6 地址](https://forum.huawei.com/enterprise/zh/forum.php?mod=viewthread&tid=412485)
- [IPv6 cheat-sheet, part 2: the IPv6 address space](https://www.menandmice.com/blog/ipv6-reference-address-space/)

## `txqueuelen`

全称：[transmit queue length](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/include/interface.h#L37)。

从结论说，`txqueuelen` 是 **发送数据** 时 qdisc 的允许队列大小。

![](http://www.linuxjournal.com/files/linuxjournal.com/ufiles/imagecache/large-550px-centered/u1002061/11476f2.jpg)

> [↑ 发送数据时：Queueing Disciplines（Qdisc） 与 Driver Queue（Ring Buffer）与 SKB（Socket Buffer 或 sk_buff）与 NIC（网卡）的关系](https://www.linuxjournal.com/content/queueing-linux-network-stack)

> 更多细节见接下来的小节

### `txqueuelen` vs `接收`、`发送`

`txqueuelen` 的全称 [transmit queue length](https://github.com/giftnuss/net-tools/blob/master/include/interface.h#L37) 的 `transmit` 是 `发送` 的意思，相对的，`接收` 是 `receive`。

根据 [TC(Traffic Control)命令—linux 自带高级流控](https://cloud.tencent.com/developer/article/1409664)：

> 一般只能限制网卡 `发送的数据包`，不能限制网卡接收的数据包，所以可以通过改变发送次序来控制传输速率。Linux 流量控制主要是在输出接口排列时进行处理和实现的。

求：更客观证据说明 `txqueuelen`、`qdisc` 只用在 `发送` 而没用在 `接收`？

### `txqueuelen` vs `qdisc`

`qdisc`（全称：Queueing Discipline）：是 Linux [控制](https://tldp.org/HOWTO/Traffic-Control-HOWTO/components.html)网络发送流量（[tc 命令](https://man7.org/linux/man-pages/man8/tc.8.html)）的机制。

`txqueuelen`：是 qdisc 的 [允许队列大小](https://www.coverfire.com/articles/queueing-in-the-linux-network-stack/)。

### `txqueuelen` 的单位

`txqueuelen` 的单位是 [sk_buff（socket buffer）](http://vger.kernel.org/~davem/skb.html)。

sk_buff 是贯穿整个 Linux Network 栈的 [最基础的数据结构](http://vger.kernel.org/~davem/skb.html) 。

详细可见前面 [sk_buff](#sk_buff) 小节。

> 此处暂未找到直接源码证据，有错求指正

### `txqueuelen` vs `TX` 的 `errors`、`dropped`

`errors`、`dropped` 主要与 Ring Buffer、Socket Buffer（有时两者统称为 Ring Buffer）的错误相关。但 Ring Buffer 与 qdisc 是互相独立的概念，qdisc 存在于 Ring Buffer 之前。

发送数据时，应用层的数据先到达 qdisc，之后才到达 Ring Buffer，参考前面 [txqueuelen 的图](#txqueuelen)。

所以 `txqueuelen` vs `TX` 的 `errors`、`dropped` 无关。

> 还可参考 [大话 txqueuelen](http://km.oa.com/articles/show/219737)

### `Queueing Discipline` vs `Driver Queue`

`Queueing Discipline`：简称为 [qdisc](#qdisc)，前面已有介绍。

`Driver Queue`：也即 Ring Buffer。

两者互相独立，发送数据时，应用层先经过 qdisc，之后才到达 Ring Buffer。

Ring Buffer 是一个简单的 FIFO（先进先出）队列，但太简单，所以出现了 qdisc 提供灵活的流量控制功能，两者算是职责分离。

两者单位一致，都是 [sk_buff（socket buffer）](http://vger.kernel.org/~davem/skb.html)。

查看 Ring Buffer 队列大小的命令：

```sh
➜ ethtool -g eth1

Ring parameters for eth1:
Pre-set maximums:
RX:             4096
RX Mini:        0
RX Jumbo:       0
TX:             4096
Current hardware settings:
RX:             4096
RX Mini:        0
RX Jumbo:       0
TX:             4096
```

而查看 qdisc 队列大小，其实就是 `txqueuelen`。

### `txqueuelen` vs `mtu`

这是互相独立的概念。

`txqueuelen`：是 [qdisc](#qdisc) 队列的大小。

`mtu`：是第 2 层链路层 Ethernet 协议的 payload 最大允许大小。

### `txqueuelen` 数据来源

从 ifconfig 源码看 `txqueuelen` 值的来源：

- `ifconfig` ->`lib/interface.c` [L848](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/lib/interface.c#L848)：

```c
printf(_("  txqueuelen %d"), ptr->tx_queue_len);
```

- `ifconfig` ->`lib/interface.c` [L473-L481](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/lib/interface.c#L473-L481)：

```c
#ifdef HAVE_TXQUEUELEN
    strcpy(ifr.ifr_name, ifname);
    if (ioctl(skfd, SIOCGIFTXQLEN, &ifr) < 0)
	    ife->tx_queue_len = -1;	/* unknown value */
    else
	    ife->tx_queue_len = ifr.ifr_qlen;
#else
    ife->tx_queue_len = -1;	/* unknown value */
#endif
```

此 [简单 C 程序](https://github.com/vikyd/ifconfig-experiment/blob/main/get_txqueuelen_ioctl.c) 可通过 Linux 的 [ioctl](https://www.cnblogs.com/Lxk0825/p/10216662.html) 获取指定网卡的 `txqueuelen` 值。

### `tc` qdisc 延时实验

此实验命令不多，相对简单易操作，详见这篇文章 [Adding simulated network latency to your Linux server](https://bencane.com/2012/07/16/tc-adding-simulated-network-latency-to-your-linux-server/) 。

其中延时对应的是数据 **发送**，而非接收：

> Because you are adding this rule to a specific interface all traffic `out of that interface` will have the 97ms delay

## `RX`和`TX`

### 全称来源

- `RX`：全称是 `Received`
- `TX`：全称是 `Transmitted`

证据：ifconfig 的源码 `注释` 有写明。

- `ifconfig` ->`lib/interface.c` [L906-L909](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/lib/interface.c#L906-L909)：

```c
printf(_("RX packets %llu  bytes %llu (%lu.%lu %s)\n"),
	ptr->stats.rx_packets,
       rx, (unsigned long)(short_rx / 10),
       (unsigned long)(short_rx % 10), Rext);
```

↓

- `ifconfig` ->`include/interface.h` [L2-L3](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/include/interface.h#L2-L3)：

```c
unsigned long long rx_packets;	/* total packets received       */
unsigned long long tx_packets;	/* total packets transmitted    */
```

为什么 `receive` 通常不是缩写成 `rev`、`rc` 之类，而缩写成 `rx`？

来自 Quora 的回答 [What does "X" stand for in TX and RX?](https://qr.ae/pN5kki)：

> It's doesn't stand for anything. The X is used to pad out acronyms to make them more acceptable.

来自 reddit 的回答 [Why is "transmit" and "receive" often abbreviated as Tx and Rx, and not Tm and Rc, or something else that makes sense?](https://www.reddit.com/r/answers/comments/2ja441/why_is_transmit_and_receive_often_abbreviated_as/)：

> X is occasionally used as an abbreviation for "trans" because it visually looks like a cross. Perhaps Tx/Rx just combine that concept into convenient abbreviations.

### `GiB` vs `GB`？`1024` vs `1000`

再次回顾前面 Linux `ifconfig` 输出的其中一行（来自 CentOS）：

```
RX packets 69426519  bytes 20960261647 (19.5 GiB)
```

`bytes 20960261647` 与 `19.5 GiB` 是什么关系？

```
① 20960261647 / (1024)^3 = 19.5207648417 ≈ 19.5

② 20960261647 / (1000)^3 = 20.960261647 ≈ 20.9 或 21.0
```

由上述两个式子可知 `GiB` 对应 `1024` 换算。

再看看 [`man 7 units`](https://man7.org/linux/man-pages/man7/units.7.html) 描述（也可 Linux 中执行此命令查看）：

```
...
Decimal prefixes
Prefix   Name   Value
k        kilo    10^ 3  = 1000
M        mega    10^ 6  = 1000000
G        giga    10^ 9  = 1000000000
T        tera    10^12  = 1000000000000

...

Binary prefixes
Prefix   Name   Value
Ki       kibi   2^10 = 1024
Mi       mebi   2^20 = 1048576
Gi       gibi   2^30 = 1073741824
Ti       tebi   2^40 = 1099511627776
...
```

再看看来自 Ubuntu 18.04 的 `ifconfig` 的对应输出（这次输出的是 `GB` 而非 `GiB`）：

```
RX packets 4466144  bytes 2817476788 (2.8 GB)
```

再算一次：

```
① 2817476788 / (1024)^3 = 2.62397973612 ≈ 2.6

② 2817476788 / (1000)^3 = 2.817476788 ≈ 2.8
```

明显，这里 `GB` 对应的是 `1000` 的换算。

### 重启网卡、系统是否清零 `packets`

在 Ubuntu 18.04 上试验了一下。

结果：

- 重启网卡（即禁用网卡，再启用网卡）不会清零 `RX packets` 数据
  - 禁用网卡：[`ifconfig 网卡名 down`](https://zhuanlan.zhihu.com/p/65480107)
  - 启用网卡：`ifconfig 网卡名 up`
- 重启系统，会清零 `RX packets` 数据

### `RX`、`TX` 的 `packets` 对应哪一层？

`packets` 对应第 2 层链路层的 frame，而非对应第 3 层网络层的 IP packet。

理由：

- 前面 [sk_buff](#sk_buff) 小节已说明 sk_buff 对应第 2 层链路层的 frame
- 如何说明 `RX` 的 `packets` 与 sk_buff 一一对应？

以此网卡驱动为例 [`drivers/net/ethernet/realtek/8139cp.c`](https://github.com/torvalds/linux/blob/v5.8/drivers/net/ethernet/realtek/8139cp.c#L418-L432)：

```c
static inline void cp_rx_skb (struct cp_private *cp, struct sk_buff *skb,
			      struct cp_desc *desc)
{
	u32 opts2 = le32_to_cpu(desc->opts2);

	skb->protocol = eth_type_trans (skb, cp->dev);

	cp->dev->stats.rx_packets++;
	cp->dev->stats.rx_bytes += skb->len;

	if (opts2 & RxVlanTagged)
		__vlan_hwaccel_put_tag(skb, htons(ETH_P_8021Q), swab16(opts2 & 0xffff));

	napi_gro_receive(&cp->napi, skb);
}
```

观测上述驱动，`cp->dev->stats.rx_packets++` 是这个驱动唯一让 `packets` 数量增加的地方，而这个函数操作的原子正是 sk_buff。

> 有错请指正

### `packets`、`sk_buff`、`frame` 一一对应吗？

`RX` 的 `packets`、第 2 层链路层的 `frame`、Linux 内核的 [sk_buff](#sk_buff) 是一一对应的。

`RX` 的 `packets` 与第 3 层网络层 IP 协议的 `packet` 是不同的概念。

为什么 ifconfig 将其称为 `RX packets` 而不是 `RX frames`？

可能是历史原因，譬如：

- 这里将 sk_buff 称为 Packet Structure - [Linux IP Networking](https://www.cs.unh.edu/cnrg/people/gherrin/linux-net.html#tth_sEc2.3)

其他参考：

- 貌似 packet 有时也可指物理层 - [What is the difference between frames and packets?](https://www.quora.com/What-is-the-difference-between-frames-and-packets)
- [`man packet`](https://man7.org/linux/man-pages/man7/packet.7.html)
  > Packet sockets are used to receive or send raw packets at the device driver (OSI Layer 2) level.
- 里面搜索 `frame` 说明 frame 对应 sk_buff - [The Journey of a Packet Through the Linux Network Stack](https://www.cs.dartmouth.edu/~sergey/me/netreads/path-of-packet/Lab9_modified.pdf)

### `RX` 的 `errors` 指哪些错误？

以此网卡驱动为例 [`drivers/net/ethernet/realtek/8139cp.c`](https://github.com/torvalds/linux/blob/v5.8/drivers/net/ethernet/realtek/8139cp.c#L434-L450)：

```c
static void cp_rx_err_acct (struct cp_private *cp, unsigned rx_tail,
			    u32 status, u32 len)
{
	netif_dbg(cp, rx_err, cp->dev, "rx err, slot %d status 0x%x len %d\n",
		  rx_tail, status, len);
	cp->dev->stats.rx_errors++;
	if (status & RxErrFrame)
		cp->dev->stats.rx_frame_errors++;
	if (status & RxErrCRC)
		cp->dev->stats.rx_crc_errors++;
	if ((status & RxErrRunt) || (status & RxErrLong))
		cp->dev->stats.rx_length_errors++;
	if ((status & (FirstFrag | LastFrag)) != (FirstFrag | LastFrag))
		cp->dev->stats.rx_length_errors++;
	if (status & RxErrFIFO)
		cp->dev->stats.rx_fifo_errors++;
}
```

从此驱动文件看，只有此函数会对 `rx_errors` 递增（`cp->dev->stats.rx_errors++`），也即说明 `RX errors` 包含的错误类型大都在此函数内。

> 不过，也有部分错误调用了本函数，见 [这里](https://github.com/torvalds/linux/blob/v5.8/drivers/net/ethernet/realtek/8139cp.c#L496-L503)

错误类型包括：

- rx_frame_errors（对应 `ifconfig` 的 [frame](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/lib/interface.c#L915-L917)）
- rx_crc_errors（不对应 `ifconfig` 的任何字段）
- rx_length_errors（不对应 `ifconfig` 的任何字段）
- rx_fifo_errors（对应 `ifconfig` 的 [overruns](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/lib/interface.c#L915-L917)）

> 这些错误类型可能因不同网卡而不同

错误类型 [不一定](https://github.com/torvalds/linux/blob/v5.8/drivers/net/ethernet/realtek/8139cp.c#L496-L503) 包括：

- rx_dropped（对应 `ifconfig` 的 [dropped](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/lib/interface.c#L915-L917)）
- 因为 `dropped` 有 3 出来源：[01](https://github.com/torvalds/linux/blob/v5.8/drivers/net/ethernet/realtek/8139cp.c#L496-L497) + [02](https://github.com/torvalds/linux/blob/v5.8/drivers/net/ethernet/realtek/8139cp.c#L512) + [03](https://github.com/torvalds/linux/blob/v5.8/drivers/net/ethernet/realtek/8139cp.c#L519)

### `TX` 的 `errors` 指哪些错误？

同样，以此网卡驱动为例 [`drivers/net/ethernet/realtek/8139cp.c`](https://github.com/torvalds/linux/blob/v5.8/drivers/net/ethernet/realtek/8139cp.c#L672-L684)：

```c
...
if (status & (TxError | TxFIFOUnder)) {
	netif_dbg(cp, tx_err, cp->dev,
		  "tx err, status 0x%x\n", status);
	cp->dev->stats.tx_errors++;
	if (status & TxOWC)
		cp->dev->stats.tx_window_errors++;
	if (status & TxMaxCol)
		cp->dev->stats.tx_aborted_errors++;
	if (status & TxLinkFail)
		cp->dev->stats.tx_carrier_errors++;
	if (status & TxFIFOUnder)
		cp->dev->stats.tx_fifo_errors++;
} else {
...
```

从此驱动文件看，只有此处会对 `tx_errors` 递增（`cp->dev->stats.tx_errors++`），也即说明 `TX errors` 包含的错误类型都在此函数内。

错误类型包括：

- tx_window_errors（不对应 `ifconfig` 的任何字段）
- tx_aborted_errors（不对应 `ifconfig` 的任何字段）
- tx_carrier_errors（对应 `ifconfig` 的 [carrier](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/lib/interface.c#L930-L933)）
- tx_fifo_errors（对应 `ifconfig` 的 [overruns](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/lib/interface.c#L930-L933)）

> 这些错误类型可能因不同网卡而不同

错误类型不包括：

- tx_dropped（对应 `ifconfig` 的 [dropped](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/lib/interface.c#L930-L933)）

> TODO：[为什么](https://github.com/torvalds/linux/blob/v5.8/drivers/net/ethernet/realtek/8139cp.c#L685-L687) collisions++ 时，也同时 tx_packets++？按理说 collisions 不是代表错误了吗？

### `dropped`与`overruns`的区别

`dropped` 与 `overruns` 是指两种不同的丢包情况。

要了解两者的区别，需首先了解 Linux 内核中的 [网络数据流转机制](https://plantegg.github.io/2019/05/08/%E5%B0%B1%E6%98%AF%E8%A6%81%E4%BD%A0%E6%87%82%E7%BD%91%E7%BB%9C--%E7%BD%91%E7%BB%9C%E5%8C%85%E7%9A%84%E6%B5%81%E8%BD%AC/)。

以接收数据为例：

1. 网卡驱动在内存中分配一片缓冲区用来接收数据包，叫做 sk_buff
1. 将上述缓冲区的地址和大小（即接收描述符），加入到 rx ring buffer。描述符中的缓冲区地址是 DMA 使用的物理地址
1. 驱动通知网卡有一个新的描述符
1. 网卡从 rx ring buffer 中取出描述符，从而获知缓冲区的地址和大小
1. 网卡收到新的数据包;
1. 网卡将新数据包通过 DMA 直接写到 sk_buff 中

注意，上述流程有几个可能容易模糊的概念：

- 网卡驱动：这是跑在 Linux 中的程序，而非跑在网卡硬件中
- [sk_buff](#sk_buff)：存在于 Linux 内存中，可以在不同的网络协议层之间传递（在 Linux 源码中的定义见 [`skbuff.h`](https://github.com/torvalds/linux/blob/v5.8/include/linux/skbuff.h)），sk_buff 是真正存放网络数据的位置
- rx ring buffer：是一个 [FIFO（先进先出）队列](<https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics)>)，队列的内容并不是真正的网络数据，而是一些指向 sk_buff 的描述符

再次看下这个图可能会更清晰：

![](https://i.stack.imgur.com/HignO.png)

> [↑ 接收数据时：Linux 网络 Ring Buffer、Socket Buffer 与网卡（NIC）的关系](https://stackoverflow.com/a/59491902/2752670)

了解上述流程后，可以开始说两者的区别了：

- `dropped`：sk_buff 满了，新的数据写不进 sk_buff 导致的丢包
  - 可能原因之一：Linux 系统内存不足，[导致从网卡拷贝数据到系统内存时丢包](https://plantegg.github.io/2019/05/08/%E5%B0%B1%E6%98%AF%E8%A6%81%E4%BD%A0%E6%87%82%E7%BD%91%E7%BB%9C--%E7%BD%91%E7%BB%9C%E5%8C%85%E7%9A%84%E6%B5%81%E8%BD%AC/#ifconfig-%E7%9B%91%E6%8E%A7%E6%8C%87%E6%A0%87)
- `overruns`：ring buffer 队列满了，队列暂无可用的描述符，导致的丢包。在 ifconfig 源码实际就是 [rx_fifo_errors（recv'r fifo overrun）](https://github.com/giftnuss/net-tools/blob/9446c4dd69fe5bc1c1de403039b9565fca9e4273/lib/interface.c#L915-L917)
  - 可能原因之一：CPU 很忙无法及时处理网卡申请的中断
- 总之，大概可理解为，一个是指针满了（overruns），一个是内存满了（dropped）

ring buffer 满了不代表 buffer 满了，可能是因为每个指针指向的 buffer 数据都很小；sk_buff 满了也不代表 ring buffer 满了，可能是因为每个指针指向的 buffer 数据较大（待验证）。

`dropped` 与 `overruns` 的共同点：

- 都是指丢包相关的错误
- 单位都是 [sk_buff](http://vger.kernel.org/~davem/skb.html)
- 接收数据、发送数据都可能出现这两种错误

### `bytes 20960261647 (19.5 GiB)` 是否包含各层协议 Header？

答：包含。

理由：

以此网卡驱动为例，[`drivers/net/ethernet/realtek/8139cp.c` L425-L426](https://github.com/torvalds/linux/blob/v5.8/drivers/net/ethernet/realtek/8139cp.c#L425-L426)：

> 这是统计 `bytes` 值的代码，用的是 sk_buff 的 `len`

```c
cp->dev->stats.rx_packets++;
cp->dev->stats.rx_bytes += skb->len;
```

↓

[`include/linux/skbuff.h` L2095-L2098](https://github.com/torvalds/linux/blob/v5.8/include/linux/skbuff.h#L2095-L2098)：

> 从 headerlen 的来源侧面反映 [skb->len](https://github.com/torvalds/linux/blob/v5.8/include/linux/skbuff.h#L626) 包含 header 的大小，真正网络数据是 [skb->data_len](https://github.com/torvalds/linux/blob/v5.8/include/linux/skbuff.h#L627)

```c
static inline unsigned int skb_headlen(const struct sk_buff *skb)
{
	return skb->len - skb->data_len;
}
```

> 而 [skb->truesize](https://github.com/torvalds/linux/blob/v5.8/include/linux/skbuff.h#L706) 指的是 sk_buff 这个结构本身占的内存大小

参考：

- [skb->truesize，len，datalen，size，等的区别？](http://blog.chinaunix.net/uid-26029760-id-1746557.html)
- [How SKBs work - Kernel.org](http://vger.kernel.org/~davem/skb_data.html)

# 综合参考

- [《Understanding Linux Network Internals》2006](https://doc.lagout.org/operating%20system%20/linux/Understanding%20Linux%20Network%20Internals.pdf)
- [可互动操作的各层协议地图](http://www.023wg.com/message/message/cd_feature_cover.html)
- ifconfig 各字段解释 - [The Missing Man Page for ifconfig](http://blog.hyfather.com/blog/2013/03/04/ifconfig/)
- ifconfig 各字段解释 - [Demystifying ifconfig and network interfaces in Linux](https://goinbigdata.com/demystifying-ifconfig-and-network-interfaces-in-linux/)
- 网络收包过程详述 - [Redis 高负载下的中断优化](https://www.infoq.cn/article/ux4U1GAidcMtVj8t8XXG)
- 多图含代码 - [网卡收包流程](https://cloud.tencent.com/developer/article/1030881)
- Linux 网络栈的相关队列机制 - [Queueing in the Linux Network Stack](https://www.coverfire.com/articles/queueing-in-the-linux-network-stack/)
- `ping` 命令基于 [ICMP 协议](https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol)，而 ICMP 报文是封装在 IP 包里面 - [20 张图解： ping 的工作原理](https://zhuanlan.zhihu.com/p/116902722)
