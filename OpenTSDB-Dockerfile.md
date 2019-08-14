# 背景
- 发现现有大部分 `OpenTSDB` 的 `Dockerfile` 镜像都包含 `HBase` 组件，也在的业务需求需要一个无状态的 `OpenTSDB` 节点，因此打算自己重写一个 `Dockerfile` 只包含 `Java` 等基础环境。
- 官方自己也有 `Dockerfile` 但是 `Dockerfile` 的 `Build` 依赖已经编译好的产物，本身需要一套能编译 `OpenTSDB` 环境，特别其依赖的 `gnuplot` 组件，还需要 `make` 源码编译。

# 改动说明
1. 当前默认编译打包最新的  `OpenTSDB Release 2.4.0` 版本，如果需要打包其他版本需要更改 `Dockerfile`
2. 当前只测试了 `Build OpenTSDB Release 2.4.0` 版本，理论上其他版本也能编译，但是未测试
3. 镜像 `Build` 的过程是直接从官方 `GitHub` 拉取指定版本代码和基础环境所需要的依赖，依据网速不同整个 Build 过程大概10分钟左右
4. 可直接导出配置配置文件，自己定义配置文件后使用自己的配置文件启动，一个例子如下： 

```bash
$ docker run --rm zealzhang/opentsdb:2.4.0 cat /etc/opentsdb/opentsdb.conf > opentsdb.conf
```
5. 必须修改配置 `tsd.storage.hbase.zk_quorum` 配置为自己的配置，因为镜像只包含 `opentsdb`，不包含 `HBase`，`Zookeeper`，`HDFS` 等其他组件，同时要保证 `Docker` 容器和 `Zookeeper` 服务网络是通的
6. 默认添加了 `tsd.http.request.enable_chunked = true` 和 `tsd.http.request.max_chunk = 655350` 两个配置。一个配置如下（只列出部分）：

```conf
tsd.http.request.enable_chunked = true
tsd.http.request.max_chunk = 655350
tsd.storage.hbase.zk_quorum = 10.201.12.66
```
7. 添加了配置文件和 `log` 的宿主机卷挂载点，镜像内默认使用 `/opentsdb` 挂载点，日志会自动写到该目录下面，自定义的配置也放下面，一个启动命令例子：

```bash
docker run -dp 4242:4242 \
-v /xxx/myopentsdb:/opentsdb \
zealzhang/opentsdb:2.4.0 tsdb tsd --config=/opentsdb/opentsdb.conf
```
把自定义后的配置文件放到 `/xxx/myopentsdb` 下，通过以上命令容器就能加载到配置文件，日志也会写到该目录下面，成功运行后目录结构如下：

```bash
.
├── log
│   ├── opentsdb.log
│   └── queries.log
└── opentsdb.conf
```
8. 目前容器内只使用了一个卷挂载点，并未区分日志和配置文件或其他数据，也就是说目前日志的路径是固定的，如需要自定义不同的目录需要更改 `Dockerfile` 重新构建镜像，同时日志配置文件 `logback.xml` 当前页未暴露出来。
9. 因为源码编译安装后，世界的产物位置是在 `/usr/local/share/opentsdb`，为了和官网文档安装的路径一致，做了一些软链接，如下：

```bash
# 包含两个配置文件opentsdb.conf 和 logback.xml
ln -s /usr/local/share/opentsdb/etc/opentsdb /etc
# 相关的静态文件
ln -s /usr/local/share/opentsdb/static  /usr/share/opentsdb
```
以上启动命令 `opentsdb.conf` 配置使用的是我们自定义的配置，`logback.xml` 配置使用的是 `/usr/local/share/opentsdb/etc/opentsdb` 下面的配置
10. 为了更改log的默认目录，构建镜像的时候做了 `logback.xml` 字符串替换如下，更改了默认 `log` 的位置，否则会报未设置日志路径：

```bash
    sed -i 's,${LOG_FILE},/opentsdb/log/opentsdb.log,g' /etc/opentsdb/logback.xml
    sed -i 's,${QUERY_LOG},/opentsdb/log/queries.log,g' /etc/opentsdb/logback.xml
```
11. 当前打好镜像显示 399M 似乎比官方 Snapshot 版本小，如下：

```bah
$ docker images 
REPOSITORY                                 TAG                 IMAGE ID            CREATED             SIZE
zealzhang/opentsdb                         2.4.0               e9b420444d32        32 minutes ago      399MB
```

# 参考资料
- [OpenTSDB-Dockerfile](https://github.com/PeterGrace/opentsdb-docker/blob/master/Dockerfile)
- [Officail-Dockerfile](https://github.com/OpenTSDB/opentsdb/blob/master/tools/docker/Dockerfile)