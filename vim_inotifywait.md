# inotifywait 监控 Vim 编辑新文件时产生的临时文件 swp、swpx 等以及相关操作

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

从文件的增删改（`create,delete,modify`）监控监督可见，虽然是简单的 Vim 编辑新文件操作，但内部却发生了不少操作：创建了 `.b.swp`、`.b.swpx`，之后又删除了，又重新创建 `.b.swp` 等。



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
