# Trillian Docker 安装记录

文章：

https://medium.com/google-cloud/google-trillian-for-noobs-9b81547e9c4a

# 目录

<!--ts-->
   * [Trillian Docker 安装记录](#trillian-docker-安装记录)
   * [目录](#目录)
   * [坑：执行 docker-compose 前应先停止之前启动的 database](#坑执行-docker-compose-前应先停止之前启动的-database)
   * [坑：adminer 应使用 server：db、user：test、password：zaphod](#坑adminer-应使用-serverdbusertestpasswordzaphod)
   * [坑：LOGID 生成问题](#坑logid-生成问题)
   * [坑：demo 启动问题](#坑demo-启动问题)


<!--te-->

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
