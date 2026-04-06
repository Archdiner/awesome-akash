#!/bin/bash
if [ -z "${PUBLIC_IP}" ]; then
  echo "Missing \$PUBLIC_IP=public_ip_of_the_deplyoment"
  sleep 120
  exit 1
fi

mkdir -p ${DATA_DIR}
chmod 0700 ${DATA_DIR}

quota=$(df --output=size --block-size=1 /codex | tail -1)

BOOTSTRAP_NODES=$(for i in $(curl https://spr.codex.storage/testnet 2> /dev/null); do echo --bootstrap-node=${i}; done)

exec /docker-entrypoint.sh codex \
  --storage-quota=${quota} \
  --data-dir=${DATA_DIR} \
  --api-port=8080 \
  --api-bindaddr=0.0.0.0 \
  --disc-port=8090 \
  --listen-addrs=/ip4/0.0.0.0/tcp/8070 \
  --nat=extip:${PUBLIC_IP}\
  ${BOOTSTRAP_NODES}\
  persistence \
  --eth-provider=https://rpc.testnet.codex.storage
