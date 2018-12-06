FROM erlang:20.3 AS build-env

WORKDIR /vernemq-build

ARG VERNEMQ_GIT_REF=1.6.2
ARG TARGET=rel
ARG VERNEMQ_REPO=https://github.com/vernemq/vernemq.git

# Defaults
ENV DOCKER_VERNEMQ_KUBERNETES_APP_LABEL vernemq
ENV DOCKER_VERNEMQ_LOG__CONSOLE console

RUN \
    apt-get update \
    && apt-get -y install build-essential git libssl-dev  \
    && git clone -b $VERNEMQ_GIT_REF --single-branch --depth 1 $VERNEMQ_REPO .

ADD bin/build.sh build.sh

RUN ./build.sh $TARGET


FROM debian:stretch-slim

RUN \
    apt-get update \
    && apt-get -y install openssl iproute2 curl jq \
	&& rm -rf /var/lib/apt/lists/*

# Defaults
ENV DOCKER_VERNEMQ_KUBERNETES_APP_LABEL vernemq
ENV DOCKER_VERNEMQ_LOG__CONSOLE console
ENV PATH "/vernemq/bin:$PATH"
ADD bin/vernemq.sh /usr/sbin/start_vernemq

WORKDIR /vernemq
COPY --from=build-env /vernemq-build/release /vernemq
ADD files/vm.args /vernemq/etc/vm.args

RUN addgroup vernemq && \
    adduser --system --ingroup vernemq --home /vernemq --disabled-password vernemq && \
    chown -R vernemq:vernemq /vernemq && \
    ln -s /vernemq/etc /etc/vernemq && \
    ln -s /vernemq/data /var/lib/vernemq && \
    ln -s /vernemq/log /var/log/vernemq

# Ports
# 1883  MQTT
# 8883  MQTT/SSL
# 8080  MQTT WebSockets
# 44053 VerneMQ Message Distribution
# 4369  EPMD - Erlang Port Mapper Daemon
# 8888  Prometheus Metrics
# 9100 9101 9102 9103 9104 9105 9106 9107 9108 9109  Specific Distributed Erlang Port Range

EXPOSE 1883 8883 8080 44053 4369 8888 \
       9100 9101 9102 9103 9104 9105 9106 9107 9108 9109


VOLUME ["/vernemq/log", "/vernemq/data", "/vernemq/etc"]

USER vernemq
CMD ["start_vernemq"]
