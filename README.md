# Supported tags and respective Dockerfile links
[2.4.0](https://github.com/zealzhangz/opentsdb-docker/blob/master/Dockerfile)

# OpenTSDB
## Abstract
This image just include OpenTSDB and Java 1.8 basic env, without Zookeeper、HBase、HDFS。Before starting the container, you must ensure that the available HBase services are started,and [OpenTSDB's](http://opentsdb.net/docs/build/html/index.html) [create_table.sh](http://opentsdb.net/docs/build/html/installation.html#id1) has been excuted. 

## Configuration
Generate and customize configuration files

```bash
$ docker run --rm zealzhangz/opentsdb:2.4.0 cat /etc/opentsdb/opentsdb.conf > opentsdb.conf
# edit conf
vim opentsdb.conf
# available zookeeper services
tsd.storage.hbase.zk_quorum = 10.201.12.66
```
## Running this Image

```bah
docker run -dp 4242:4242 \
-v /xxx/myopentsdb:/opentsdb \
zealzhangz/opentsdb:2.4.0 tsdb tsd --config=/opentsdb/opentsdb.conf
```

## Exposed Ports
- 4242 HTTP API/Web port

Update the port by opentsdb.conf


## Testing
- Test by browser

```bash
http://127.0.0.1:4242/
```
- Test by API 

```bash
# Writing a point
curl -i -X POST -d '{"metric":"wind.UC_ResetAlarms6","timestamp":1565771210142,"tags":{"arch":"x64","datacenter":"ap-northeast-1a","hostname":"host_0","os":"Ubuntu15.10","rack":"72","region":"ap-northeast-1"},"value":33.466028797961954}' http://127.0.0.1:4242/api/put?summary
# Response
HTTP/1.1 200 OK
Content-Type: application/json; charset=UTF-8
Content-Length: 24

{"success":1,"failed":0}% 
# Querying test
curl  -X POST -d '{"start":1565771210042,"end":1565771210146,"msResolution":true,"queries":[{"aggregator":"none","metric":"wind.UC_ResetAlarms6","tags":{"arch":"x64"}}]}' http://127.0.0.1:4242/api/query 
# Response
[{"metric":"wind.UC_ResetAlarms6","tags":{"hostname":"host_0","rack":"72","os":"Ubuntu15.10","datacenter":"ap-northeast-1a","arch":"x64","region":"ap-northeast-1"},"aggregateTags":[],"dps":{"1565771210142":33.466028797961954}}]
```

## Log
Logs are written to /opentsdb/log by default，you can mount own volumn to check logs.

```bash
# Container
tree /opentsdb
.
├── log
│   ├── opentsdb.log
│   └── queries.log
└── opentsdb.conf
```