FROM fluent/fluentd:v1.20.1-1.0
ENV LOG_LEVEL="warn"
ENV BASE_URI="https://log-api.newrelic.com/log/v1"

USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential ruby-dev \
 && fluent-gem install fluent-plugin-newrelic \
 && gem sources --clear-all \
 && apt-get purge -y --auto-remove build-essential ruby-dev \
 && rm -rf /var/lib/apt/lists/* /home/fluent/.gem/ruby/*/cache/*.gem

COPY fluent.conf /fluentd/etc/
COPY entrypoint.sh /bin/

USER fluent
