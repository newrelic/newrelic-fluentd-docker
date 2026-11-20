# The official fluent/fluentd image is Debian-based since the Alpine variant was dropped.
FROM fluent/fluentd:v1.19.4-debian-2.2

ENV LOG_LEVEL="warn"
ENV BASE_URI="https://log-api.newrelic.com/log/v1"

USER root

# Build deps are installed only to compile native gem extensions, then removed.
RUN BUILD_DEPS="build-essential ruby-dev" \
 && apt-get update \
 && apt-get install -y --no-install-recommends ${BUILD_DEPS} \
 && fluent-gem install --no-document fluent-plugin-newrelic -v 1.2.3 \
 && fluent-gem install --no-document msgpack -v '>= 1.8.7' \
 && fluent-gem uninstall msgpack -v 1.8.5 --executables --ignore-dependencies \
 && fluent-gem sources --clear-all \
 && SUDO_FORCE_REMOVE=yes apt-get purge -y --auto-remove ${BUILD_DEPS} \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/fluent/.gem/ruby/*/cache/*.gem

COPY fluent.conf /fluentd/etc/
COPY entrypoint.sh /bin/

USER fluent
