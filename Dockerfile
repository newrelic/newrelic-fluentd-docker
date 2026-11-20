# Fluentd 1.20.1 built on Ruby 3.4.13 (Ruby2Shell fix). This mirrors the upstream
# fluent/fluentd-docker-image v1.20/debian Dockerfile, with the base changed from
# ruby:3.4-slim to ruby:3.4.13-slim-trixie, because no published fluent/fluentd tag
# ships Ruby >= 3.4.13 yet. The New Relic output plugin is installed on top.
FROM ruby:3.4.13-slim-trixie

LABEL maintainer="Logging Integrations"
LABEL Description="Fluentd docker image with the New Relic output plugin"
LABEL Version="1.20.1"

ENV LOG_LEVEL="warn"
ENV BASE_URI="https://log-api.newrelic.com/log/v1"

# Do not split this into multiple RUN: a separate 'apt-get purge' layer would not shrink the image.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
            ca-certificates tini \
 && buildDeps=" \
      make gcc g++ libc-dev \
      wget bzip2 gnupg dirmngr \
    " \
 && apt-get install -y --no-install-recommends $buildDeps \
 && echo 'gem: --no-document' >> /etc/gemrc \
 && export MAKEFLAGS=-j$(nproc) \
 && gem install oj -v 3.17.3 \
 && gem install rexml -v 3.4.4 \
 && gem install async -v 2.24.0 \
 && gem install async-http -v 0.89.0 \
 && gem install yajl-ruby -v 1.4.3 \
 && gem install msgpack -v 1.8.5 \
 && gem install fluentd -v 1.20.1 \
 && gem install fluent-plugin-newrelic \
 && unset MAKEFLAGS \
 && export GEM_DIR=$(ruby -e 'puts Gem.dir') \
 && echo GEM_DIR=$GEM_DIR \
 && rm -rf $GEM_DIR/cache/*.gem \
 # Don't purge $GEM_DIR/gems/GEM/lib/GEM/ext because it might contain runtime .so (e.g json)
 && find $GEM_DIR -maxdepth 3 -type d -name test -or -name ext -or -name spec -or -name benchmark | xargs -r rm -rfv \
 && find $GEM_DIR -name "*.so" | xargs -r strip \
 && wget -O /tmp/jemalloc-5.4.0.tar.bz2 https://github.com/jemalloc/jemalloc/releases/download/5.4.0/jemalloc-5.4.0.tar.bz2 \
 && cd /tmp && tar -xjf jemalloc-5.4.0.tar.bz2 --no-same-owner && cd jemalloc-5.4.0/ \
 # Don't use MADV_FREE to reduce memory usage and improve stability
 # https://github.com/fluent/fluentd-docker-image/pull/350
 && (echo "je_cv_madv_free=no" > config.cache) && ./configure -C --with-lg-page=16 --disable-cxx --disable-static && make -j$(nproc) \
 && mv lib/libjemalloc.so.2 /usr/lib \
 && apt-get purge -y --auto-remove \
                  -o APT::AutoRemove::RecommendsImportant=false \
                  $buildDeps \
                  '*-dev' \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/* /var/tmp/*

RUN groupadd -r fluent && useradd -r -g fluent fluent \
    && mkdir -p /fluentd/log /fluentd/etc /fluentd/plugins \
    && chown -R fluent /fluentd && chgrp -R fluent /fluentd

COPY fluent.conf /fluentd/etc/
COPY entrypoint.sh /bin/

ENV FLUENTD_CONF="fluent.conf"
ENV LD_PRELOAD="/usr/lib/libjemalloc.so.2"
ENV MALLOC_CONF="dirty_decay_ms:400,muzzy_decay_ms:0,narenas:2,background_thread:true,thp:never,abort_conf:true"

EXPOSE 24224 5140

USER fluent
ENTRYPOINT ["tini", "--", "/bin/entrypoint.sh"]
CMD ["fluentd"]
