# -------- Build stage --------
FROM erlang:26 AS build

ARG VERNEMQ_VERSION=2.0.1

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      git ca-certificates curl build-essential \
      autoconf automake libtool pkg-config libsnappy-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --branch ${VERNEMQ_VERSION} https://github.com/vernemq/vernemq.git .

RUN make rel


# -------- Runtime stage --------
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
      bash procps openssl iproute2 curl jq libsnappy-dev net-tools nano ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    addgroup --gid 10000 vernemq && \
    adduser --uid 10000 --system --ingroup vernemq --home /vernemq --disabled-password vernemq

WORKDIR /vernemq

ENV DOCKER_VERNEMQ_KUBERNETES_LABEL_SELECTOR="app=vernemq" \
    DOCKER_VERNEMQ_LOG__CONSOLE=console \
    PATH="/vernemq/bin:$PATH"

# --- scripts & config ---
COPY bin/vernemq.sh /usr/local/bin/start_vernemq
COPY bin/join_cluster.sh /usr/local/bin/join_cluster
COPY files/vm.args /vernemq/etc/vm.args

RUN sed -i 's/\r$//' /usr/local/bin/start_vernemq /usr/local/bin/join_cluster && \
    chmod 0755 /usr/local/bin/start_vernemq /usr/local/bin/join_cluster && \
    ln -s /vernemq/etc /etc/vernemq && \
    ln -s /vernemq/data /var/lib/vernemq && \
    ln -s /vernemq/log  /var/log/vernemq && \
    chown -R 10000:10000 /vernemq

COPY --from=build --chown=10000:10000 /src/_build/default/rel/vernemq /vernemq

EXPOSE 1883 8883 8080 44053 4369 8888 \
       9100 9101 9102 9103 9104 9105 9106 9107 9108 9109

VOLUME ["/vernemq/log", "/vernemq/data", "/vernemq/etc"]

HEALTHCHECK CMD vernemq ping | grep -q pong

USER vernemq
CMD ["/usr/local/bin/start_vernemq"]
