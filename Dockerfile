FROM alpine:3.23
ENV LOG_LEVEL="warn"
ENV BASE_URI="https://log-api.newrelic.com/log/v1"
ENV FLUENTD_CONF="fluent.conf"

# Alpine 3.23 provides ruby 3.4.13-r0. The version constraint fails the build if the package is older.
RUN apk add --no-cache --update \
        'ruby>=3.4.13-r0' ruby-bigdecimal ruby-webrick tini libffi \
 && apk add --no-cache --update --virtual .build-deps \
        build-base ruby-dev linux-headers \
 && gem install --no-document fluentd yajl-ruby fluent-plugin-newrelic \
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
