<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [inotifywait 监控 Vim 编辑新文件时产生的临时文件 swp、swpx 等以及相关操作](#inotifywait-%E7%9B%91%E6%8E%A7-vim-%E7%BC%96%E8%BE%91%E6%96%B0%E6%96%87%E4%BB%B6%E6%97%B6%E4%BA%A7%E7%94%9F%E7%9A%84%E4%B8%B4%E6%97%B6%E6%96%87%E4%BB%B6-swpswpx-%E7%AD%89%E4%BB%A5%E5%8F%8A%E7%9B%B8%E5%85%B3%E6%93%8D%E4%BD%9C)
- [使用](#%E4%BD%BF%E7%94%A8)
- [只监控 `modify,delete,create` 操作](#%E5%8F%AA%E7%9B%91%E6%8E%A7-modifydeletecreate-%E6%93%8D%E4%BD%9C)
- [监全部操作](#%E7%9B%91%E5%85%A8%E9%83%A8%E6%93%8D%E4%BD%9C)
- [参考](#%E5%8F%82%E8%80%83)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# inotifywait 监控 Vim 编辑新文件时产生的临时文件 swp、swpx 等以及相关操作
结论：从文件的增删改（`create,delete,modify`）监控监督可见：Vim 编辑新文件并并保存这样的简单操作的背后，内部发生了不少操作：自动创建了 `.b.swp`、`.b.swpx`，之后又删除了，又重新创建 `.b.swp` 等。

> 本文起因：

- 尝试用 inotifywait 监控 nginx 容器中的配置目录变化后自动 reload nginx
- 并允许临时用 Vim 编辑配置文件，但发现 Vim 并未开始保存，inotifywait 已开始出发 nginx reload
- 但即使 exclude 了 `swp`，inotifywait 也依然会在 Vim 保存文件前触发 reload
- 曾一度怀疑 inotifywait 的 exclude 参数不生效
- 最后发现，原来 Vim 还另外产生了 `.swpx` 文件，并且 `.swpx` 只存在了一小段时间（保存 Vim 的编辑文件前）就被自动删了



# 使用

- 前提：
  - `/data/` 目录存在，且目录为空
  - `/data/b` 文件不存在
- 对 `/data` 目录开始 `inotifywait` 监控：

```sh
#!/bin/bash
inotifywait -mrq -e modify,delete,create /data/ | 
while read event; do
    echo $event
done
```
- `vim /data/b` 开始编辑
- 输入 `i` 进入编辑模式，填入内容 `1`
- `:wq` 退出


# 只监控 `modify,delete,create` 操作

下面是 `inotifywait` 监控得到的内部操作过程（事件：`-e modify,delete,create`）：

```
/data/ CREATE .b.swp
/data/ CREATE .b.swpx
/data/ DELETE .b.swpx
/data/ DELETE .b.swp
/data/ CREATE .b.swp
/data/ MODIFY .b.swp
/data/ MODIFY .b.swp
/data/ CREATE b
/data/ MODIFY b
/data/ MODIFY .b.swp
/data/ DELETE .b.swp
```



# 监全部操作
下面是 `inotifywait` 监控得到的内部操作过程（所有事件，即不带 `-e` 参数）：

```
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ CREATE .b.swp
/data/ OPEN .b.swp
/data/ CREATE .b.swpx
/data/ OPEN .b.swpx
/data/ CLOSE_WRITE,CLOSE .b.swpx
/data/ DELETE .b.swpx
/data/ CLOSE_WRITE,CLOSE .b.swp
/data/ DELETE .b.swp
/data/ CREATE .b.swp
/data/ OPEN .b.swp
/data/ MODIFY .b.swp
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ OPEN,ISDIR
/data/ CLOSE_NOWRITE,CLOSE,ISDIR
/data/ MODIFY .b.swp
/data/ MODIFY .b.swp
/data/ CREATE b
/data/ OPEN b
/data/ MODIFY b
/data/ CLOSE_WRITE,CLOSE b
/data/ MODIFY .b.swp
/data/ CLOSE_WRITE,CLOSE .b.swp
/data/ DELETE .b.swp
```

# 参考
- [Vim 官方文档：swap-file](https://vimhelp.org/recover.txt.html#swap-file)
