#!/usr/bin/dumb-init /bin/sh
set -e

# Note above that we run dumb-init as PID 1 in order to reap zombie processes
# as well as forward signals to all processes in its session. Normally, sh
# wouldn't do either of these functions so we'd leak zombies as well as do
# unclean termination of all our sub-processes.
# As of docker 1.13, using docker run --init achieves the same outcome.

# You can set CONSUL_BIND_INTERFACE to the name of the interface you'd like to
# bind to and this will look up the IP and pass the proper -bind= option along
# to Consul.
echo "Arg1:".$1
echo "Arg2:".$2
echo "Arg3:".$3
echo "Arg4:".$4

CONSUL_COMPLETE=false
VAULT_COMPLETE=false

#################################################Consul docker-entrypoint.sh############################################

do_consul() {
  echo "do_consul called with:".$@
  if [ -z "$CONSUL_BIND" ]; then
    if [ -n "$CONSUL_BIND_INTERFACE" ]; then
      CONSUL_BIND_ADDRESS=$(ip -o -4 addr list $CONSUL_BIND_INTERFACE | head -n1 | awk '{print $4}' | cut -d/ -f1)
      if [ -z "$CONSUL_BIND_ADDRESS" ]; then
        echo "Could not find IP for interface '$CONSUL_BIND_INTERFACE', exiting"
        exit 1
      fi

      CONSUL_BIND="-bind=$CONSUL_BIND_ADDRESS"
      echo "==> Found address '$CONSUL_BIND_ADDRESS' for interface '$CONSUL_BIND_INTERFACE', setting bind option..."
    fi
  fi

  # You can set CONSUL_CLIENT_INTERFACE to the name of the interface you'd like to
  # bind client intefaces (HTTP, DNS, and RPC) to and this will look up the IP and
  # pass the proper -client= option along to Consul.
  if [ -z "$CONSUL_CLIENT" ]; then
    if [ -n "$CONSUL_CLIENT_INTERFACE" ]; then
      CONSUL_CLIENT_ADDRESS=$(ip -o -4 addr list $CONSUL_CLIENT_INTERFACE | head -n1 | awk '{print $4}' | cut -d/ -f1)
      if [ -z "$CONSUL_CLIENT_ADDRESS" ]; then
        echo "Could not find IP for interface '$CONSUL_CLIENT_INTERFACE', exiting"
        exit 1
      fi

      CONSUL_CLIENT="-client=$CONSUL_CLIENT_ADDRESS"
      echo "==> Found address '$CONSUL_CLIENT_ADDRESS' for interface '$CONSUL_CLIENT_INTERFACE', setting client option..."
    fi
  fi

  # CONSUL_DATA_DIR is exposed as a volume for possible persistent storage. The
  # CONSUL_CONFIG_DIR isn't exposed as a volume but you can compose additional
  # config files in there if you use this image as a base, or use CONSUL_LOCAL_CONFIG
  # below.
  if [ -z "$CONSUL_DATA_DIR" ]; then
    CONSUL_DATA_DIR=/consul/data
  fi

  if [ -z "$CONSUL_CONFIG_DIR" ]; then
    CONSUL_CONFIG_DIR=/consul/config
  fi

  # You can also set the CONSUL_LOCAL_CONFIG environemnt variable to pass some
  # Consul configuration JSON without having to bind any volumes.
  if [ -n "$CONSUL_LOCAL_CONFIG" ]; then
    echo "$CONSUL_LOCAL_CONFIG" > "$CONSUL_CONFIG_DIR/local.json"
  fi

  # If the user is trying to run Consul directly with some arguments, then
  # pass them to Consul.
  if [ "${1:0:1}" = '-' ]; then
    echo "Using a direct consul command, found args:".$@
    set -- consul "$@"
  fi

  # Look for Consul subcommands.
  if [ "$1" = 'agent' ]; then
    shift
    set -- consul agent \
      -data-dir="$CONSUL_DATA_DIR" \
      -config-dir="$CONSUL_CONFIG_DIR" \
      $CONSUL_BIND \
      $CONSUL_CLIENT \
      "$@"
      echo "agent passed, new positional arg list:".$@
  elif [ "$1" = 'version' ]; then
    # This needs a special case because there's no help output.
    set -- consul "$@"
  elif consul --help "$1" 2>&1 | grep -q "consul $1"; then
    # We can't use the return code to check for the existence of a subcommand, so
    # we have to use grep to look for a pattern in the help output.
    set -- consul "$@"
    echo "wasnt agent nor version passed, new positional arg list:".$@
  fi

  # If we are running Consul, make sure it executes as the proper user.
  if [ "$1" = 'consul' -a -z "${CONSUL_DISABLE_PERM_MGMT+x}" ]; then
    echo "consul arg1 and disable_perm is null"
    # Allow to setup user and group via envrironment
    if [ -z "$CONSUL_UID" ]; then
      echo "setting consul_uid"
      CONSUL_UID="$(id -u consul)"
    fi

    if [ -z "$CONSUL_GID" ]; then
      echo "setting consul_gid"
      CONSUL_GID="$(id -g consul)"
    fi

    # If the data or config dirs are bind mounted then chown them.
    # Note: This checks for root ownership as that's the most common case.
    if [ "$(stat -c %u "$CONSUL_DATA_DIR")" != "${CONSUL_UID}" ]; then
      echo "chown data_dir"
      chown ${CONSUL_UID}:${CONSUL_GID} "$CONSUL_DATA_DIR"
    fi
    if [ "$(stat -c %u "$CONSUL_CONFIG_DIR")" != "${CONSUL_UID}" ]; then
      echo "chown config_dir"
      chown ${CONSUL_UID}:${CONSUL_GID} "$CONSUL_CONFIG_DIR"
    fi

    # If requested, set the capability to bind to privileged ports before
    # we drop to the non-root user. Note that this doesn't work with all
    # storage drivers (it won't work with AUFS).
    if [ ! -z ${CONSUL_ALLOW_PRIVILEGED_PORTS+x} ]; then
      echo "allow privileged ports"
      setcap "cap_net_bind_service=+ep" /bin/consul
    fi
    echo "before setting su exec:".$@
    set -- su-exec ${CONSUL_UID}:${CONSUL_GID} "$@"
    echo "after setting su exec:".$@
  fi

  echo "Executing:".$@
  CONSUL_COMPLETE=true
  $@ &
}

#################################################Vault docker-entrypoint.sh############################################

# Note above that we run dumb-init as PID 1 in order to reap zombie processes
# as well as forward signals to all processes in its session. Normally, sh
# wouldn't do either of these functions so we'd leak zombies as well as do
# unclean termination of all our sub-processes.

#if ["$0" = "vault"]; then
# Prevent core dumps
ulimit -c 0

# Allow setting VAULT_REDIRECT_ADDR and VAULT_CLUSTER_ADDR using an interface
# name instead of an IP address. The interface name is specified using
# VAULT_REDIRECT_INTERFACE and VAULT_CLUSTER_INTERFACE environment variables. If
# VAULT_*_ADDR is also set, the resulting URI will combine the protocol and port
# number with the IP of the named interface.
get_addr () {
  local if_name=$1
  local uri_template=$2
  ip addr show dev $if_name | awk -v uri=$uri_template '/\s*inet\s/ { \
  ip=gensub(/(.+)\/.+/, "\\1", "g", $2); \
  print gensub(/^(.+:\/\/).+(:.+)$/, "\\1" ip "\\2", "g", uri); \
  exit}'
}

do_vault() {
  echo "do_vault called with:".$@
  if [ -n "$VAULT_REDIRECT_INTERFACE" ]; then
    export VAULT_REDIRECT_ADDR=$(get_addr $VAULT_REDIRECT_INTERFACE ${VAULT_REDIRECT_ADDR:-"http://0.0.0.0:8200"})
    echo "Using $VAULT_REDIRECT_INTERFACE for VAULT_REDIRECT_ADDR: $VAULT_REDIRECT_ADDR"
  fi
  if [ -n "$VAULT_CLUSTER_INTERFACE" ]; then
    export VAULT_CLUSTER_ADDR=$(get_addr $VAULT_CLUSTER_INTERFACE ${VAULT_CLUSTER_ADDR:-"https://0.0.0.0:8201"})
    echo "Using $VAULT_CLUSTER_INTERFACE for VAULT_CLUSTER_ADDR: $VAULT_CLUSTER_ADDR"
  fi

  # VAULT_CONFIG_DIR isn't exposed as a volume but you can compose additional
  # config files in there if you use this image as a base, or use
  # VAULT_LOCAL_CONFIG below.
  VAULT_CONFIG_DIR=/etc/vault

  # You can also set the VAULT_LOCAL_CONFIG environment variable to pass some
  # Vault configuration JSON without having to bind any volumes.
  if [ -n "$VAULT_LOCAL_CONFIG" ]; then
    echo "$VAULT_LOCAL_CONFIG" > "$VAULT_CONFIG_DIR/local.json"
  fi

  # If the user is trying to run Vault directly with some arguments, then
  # pass them to Vault.
  if [ "$1" = "vault" -a "${1:0:1}" = '-' ]; then
    set -- vault "$@"
  fi

  # Look for Vault subcommands.
  if [ "$2" = 'server' ]; then
    shift
    set -- vault server \
        -config="$VAULT_CONFIG_DIR" \
        -dev-root-token-id="$VAULT_DEV_ROOT_TOKEN_ID" \
        -dev-listen-address="${VAULT_DEV_LISTEN_ADDRESS:-"0.0.0.0:8200"}" \
        "$@"
  elif [ "$2" = 'version' ]; then
    # This needs a special case because there's no help output.
    set -- vault "$@"
  elif vault --help "$1" 2>&1 | grep -q "vault $2"; then
    # We can't use the return code to check for the existence of a subcommand, so
    # we have to use grep to look for a pattern in the help output.
    set -- vault "$@"
  fi

  # If we are running Vault, make sure it executes as the proper user.
  if [ "$1" = 'vault' ]; then
    if [ -z "$SKIP_CHOWN" ]; then
      # If the config dir is bind mounted then chown it
      if [ "$(stat -c %u /etc/config)" != "$(id -u vault)" ]; then
        chown -R vault:vault /etc/config || echo "Could not chown /vault/config (may not have appropriate permissions)"
      fi

      # If the logs dir is bind mounted then chown it
      if [ "$(stat -c %u /opt/vault)" != "$(id -u vault)" ]; then
        chown -R vault:vault /opt/vault
      fi

      # If the file dir is bind mounted then chown it
      if [ "$(stat -c %u /vault/file)" != "$(id -u vault)" ]; then
        chown -R vault:vault /vault/file
      fi
    fi

    if [ -z "$SKIP_SETCAP" ]; then
      # Allow mlock to avoid swapping Vault memory to disk
      setcap cap_ipc_lock=+ep $(readlink -f $(which vault))

      # In the case vault has been started in a container without IPC_LOCK privileges
      if ! vault -version 1>/dev/null 2>/dev/null; then
        >&2 echo "Couldn't start vault with IPC_LOCK. Disabling IPC_LOCK, please use --cap-add IPC_LOCK"
        setcap cap_ipc_lock=-ep $(readlink -f $(which vault))
      fi
    fi

    if [ "$(id -u)" = '0' ]; then
      set -- su-exec vault "$@"
    fi
  fi
  VAULT_COMPLETE=true
  exec "$@"
  #done
}

if [ "$3" = "start-both" -a "$CONSUL_COMPLETE" = false ]; then
  do_consul consul agent -config-file /etc/consul/consul.hcl
  echo "About to call do_vault"
  do_vault vault server -config /etc/vault/vault.hcl
elif [ "$1" = "consul" ]; then
  do_consul $@
elif [ "$1" = "vault" ]; then
  do_vault $@
fi