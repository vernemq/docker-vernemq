#!/usr/bin/env bash

IP_ADDRESS=$(ip -4 addr show eth0 | grep -oP "(?<=inet).*(?=/)"| sed -e "s/^[[:space:]]*//")

# Ensure correct ownership and permissions on volumes
chown vernemq:vernemq /var/lib/vernemq /var/log/vernemq
chmod 755 /var/lib/vernemq /var/log/vernemq

# Ensure the Erlang node name is set correctly
sed -i.bak "s/VerneMQ@127.0.0.1/VerneMQ@${IP_ADDRESS}/" /etc/vernemq/vm.args

if env | grep -q "DOCKER_VERNEMQ_DISCOVERY_NODE"; then
    echo "-eval \"vmq_server_cmd:node_join('VerneMQ@${DOCKER_VERNEMQ_DISCOVERY_NODE}')\"" >> /etc/vernemq/vm.args
fi

echo "log.console = console" >> /etc/vernemq/vernemq.conf
echo "erlang.distribution.port_range.minimum = 9100" >> /etc/vernemq/vernemq.conf
echo "erlang.distribution.port_range.maximum = 9109" >> /etc/vernemq/vernemq.conf
echo "listener.tcp.default = ${IP_ADDRESS}:1883" >> /etc/vernemq/vernemq.conf
echo "listener.ws.default = ${IP_ADDRESS}:8080" >> /etc/vernemq/vernemq.conf
echo "listener.vmq.clustering = ${IP_ADDRESS}:44053" >> /etc/vernemq/vernemq.conf

/usr/sbin/vernemq console
