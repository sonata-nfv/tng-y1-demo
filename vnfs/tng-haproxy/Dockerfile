FROM million12/haproxy
LABEL maintainer="felipe.vicens@atos.net"
RUN yum -y install epel-release && yum clean all
RUN yum -y install python-pip && yum clean all
RUN yum -y install net-snmp net-snmp-utils net-snmp-perl socat nano && yum clean all
RUN pip install flask-restful
RUN mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.orig
COPY ./snmpd.conf /etc/snmp/snmpd.conf 
COPY ./scripts/* /etc/snmp/scripts/
RUN systemctl enable snmpd.service

COPY . /app
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
EXPOSE 5000
WORKDIR /app
CMD ["./service.sh"]
