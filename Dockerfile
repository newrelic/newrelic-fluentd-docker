FROM alpine:3.23
ENV LOG_LEVEL="warn"
ENV BASE_URI="https://log-api.newrelic.com/log/v1"
ENV FLUENTD_CONF="fluent.conf"

# Alpine 3.23 provides ruby 3.4.13-r0. The version constraint fails the build
# if the package is older.
#
# This replaces the fluent/fluentd base image (used until now) with a
# from-scratch Alpine build so we can control the Ruby version directly:
# no current fluent/fluentd tag ships Ruby >=3.4.13, and Fluentd dropped
# Alpine support upstream at v1.19 so there is no official Alpine image for
# any maintained Fluentd version.
#
# amd64 only: this is a published single-arch (amd64) image today, with no
# multi-arch manifest, so this isn't a new limitation. The same recipe
# currently fails to build on arm64 (zstd-ruby's bundled libzstd hits a
# musl "fortify" PATH_MAX compile error that doesn't occur on glibc/amd64) -
# tracked as a follow-up, not blocking here since arm64 was never supported.
RUN apk add --no-cache --update \
        'ruby>=3.4.13-r0' ruby-bigdecimal ruby-webrick tini libffi \
 && apk upgrade --no-cache \
 && apk add --no-cache --update --virtual .build-deps \
        build-base ruby-dev linux-headers \
 && gem install --no-document \
        'fluentd:1.20.1' \
        'yajl-ruby:1.4.3' \
        'fluent-plugin-newrelic:1.2.3' \
 && gem sources --clear-all \
 && apk del .build-deps \
 && rm -rf /root/.gem /usr/lib/ruby/gems/*/cache/*.gem \
 && addgroup -S fluent \
 && adduser -S -G fluent -h /home/fluent fluent \
 && mkdir -p /fluentd/log /fluentd/etc /fluentd/plugins \
 && chown -R fluent:fluent /fluentd

COPY fluent.conf /fluentd/etc/
COPY entrypoint.sh /bin/

USER fluent
ENTRYPOINT ["tini", "--", "/bin/entrypoint.sh"]
CMD ["fluentd"]
