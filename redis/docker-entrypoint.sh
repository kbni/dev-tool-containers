#!/usr/bin/env bash

echo "Starting redis?"
echo "requirepass ${REDIS_PASSWORD}" > /etc/redis.conf
exec redis-server /etc/redis.conf
