FROM rabbitmq:4.1.8-management

# Community plugin: per-message x-delay support used by the platform queue
# retry pipeline. Pin to the version matching RabbitMQ 4.1.x.
# Source: https://github.com/rabbitmq/rabbitmq-delayed-message-exchange
ARG DELAYED_PLUGIN_VERSION=4.1.0
ARG DELAYED_PLUGIN_SHA256=567f876378e70af9d949de4066bbb2fc30162b46bcbc9efe2430076b172e4a87

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates; \
    curl -fsSL -o /opt/rabbitmq/plugins/rabbitmq_delayed_message_exchange-${DELAYED_PLUGIN_VERSION}.ez \
        "https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v${DELAYED_PLUGIN_VERSION}/rabbitmq_delayed_message_exchange-${DELAYED_PLUGIN_VERSION}.ez"; \
    if [ -n "${DELAYED_PLUGIN_SHA256}" ]; then \
        echo "${DELAYED_PLUGIN_SHA256}  /opt/rabbitmq/plugins/rabbitmq_delayed_message_exchange-${DELAYED_PLUGIN_VERSION}.ez" \
        | sha256sum -c -; \
    fi; \
    apt-get purge -y --auto-remove curl; \
    rm -rf /var/lib/apt/lists/*; \
    rabbitmq-plugins enable --offline rabbitmq_delayed_message_exchange