#!/usr/bin/env bash

IP_ADDRESS=$(ip -4 addr show eth0 | grep -oP "(?<=inet).*(?=/)"| sed -e "s/^[[:space:]]*//"| tail -n 1)
if env | grep -q "DOCKER_VERNEMQ_DISCOVERY_NODE"; then
  IP_ADDRESS=$(getent hosts `hostname` | awk '{ print $1 }' | head -n 1)
fi

# Ensure correct ownership and permissions on volumes
chown vernemq:vernemq /var/lib/vernemq /var/log/vernemq
chmod 755 /var/lib/vernemq /var/log/vernemq

# Ensure the Erlang node name is set correctly
sed -i.bak "s/VerneMQ@127.0.0.1/VerneMQ@${IP_ADDRESS}/" /etc/vernemq/vm.args

sed -i '/########## Start ##########/,/########## End ##########/d' /etc/vernemq/vernemq.conf

echo "########## Start ##########" >> /etc/vernemq/vernemq.conf

env | grep DOCKER_VERNEMQ | grep -v DISCOVERY_NODE | cut -c 16- | tr '[:upper:]' '[:lower:]' >> /etc/vernemq/vernemq.conf

echo "erlang.distribution.port_range.minimum = 9100" >> /etc/vernemq/vernemq.conf
echo "erlang.distribution.port_range.maximum = 9109" >> /etc/vernemq/vernemq.conf
echo "listener.tcp.default = 0.0.0.0:1883" >> /etc/vernemq/vernemq.conf
echo "listener.ws.default = 0.0.0.0:8080" >> /etc/vernemq/vernemq.conf
echo "listener.vmq.clustering = 0.0.0.0:44053" >> /etc/vernemq/vernemq.conf
echo "listener.http.metrics = 0.0.0.0:8888" >> /etc/vernemq/vernemq.conf

echo "########## End ##########" >> /etc/vernemq/vernemq.conf

# Check configuration file
su - vernemq -c "/usr/sbin/vernemq config generate 2>&1 > /dev/null" | tee /tmp/config.out | grep error

if [ $? -ne 1 ]; then
    echo "configuration error, exit"
    echo "$(cat /tmp/config.out)"
    exit $?
fi

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

if env | grep -q "DOCKER_VERNEMQ_DISCOVERY_NODE"; then
    DOCKER_VERNEMQ_DISCOVERY_NODE=$(getent hosts ${DOCKER_VERNEMQ_DISCOVERY_NODE} | awk '{ print $1 }' | head -n 1)
    wait-for-it.sh ${IP_ADDRESS}:44053 ${DOCKER_VERNEMQ_DISCOVERY_NODE}:44053 && vmq-admin cluster join discovery-node=VerneMQ@${DOCKER_VERNEMQ_DISCOVERY_NODE}
fi

while true
do
    tail -f /var/log/vernemq/console.log & wait ${!}
done
