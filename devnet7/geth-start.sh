#! /usr/bin/env bash
#
GETH=$HOME/src/MariusVanDerWijden/go-ethereum/build/bin/geth
ETHENVS=/home/kasey/src/kasey/eth-envs/devnet7
ENVRUN=/var/lib/db/devnet7

$GETH init --datadir $ENVRUN/geth genesis.json

$GETH \
	--http \
	--http.api eth,net,engine,admin,web3,debug \
	--authrpc.vhosts=* \
	--networkid=7011893056 \
	--authrpc.jwtsecret=$ETHENVS/jwt.hex \
	--syncmode=full \
	--bootnodes=enode://aca516c9a2b78d0d0b20b9f565a8f781fefbc206f0b45a3803c209bf5bdd5d20b1948a29e720ef4b423f8d1e7a647524bff46efe5adc505ad632867bea2fe80b@159.223.15.126:30303?discport=30303 \
	--datadir ${ENVRUN}/geth





