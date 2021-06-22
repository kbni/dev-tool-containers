#!/usr/bin/env bash
#set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
GREEN='\033[0;32m'
RED='\033[0;31m'
WHITE='\033[0;37m'
RESET='\033[0m'

export NETWORK_NAME="${NETWORK_NAME:-devenv}"
export DATA_DIR="${DATA_DIR:-"${SCRIPT_DIR}/data/${NETWORK_NAME}"}"

test_curl() {
    curl --silent "$@" > /dev/null
}

test_netcat() {
    nc -z "$@" > /dev/null
}

create_datadir() {
    if [ ! -d "$DATA_DIR" ]; then
        mkdir -p "$DATA_DIR"
        echo "data dir created: $DATA_DIR"
    else
        echo "data dir exists: $DATA_DIR"
    fi
}

create_network() {
    network_id=$(docker network ls -q --filter=name="$NETWORK_NAME")
    if [[ "$network_id" = "" ]]; then
        network_id=$(docker network create --attachable "$NETWORK_NAME")
        echo "network created: $NETWORK_NAME ($network_id)"
    else
        echo "network exists: $NETWORK_NAME ($network_id)"
    fi
}

murder_container() {
    container_name="$1"; shift
    docker stop "$container_name" &> /dev/null
    docker kill "$container_name" &> /dev/null
    docker rm "$container_name" &> /dev/null
}

create_container() {
    container_name="$1"; shift
    check_script="$1"; shift

    echo -en "${WHITE}${container_name}${RESET} ."

    if [ ! -f "${container_name}/${container_name}.env" ]; then
        echo -e ". skipped (no env file)"
        return 0
    fi

    if eval "$check_script" ; then
        echo -e ". ${GREEN}checks successful${RESET}"
        return 0
    fi
    echo -e ". ${RED}checks failed${RESET}"

    container_id=$(docker ps -aq --filter=name="^${container_name}\$")
    if [[ ! "$container_id" = "" ]]; then
        echo -e "found container ${container_id}, murdering it."
        docker stop "$container_id" &> /dev/null
        docker kill "$container_id" &> /dev/null
        docker rm "$container_id" &> /dev/null
    fi

    if [ -f "${SCRIPT_DIR}/${container_name}/Dockerfile" ]; then
        ( cd "${SCRIPT_DIR}/${container_name}" && docker build -t "devtools-${container_name}" . )
        if [ $? -ne 0 ]; then
            echo -e "... ${RED}failed to build container${RESET}"
            return
        fi
    fi

    addn_args=()

    if [ -f "${SCRIPT_DIR}/${container_name}/${container_name}.env" ]; then
        addn_args+=( "--env-file" "${SCRIPT_DIR}/${container_name}/${container_name}.env" )
    else
        if [ -f "${SCRIPT_DIR}/${container_name}/${container_name}.env.example" ]; then
            echo "${RED}missing env file${RESET}: ${container_name}/${container_name}.env!" > /dev/stderr
            return 1
        fi
    fi

    container_id=$(set -x ; docker run "${addn_args[@]}" -d --name="$container_name" --restart=always "$@")

    inside_script="${SCRIPT_DIR}/${container_name}/inside.sh"
    if [ -f "$inside_script" ]; then
        echo -e "${WHITE}${container_name}${RESET} running inside.sh"
        docker cp "$inside_script" "$container_name":/inside.sh
        docker exec "$container_name" bash /inside.sh
        docker exec "$container_name" rm /inside.sh
    fi

    outside_script="${SCRIPT_DIR}/${container_name}/outside.sh"
    if [ -f "$outside_script" ]; then
        echo "${WHITE}${container_name}${RESET} running outside.sh"
        bash "$outside_script"
    fi


    echo -en "${WHITE}${container_name}${RESET} ."
    if eval "$check_script" ; then
        echo -e ". ${GREEN}launched successfully${RESET}"
        return 0
    fi
    echo -e ". ${RED}post-create check failed${RESET}"

}