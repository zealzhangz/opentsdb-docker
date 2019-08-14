FROM java:openjdk-8-alpine

ENV       TSDB_VERSION 2.4.0
ENV       GNUPLOT_VERSION 5.2.4
ENV       WORKDIR /usr/share/opentsdb
ENV       BUILD_PACKAGES "build-base autoconf automake python"
ENV       CONFIG /etc/opentsdb/opentsdb.conf


# Add the base packages we'll need
RUN apk --update add apk-tools \
    && apk add bash \
    && apk add make \
    && apk add wget \
    && mkdir -p ${WORKDIR}

WORKDIR ${WORKDIR}

# Add build deps, build opentsdb, and clean up afterwards.

RUN apk add --virtual builddeps \
    ${BUILD_PACKAGES} \
  && : Install OpenTSDB and scripts \
  && wget --no-check-certificate \
    -O v${TSDB_VERSION}.zip \
    https://github.com/OpenTSDB/opentsdb/archive/v${TSDB_VERSION}.zip \
  && unzip v${TSDB_VERSION}.zip \
  && rm v${TSDB_VERSION}.zip \
  && cd ${WORKDIR}/opentsdb-${TSDB_VERSION} \
  && ./build.sh \
  && cp build-aux/install-sh build/build-aux \
  && cd build \
  && make install \
  && cd / \
  && rm -rf ${WORKDIR}/opentsdb-${TSDB_VERSION}

RUN cd /tmp && \
wget https://datapacket.dl.sourceforge.net/project/gnuplot/gnuplot/${GNUPLOT_VERSION}/gnuplot-${GNUPLOT_VERSION}.tar.gz \
&& tar xzf gnuplot-${GNUPLOT_VERSION}.tar.gz \
&& cd gnuplot-${GNUPLOT_VERSION} \
&& ./configure \
&& make install \
&& cd /tmp && rm -rf /tmp/gnuplot-${GNUPLOT_VERSION} && rm /tmp/gnuplot-${GNUPLOT_VERSION}.tar.gz

VOLUME    ["/opentsdb"]
# 4242 for tsdb
EXPOSE 4242

RUN apk del builddeps && rm -rf /var/cache/apk/*  

# link to default configuration dir
RUN mkdir -p ${WORKDIR}/plugins \
    && ln -s /usr/local/share/opentsdb/etc/opentsdb /etc \
    && ln -s /usr/local/share/opentsdb/static  ${WORKDIR} \
    # update log dir to /opentsdb
    && sed -i 's,${LOG_FILE},/opentsdb/log/opentsdb.log,g' /etc/opentsdb/logback.xml \
    && sed -i 's,${QUERY_LOG},/opentsdb/log/queries.log,g' /etc/opentsdb/logback.xml \
    # default config
    && echo "tsd.http.request.enable_chunked = true" >> ${CONFIG} \
    && echo "tsd.http.request.max_chunk = 655350" >> ${CONFIG}