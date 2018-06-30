# tng-haproxy docker container

This container is composed by haproxy server [million12/haproxy](https://github.com/million12/docker-haproxy) + simple API to handle the automatic reconfiguration of the backend services.

## How to use it?

* To start the container is needed to set admin networking capabilities with the parameter --cap-add NET_ADMIN
* The API is listen internally in the port 5000
* The HA Proxy is receiving packages in port 80

```bash
docker run --cap-add NET_ADMIN -d -p 5000:5000 -p 80:80 -ti sonatanfv/tng-haproxy
```

## tng-haproxy API description

The api of the haproxy have two methods in the / [GET and POST]

### GET /

This endpoint returns the curren configuration of the haproxy

```text
curl http://localhost:5000

global
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    pidfile /var/run/haproxy.pid
    spread-checks 4
    tune.maxrewrite 1024
    tune.ssl.default-dh-param 2048

defaults
    mode    http
    balance roundrobin
    option  dontlognull
    option  dontlog-normal
    option  redispatch
    maxconn 10000
    timeout connect 5s
    timeout client  20s
    timeout server  20s
    timeout queue   30s
    timeout http-request 5s
    timeout http-keep-alive 15s

    frontend squid
        stats enable
        stats refresh 5s
        stats realm Strictly\ Private
        stats auth admin:admin
        stats uri /admin?stats
        bind *:80
        mode http
        default_backend squid_backend

    backend squid_backend
        mode http
        server vnf1 172.17.0.7:3128 check
        server vnf2 172.17.0.6:3128 check
```

### POST /

This endpoint configure the haproxy via json file. To configure more backends just add a new element in the backends object.

```bash
curl -X POST http://localhost:5000/ --data @services_example.json -H "Content-type: application/json"
```

```json
[
  {
    "name": "squid",
    "port": 80,
    "backends": [
      { "name": "vnf1", "host": "172.17.0.7", "port": 3128 },
      { "name": "vnf2", "host": "172.17.0.6", "port": 3128 }
    ]
  }
]
```
## How it works

For the demo, the haproxy is located on front of a set of squid servers. The idea is to scale the squid behind the haproxy in order to increase the number of connections supported by the system.

When a specific metric of the system is reached, then the scaling capability is activated and the Service Platform will trigger a new instantiation of squid server. Once the squid service is UP and RUNNING then the Service Platform will reconfigure the haproxy adding the new instance of squid making use of the haproxy API. Once the traffic dissapears, the haproxy will disable one squid server and it will be removed by the Service Platform.

```text
                    +-------+
                    |       |
              +-----> squid |
              |     |       |
              |     +-------+
              |
              |
+---------+   |     +-------+
|         |   |     |       |
| haproxy +---------> squid |
|         |   |     |       |
+---------+   |     +-------+
              |
              |
              |     +-------+
              |     |       |
              +-----> squid |
                    |       |
                    +-------+
```

## How to test it?
1. Start the sonatanfv/tng-haproxy container
2. Start the sonatanfv/tng-squid container
3. Check the IP of squid container (docker inspect squid container)
4. Create the config json file adding the squid IP in the backend of the service
5. POST the json file to haproxy API
6. Configure your system to use localhost:80 as proxy
7. Request an http page or use benchmark tools to get an specific web page like wrk or ab


