<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [shell 输入长命令后，如何用 vim 快捷键修改中间文字？](#shell-%E8%BE%93%E5%85%A5%E9%95%BF%E5%91%BD%E4%BB%A4%E5%90%8E%E5%A6%82%E4%BD%95%E7%94%A8-vim-%E5%BF%AB%E6%8D%B7%E9%94%AE%E4%BF%AE%E6%94%B9%E4%B8%AD%E9%97%B4%E6%96%87%E5%AD%97)
- [太长不想看，看这句](#%E5%A4%AA%E9%95%BF%E4%B8%8D%E6%83%B3%E7%9C%8B%E7%9C%8B%E8%BF%99%E5%8F%A5)
- [前提](#%E5%89%8D%E6%8F%90)
- [疑问](#%E7%96%91%E9%97%AE)
- [切换为 vi 模式](#%E5%88%87%E6%8D%A2%E4%B8%BA-vi-%E6%A8%A1%E5%BC%8F)
- [默认：emacs 模式](#%E9%BB%98%E8%AE%A4emacs-%E6%A8%A1%E5%BC%8F)
- [shell vi 模式快捷键（推荐）](#shell-vi-%E6%A8%A1%E5%BC%8F%E5%BF%AB%E6%8D%B7%E9%94%AE%E6%8E%A8%E8%8D%90)
- [问题：是否影响原来 shell 操作？](#%E9%97%AE%E9%A2%98%E6%98%AF%E5%90%A6%E5%BD%B1%E5%93%8D%E5%8E%9F%E6%9D%A5-shell-%E6%93%8D%E4%BD%9C)
- [bash、zsh 的开启方式是否一致？](#bashzsh-%E7%9A%84%E5%BC%80%E5%90%AF%E6%96%B9%E5%BC%8F%E6%98%AF%E5%90%A6%E4%B8%80%E8%87%B4)
- [值得看一下的相关小文](#%E5%80%BC%E5%BE%97%E7%9C%8B%E4%B8%80%E4%B8%8B%E7%9A%84%E7%9B%B8%E5%85%B3%E5%B0%8F%E6%96%87)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# shell 输入长命令后，如何用 vim 快捷键修改中间文字？

> 准确是 vi 模式



# 太长不想看，看这句
- 执行 `set -o vi` 即可开启 shell 的 vi 模式，使用 vi 的快捷键修改已输入的命令文字。
- 执行 `set -o emacs` 即可回到 shell 的默认模式（即退出 vi 模式）

> 对 Vim 越熟悉，越好用



# 前提
本文适用于对 vi/vim 快捷键有了解的人。

> 若不熟悉，可能一时也难记住



# 疑问
在 Linux shell 输入长命令，想修改中间某些字，原始方式：按键盘的左右方向键。

缺点：慢，按 1 次只能移动 1 个字符。

曾想：习惯使用 Vim，若 shell 命令编辑也能用 Vim 快捷键该多好。

最近：才发现，bash 本来就自带了 vi 模式！还不用额外安装软件！只是默认不是 vi 模式而已。



# 切换为 vi 模式
立即生效（临时）：

- 执行命令 `set -o vi` 即可
- 输入命令时按下 `esc` 键即可进入 vi 模式
- 哒 ~ nice！


永久生效：

- 将 `set -o vi` 放到对应 shell 的配置文件（bash：`~/.bash_profile`；zsh：`~/.zshrc`）
- `source 配置文件` 或新开命令窗可生效
- 查看 shell 类型（[`echo $0`](https://askubuntu.com/a/590902/1042664)）


特点：
- 全程不用额外安装任何软件
- `set -o vi` 同样适用于 zsh
- 不想用 vi 模式，想临时切换回默认模式：`set -o emacs`（shell 默认就是 emacs 模式）



# 默认：emacs 模式
[没接触过的人和新手可能没有意识到 bash shell 的默认输入模式是 Emacs 模式](https://linux.cn/article-8372-1.html) 。

默认模式与此命令等价：`set -o emacs` 。

shell 默认的 emacs 模式，本来也有不少快捷键，可能大家熟悉的不多：参考 [emacs 快捷键](https://www.smartfile.com/blog/bash-shortcuts-for-the-command-line-emacs/)。



# shell vi 模式快捷键（推荐）
见此文：[How To Use Vim Mode On The Command Line In Bash](https://dev.to/brandonwallace/how-to-use-vim-mode-on-the-command-line-in-bash-fnn) 。

- 列举了详细的快捷键
- 有 gif 动态演示



# 问题：是否影响原来 shell 操作？
答：正常输入时，若不按 `esc` 则与原输入方式一致（原 `Ctrl + l` 清屏快捷键，在 bash 会失效，在 zsh 依然没问题，[参考](https://unix.stackexchange.com/questions/104094/is-there-any-way-to-enable-ctrll-to-clear-screen-when-set-o-vi-is-set)）。

Normal、Insert 的切换方式：

- 按 `esc` 键，才会进入 Normal 模式
- 按 `i` 键，可从 Normal 回到 Insert 输入模式



# bash、zsh 的开启方式是否一致？
答：可一致，也可不一致。

zsh 的开启方式（n 选一即可）：

```sh
# 可执行，也可放到 ~/.zshrc
set -o vi
```

或

```sh
# 可执行，也可放到 ~/.zshrc
bindkey -v
```

或在 `~.zshrc` 添加：

```sh
plugins=(git vi-mode)
```

> 可能默认是 `plugins=(git)` ，改成 `plugins=(git vi-mode)`

参考：https://stackoverflow.com/questions/58187542/how-to-setup-vi-editing-mode-for-zsh



# 值得看一下的相关小文
- [译：如何在 Bash 命令行中使用 Vi 模式](https://github.com/vikyd/note/blob/master/bash_vi_mode.md)
- [在 shell 中使用 vi 模式](https://linux.cn/article-8372-1.html)


