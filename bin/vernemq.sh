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

if env | grep -q "DOCKER_VERNEMQ_ALLOW_ANONYMOUS=on"; then
    echo "allow_anonymous = on" >> /etc/vernemq/vernemq.conf
fi

if env | grep -q "DOCKER_VERNEMQ_TRADE_CONSISTENCY=on"; then
    echo "trade_consistency = on" >> /etc/vernemq/vernemq.conf
fi

if env | grep -q "DOCKER_VERNEMQ_ALLOW_MULTIPLE_SESSIONS=on"; then
    echo "allow_multiple_sessions = on" >> /etc/vernemq/vernemq.conf
fi

if env | grep -q "DOCKER_VERNEMQ_MAX_CLIENT_ID_SIZE"; then
    echo "max_client_id_size = ${DOCKER_VERNEMQ_MAX_CLIENT_ID_SIZE}" >> /etc/vernemq/vernemq.conf
fi

echo "erlang.distribution.port_range.minimum = 9100" >> /etc/vernemq/vernemq.conf
echo "erlang.distribution.port_range.maximum = 9109" >> /etc/vernemq/vernemq.conf
echo "listener.tcp.default = ${IP_ADDRESS}:1883" >> /etc/vernemq/vernemq.conf
echo "listener.ws.default = ${IP_ADDRESS}:8080" >> /etc/vernemq/vernemq.conf
echo "listener.vmq.clustering = ${IP_ADDRESS}:44053" >> /etc/vernemq/vernemq.conf
echo "listener.http.metrics = ${IP_ADDRESS}:8888" >> /etc/vernemq/vernemq.conf


pid=0

# SIGUSR1-handler
siguser1_handler() {
    echo "stopped"
}

# SIGTERM-handler
sigterm_handler() {
    if [ $pid -ne 0 ]; then
        # this will stop the VerneMQ process
        vmq-admin cluster leave node=VerneMQ@$IP_ADDRESS -k > /dev/null
        wait "$pid"
    fi
    exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null`
# and execute the specified handler
trap 'kill ${!}; siguser1_handler' SIGUSR1
trap 'kill ${!}; sigterm_handler' SIGTERM

/usr/sbin/vernemq start
pid=$(ps aux | grep '[b]eam.smp' | awk '{print $2}')

while true
do
    tail -f /var/log/vernemq/console.log & wait ${!}
done
