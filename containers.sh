#!/usr/bin/env bash
#
#
#
#
#
#
#


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR" && source functions.sh

create_container oauth2proxy \
    "test_curl localhost:4180" \
    -p 4180:4180 \
    -v "${SCRIPT_DIR}/oauth2proxy/oauth2_proxy.conf:/etc/oauth2_proxy.conf" \
    quay.io/oauth2-proxy/oauth2-proxy \
    oauth2_proxy --email-domain='*' --config=/etc/oauth2_proxy.conf

create_container portainer \
    "test_curl localhost:9999" \
    -p 8000:8000 -p 9999:9999 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce -p :9999

create_container madness \
    "test_curl localhost:3000" \
    -p 3000:3000 \
    -v /opt/dev-docs:/docs \
    dannyben/madness

create_container pgadmin \
    "test_curl localhost:5050" \
    -v pgadmin_data:/var/lib/pgadmin \
    -p 5050:5050 \
    dpage/pgadmin4

create_container postgres \
    "test_netcat localhost 5432" \
    -v postgres_data:/var/lib/postgresql/data/pgdata \
    -p 5432:5432 \
    postgres

create_container rabbitmq \
    "test_netcat localhost 5672" \
    -p 15672:15672 \
    -p 5672:5672 \
    rabbitmq:3.7-management

create_container redis \
    "test_netcat localhost 6379" \
    -v "${SCRIPT_DIR}/redis/docker-entrypoint.sh:/docker-entrypoint.sh" \
    -v redis_data:/data \
    -p 6379:6379 \
    redis \
    /docker-entrypoint.sh

create_container rebrow \
    "test_netcat localhost 5001" \
    -p 5001:5001 \
    --link redis:redis \
    marian/rebrow

create_container rediscommander \
    "test_netcat localhost 6380" \
    -p 6380:6380 \
    --link redis:redis \
    rediscommander/redis-commander:latest

create_container mongodb \
    "test_netcat localhost 27107" \
    -v mongo_data:/data/db \
    -p 27107:27107 \
    mongo:4.2

create_container mongoexpress \
    "test_netcat localhost 8081" \
    --link mongodb:mongo \
    -p 8081:8081 \
    mongo-express

create_container mitmproxy \
    "test_netcat localhost 8888" \
    -v mitmproxy:/home/mitmproxy/.mitmproxy \
    -p 8888:8888 \
    -p 8889:8889 \
    mitmproxy/mitmproxy \
    mitmweb --web-port 8889 --web-host 0.0.0.0 --listen-port 8888 --listen-host 0.0.0.0 --no-web-open-browser

