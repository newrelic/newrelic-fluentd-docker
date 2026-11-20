FROM alpine:3.23
ENV LOG_LEVEL="warn"
ENV BASE_URI="https://log-api.newrelic.com/log/v1"
ENV FLUENTD_CONF="fluent.conf"

# Custom Alpine build (replaces the fluent/fluentd base image) to pin
# Ruby >=3.4.13 - no fluent/fluentd tag ships it.
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
