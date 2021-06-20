#!/usr/bin/env

total_waits=0
available=0
while [ $total_waits -lt 30 ]; do
    sleep 1
    if rabbitmqctl await_startup &> /dev/null; then
        available=1
        break
    else
        total_waits=$((total_waits+1))
    fi
done

for username in $(set | grep -E '^RABBITMQ_.+_PASSWORD=' | cut -d_ -f2 | tr '[:upper:]' '[:lower:]' ); do
    password="$(set | grep -Ei "^RABBITMQ_${username}_PASSWORD=" | cut -d= -f2)"
    #rabbitmq_user_exists
    echo "setting up ${username}"
    if ! rabbitmqctl list_users | grep --silent -E "^${username}\s"; then
        rabbitmqctl add_user "$username" "$password"
    else
        rabbitmqctl change_password "$username" "$password"
    fi
    if [[ "$username" = "admin" ]]; then
        rabbitmqctl set_user_tags "$username" administrator
    else
        if ! rabbitmqctl list_vhosts | grep -E "^${username}\$"; then
            rabbitmqctl add_vhost "$username"
        fi
        rabbitmqctl set_permissions -p "$username" "$username" '.*' '.*' '.*'
    fi
done

rabbitmqctl delete_user guest &> /dev/null
