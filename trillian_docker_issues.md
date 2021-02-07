# Trillian Docker 安装记录

文章：

https://medium.com/google-cloud/google-trillian-for-noobs-9b81547e9c4a

# 目录

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [坑：执行 docker-compose 前应先停止之前启动的 database](#%E5%9D%91%E6%89%A7%E8%A1%8C-docker-compose-%E5%89%8D%E5%BA%94%E5%85%88%E5%81%9C%E6%AD%A2%E4%B9%8B%E5%89%8D%E5%90%AF%E5%8A%A8%E7%9A%84-database)
- [坑：adminer 应使用 server：db、user：test、password：zaphod](#%E5%9D%91adminer-%E5%BA%94%E4%BD%BF%E7%94%A8-serverdbusertestpasswordzaphod)
- [坑：LOGID 生成问题](#%E5%9D%91logid-%E7%94%9F%E6%88%90%E9%97%AE%E9%A2%98)
- [坑：demo 启动问题](#%E5%9D%91demo-%E5%90%AF%E5%8A%A8%E9%97%AE%E9%A2%98)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 坑：执行 docker-compose 前应先停止之前启动的 database

```sh
docker stop database
```

# 坑：adminer 应使用 server：db、user：test、password：zaphod

# 坑：LOGID 生成问题

```
RPCS=8090
LOGID=$(\
  go run github.com/google/trillian/cmd/createtree \
  --admin_server=:${RPCS} \
) && echo ${LOGID}
```

应修改为：

```
RPCS=8090
LOGID=$(\
  go run github.com/google/trillian/cmd/createtree \
  --admin_server=127.0.0.1:${RPCS} \
) && echo ${LOGID}
```

# 坑：demo 启动问题

```
go run github.com/DazWilkin/simple-trillian-log-1 \
--tlog_endpoint=:8090 \
--tlog_id=${LOGID}
```

应修改为：

```
go run github.com/DazWilkin/simple-trillian-log-1 \
--tlog_endpoint=127.0.0.1:8090 \
--tlog_id=${LOGID}
```

此外，demo 内有一处简单问题，根据报错提示简单修改下即可。
