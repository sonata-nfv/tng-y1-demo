FROM million12/haproxy
LABEL maintainer="felipe.vicens@atos.net"
RUN yum -y install epel-release && yum clean all
RUN yum -y install python-pip && yum clean all
RUN pip install flask-restful
COPY . /app
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
EXPOSE 5000
WORKDIR /app
ENTRYPOINT [ "bash" ]
CMD ["./service.sh"]