#!/usr/bin/env bash

IP_ADDRESS=$(getent hosts $(hostname) | awk '{ print $1 }' | head -n 1)

# Ensure correct ownership and permissions on volumes
chown vernemq:vernemq /var/lib/vernemq /var/log/vernemq
chmod 755 /var/lib/vernemq /var/log/vernemq

# Ensure the Erlang node name is set correctly
sed -i.bak "s/VerneMQ@127.0.0.1/VerneMQ@${IP_ADDRESS}/" /etc/vernemq/vm.args

sed -i '/########## Start ##########/,/########## End ##########/d' /etc/vernemq/vernemq.conf

echo "########## Start ##########" >> /etc/vernemq/vernemq.conf

env | grep DOCKER_VERNEMQ | grep -v 'DISCOVERY_NODE\|DOCKER_VERNEMQ_USER' | cut -c 16- | tr '[:upper:]' '[:lower:]' | sed 's/__/./g' >> /etc/vernemq/vernemq.conf

users_are_set=$(env | grep DOCKER_VERNEMQ_USER)
if [ ! -z $users_are_set ]
    then
        echo "vmq_passwd.password_file = /etc/vernemq/vmq.passwd" >> /etc/vernemq/vernemq.conf
fi

for vernemq_user in $(env | grep DOCKER_VERNEMQ_USER);
    do
        username=$(echo $vernemq_user | awk -F '=' '{ print $1 }' | sed 's/DOCKER_VERNEMQ_USER_//g' | tr '[:upper:]' '[:lower:]')
        password=$(echo $vernemq_user | awk -F '=' '{ print $2 }')
        vmq-passwd -c /etc/vernemq/vmq.passwd $username <<EOF
$password
$password
EOF
    done

echo "erlang.distribution.port_range.minimum = 9100" >> /etc/vernemq/vernemq.conf
echo "erlang.distribution.port_range.maximum = 9109" >> /etc/vernemq/vernemq.conf
echo "listener.tcp.default = 0.0.0.0:1883" >> /etc/vernemq/vernemq.conf
echo "listener.ws.default = 0.0.0.0:8080" >> /etc/vernemq/vernemq.conf
echo "listener.vmq.clustering = ${IP_ADDRESS}:44053" >> /etc/vernemq/vernemq.conf
echo "listener.http.default = 0.0.0.0:8888" >> /etc/vernemq/vernemq.conf

echo "listener.tcp.proxy_protocol = on" >> /etc/vernemq/vernemq.conf
echo "listener.ws.proxy_protocol = on" >> /etc/vernemq/vernemq.conf
echo "listener.http.proxy_protocol = on" >> /etc/vernemq/vernemq.conf

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
pid=$(vernemq getpid)

if env | grep -q "DOCKER_VERNEMQ_DISCOVERY_NODE"; then
    wait-for-it.sh ${IP_ADDRESS}:44053 ${DOCKER_VERNEMQ_DISCOVERY_NODE}:44053 && vmq-admin cluster join discovery-node=VerneMQ@${DOCKER_VERNEMQ_DISCOVERY_NODE}
fi

if env | grep -q "PEER_DISCOVERY_NAME"; then
    FIRST_PEER=$(getent hosts tasks.${PEER_DISCOVERY_NAME} | awk '{ print $1 }' | sort | grep -v ${IP_ADDRESS} | head -n 1)
    wait-for-it.sh ${IP_ADDRESS}:44053 ${FIRST_PEER}:44053 && vmq-admin cluster join discovery-node=VerneMQ@${FIRST_PEER}
fi


while true
do
    tail -f /var/log/vernemq/console.log & wait ${!}
done
