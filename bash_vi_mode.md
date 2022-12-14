<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [译注](#%E8%AF%91%E6%B3%A8)
- [标题：如何在 Bash 命令行中使用 Vi 模式](#%E6%A0%87%E9%A2%98%E5%A6%82%E4%BD%95%E5%9C%A8-bash-%E5%91%BD%E4%BB%A4%E8%A1%8C%E4%B8%AD%E4%BD%BF%E7%94%A8-vi-%E6%A8%A1%E5%BC%8F)
- [简介](#%E7%AE%80%E4%BB%8B)
- [Vim 爱好者的好消息](#vim-%E7%88%B1%E5%A5%BD%E8%80%85%E7%9A%84%E5%A5%BD%E6%B6%88%E6%81%AF)
- [移动](#%E7%A7%BB%E5%8A%A8)
- [Vi 模式的光标移动方式](#vi-%E6%A8%A1%E5%BC%8F%E7%9A%84%E5%85%89%E6%A0%87%E7%A7%BB%E5%8A%A8%E6%96%B9%E5%BC%8F)
- [编辑](#%E7%BC%96%E8%BE%91)
- [Vi 模式的文本编辑方式](#vi-%E6%A8%A1%E5%BC%8F%E7%9A%84%E6%96%87%E6%9C%AC%E7%BC%96%E8%BE%91%E6%96%B9%E5%BC%8F)
- [搜索](#%E6%90%9C%E7%B4%A2)
- [Vi 模式的搜索方式](#vi-%E6%A8%A1%E5%BC%8F%E7%9A%84%E6%90%9C%E7%B4%A2%E6%96%B9%E5%BC%8F)
- [小结](#%E5%B0%8F%E7%BB%93)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 译注
- 原标题：How To Use Vim Mode On The Command Line In Bash
- 原文：https://dev.to/brandonwallace/how-to-use-vim-mode-on-the-command-line-in-bash-fnn
- 作者：brandon_wallace
- 发表时间：2021-06-11，修改于 2022-12-12
- 翻译时间：2022-12-14
- 翻译原因：简单明了，有常用快捷键示例，还有动图演示


# 标题：如何在 Bash 命令行中使用 Vi 模式



# 简介
本文将聊下如何在 Bash 命令行中使用 Vi 模式。



# Vim 爱好者的好消息
你是否曾经在输入命令行时使用过 Vim 模式？

当我发现命令行可以启用 Vi 模式后，我总会在 `~/.bashrc` 中添加下面配置：

```sh
set -o vi
```

本文将涉及：

- 光标移动
- 命令编辑
- 搜索

默认情况下，Bash 命令行使用基于 Emacs 快捷键的模式，例如：

- `Ctrl + A`：跳转到一行开头
- `Ctrl + E`：跳转到一行结尾

下面是 Emacs 与 Vi 模式的快捷键简表：

```
Emacs  	Vi	含义
Ctrl+A	0	光标跳转到行头
Ctrl+E	$	光标跳转到行尾
Alt+B	b	光标向后跳转 1 个词
Alt+F	w	光标向前跳转 1 个词
Ctrl+B	h	光标向后跳转 1 个字符
Ctrl+F	l	光标向前跳转 1 个字符
Ctrl+P	k	向上搜索命令记录
Ctrl+R	j	向下搜索命令记录
```

添加下面这行到你的 `~/.bashrc` 文件中：

```sh
set -o vi
```

并 `source` 之，可立即生效：

```sh
$ source ~/.bashrc
```

添加配置，且 source 配置文件后，即可拥有一个 Vi 模式的 Bash 命令行了。

从此，你可在命令行中用上 Vi 的各种快捷键。

如果你本来就熟悉 Vim，肯定知道 Vim 的 Command 模式和 Insert 模式。Bash 的 Vi 默认进入的是 Insert 模式。

按下 `Esc` 键，才能进入 Normal 模式。

顺便提一下，我目前用的 Bash 版本是 `5.1.16`：

```sh
$ bash --version | head -1
GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)
```



# 移动
# Vi 模式的光标移动方式
Vim 有四个方向键 `h j k l`，在 Bash 的 Vi 模式中，`h`、`l` 用于左右移动。

首先，按下 `ESc` 键，进入 Normal 模式。

输入 `$`：跳转到行尾。

输入 `0`：跳转到行头。

![](https://res.cloudinary.com/practicaldev/image/fetch/s--gS5nqCaX--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_66%2Cw_880/https://i.postimg.cc/B6v7J6X8/move-to-end-of-line.gif)


`W` 以空格为分隔符跳转到下一个词。

![](https://res.cloudinary.com/practicaldev/image/fetch/s--n5Q0bKOG--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_66%2Cw_880/https://i.postimg.cc/PqdspBf1/move-to-next-word.gif)

`w` 跳转到下一个词或下一个特殊字符。

`B` 以空格为分隔符向后跳转到下一个词。

![](https://res.cloudinary.com/practicaldev/image/fetch/s--Z_tRQAtS--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_66%2Cw_880/https://i.postimg.cc/c4T5krdt/move-back-one-word.gif)

`b` 向后跳转一个词或特殊字符。

`^` 跳转到此行的第一个非空字符。

`f<字符>` 查找匹配的字符。

例如：`ft` 表示查找字符 `t`。

![](https://res.cloudinary.com/practicaldev/image/fetch/s--6VBs1QQD--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_66%2Cw_880/https://i.postimg.cc/dDMLqhtw/find-letter-t.gif)

`f"` 查找双引号 `"`。

`;` 按下分号，表示继续查找上次查找的字符。

`F<字符>` 向后查找字符。

例如：`Ft` 向后查找字符 `t`。

![](https://res.cloudinary.com/practicaldev/image/fetch/s--3xq-Dcm8--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_66%2Cw_880/https://i.postimg.cc/d1kCwPmR/find-letter-t-backwards.gif)

`F"` 向后查找双引号 `"`。

`;` 继续沿上次查找的方向查找同字符（译注：这里表示继续向后查找下一个 `"`）。



# 编辑
# Vi 模式的文本编辑方式
`x` 删除当前光标的字符。

`X` 向后删除字符（译注：类似普通编辑器中按下 `Backspace` 键）。

![](https://res.cloudinary.com/practicaldev/image/fetch/s--DMlSXrkf--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_66%2Cw_880/https://i.postimg.cc/FFykhZXL/delete-previous-character.gif)

`I` 进入 Insert 模式，并且光标跳转到行首。

`A` 进入 Insert 模式，并且光标跳转到行尾。

![](https://res.cloudinary.com/practicaldev/image/fetch/s--46Y-X0yA--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_66%2Cw_880/https://i.postimg.cc/02GYHvyh/append-to-end-of-line.gif)

`cc` 删除当前行，并进入 Insert 模式。

`ea` 跳转到当前词结尾，并进入 Insert 模式。

`y` 复制当前光标下的词（译注：貌似复制的是光标下的字符）。

`Y` 复制光标到行尾的内容。

`p` 或 `P` 粘贴刚复制的内容。

`r` 替换光标下的字符。

`R` 进入所谓替换模式。就像文档编辑器（如 Libreoffice 或 Microsoft Word）中按下 Insert 键后的效果（译注：每输入一个字符，都会往后替换一个字符）。

![](https://res.cloudinary.com/practicaldev/image/fetch/s--iBWZnsvy--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_66%2Cw_880/https://i.postimg.cc/Pq0hGmFV/replace-text.gif)

`.` 重复上个命令的动作。这是 Vim 中最好用的快捷键之一。

`u` 撤销编辑。可按多次，撤销多步。

`~` 转换光标下字符的大小写。

`dd` 或 `D` 删除当前行。

![](https://res.cloudinary.com/practicaldev/image/fetch/s--edw14fN3--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_66%2Cw_880/https://i.postimg.cc/KjCJxDMj/delete-whole-line.gif)

`dw` 删除光标下的词（译注：应是删除光标到词结尾）。

`d3w` 删除至：按下 3 次 `w` 可跳转到的位置。

`c2w` 修改 2 个词。即，删除 2 个词，并进入 Insert 模式。

`y2w` 复制 2 个词。

`xp` 交互相邻字符（译注：本质是先删当前字符，再粘贴到后一字符之后）。

![](https://res.cloudinary.com/practicaldev/image/fetch/s--vhFA8ZJV--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_66%2Cw_880/https://i.postimg.cc/Kzmf8WV1/transpose-letters.gif)



# 搜索
# Vi 模式的搜索方式
（译注：先按 `Esc` 进入到 Normal 模式）按斜杠 `/`，并输入你想搜索的内容，然后按下 `Enter` 键，即可查找曾经执行过的命令。

![](https://res.cloudinary.com/practicaldev/image/fetch/s--NzHOZ9GP--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_66%2Cw_880/https://i.postimg.cc/VLLYC9pp/vim-search.gif)

（译注：按下 `Enter` 后，可继续按 `j` 或 `k` 继续上下查找）



# 小结
如果你本来就喜欢用 Vim 编辑器，那你肯定会喜欢在命令行用上 Vim 的快捷键（尽管只支持部分快捷键）。

这是我的 [.vimrc](https://github.com/brandon-wallace/vimrc) 文件。

我的 [Github](https://github.com/brandon-wallace) 和 [DEV.to](https://dev.to/brandonwallace)。


> 原文链接：https://dev.to/brandonwallace/how-to-use-vim-mode-on-the-command-line-in-bash-fnn
