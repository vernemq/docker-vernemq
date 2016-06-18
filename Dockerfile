FROM debian:jessie

RUN apt-get update && apt-get install -y openssl logrotate sudo

ADD https://bintray.com/artifact/download/erlio/vernemq/deb/jessie/vernemq_0.12.5p5-1_amd64.deb /tmp/vernemq.deb

RUN dpkg -i /tmp/vernemq.deb

ADD files/vm.args /etc/vernemq/vm.args
ADD bin/vernemq.sh /usr/sbin/start_vernemq
ADD bin/rand_cluster_node.escript /var/lib/vernemq/rand_cluster_node.escript

EXPOSE \ 
    # MQTT
    1883 \
    # MQTT WebSockets
    8080 \
    # VerneMQ Message Distribution
    44053 \
    # EPMD - Erlang Port Mapper Daemon
    4349 \
    # Specific Distributed Erlang Port Range 
    9100 9101 9102 9103 9104 9105 9105 9107 9108 9109

VOLUME ["/var/log/vernemq", "/var/lib/vernemq"]

CMD ["start_vernemq"] 

