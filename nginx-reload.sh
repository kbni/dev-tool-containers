#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR" && source functions.sh

export NGINX_INCLUDE_FILE="${NGINX_INCLUDE_FILE:-/etc/nginx/includes/dev-tools.conf}"

[[ -d ".temp/nginx" ]] || mkdir -p ".temp/nginx"

sudo cp "$NGINX_INCLUDE_FILE" "$nginx_old_include" &> /dev/null

nginx_old_include=".temp/nginx/old-include.conf"
nginx_new_include=".temp/nginx/new-include.conf"

if [ -f "$nginx_new_include" ]; then
    rm -f "$nginx_new_include"
fi

for nginx_addn_conf in "${SCRIPT_DIR}"/*/*.nginx.conf; do
    echo "# from $nginx_addn_conf" >> "$nginx_new_include"
    grep -vE '^\s*$' "$nginx_addn_conf" >> "$nginx_new_include"
    echo "" >> "$nginx_new_include"
done

sudo cp "$nginx_new_include" "${NGINX_INCLUDE_FILE}"
if sudo nginx -t; then
    echo -e "${GREEN}nginx config tested okay, restarting nginx${RESTORE}"
    sudo systemctl restart nginx
else
    echo -e "${RED}nginx config test failed!${RESTORE}"
    if [ -f "$nginx_old_include" ]; then
        echo "restoring previous copy of ${NGINX_INCLUDE_FILE}"
        sudo cp -v "$nginx_new_include" "${NGINX_INCLUDE_FILE}"
    fi
fi

echo
sudo systemctl status nginx
