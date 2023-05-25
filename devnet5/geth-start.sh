#! /usr/bin/env bash
#
GETH=$HOME/src/mdehoog/go-ethereum/build/bin/geth

$GETH init --datadir /var/lib/db/devnet5/geth genesis.json

$GETH \
	--http \
	--http.api eth,net,engine,admin,web3,debug \
	--authrpc.vhosts=* \
	--networkid=4844001005 \
	--authrpc.jwtsecret=/home/kasey/eth-envs/devnet5/jwt.hex \
	--syncmode=full \
	--bootnodes=enr:-Iq4QJk4WqRkjsX5c2CXtOra6HnxN-BMXnWhmhEQO9Bn9iABTJGdjUOurM7Btj1ouKaFkvTRoju5vz2GPmVON2dffQKGAX53x8JigmlkgnY0gmlwhLKAlv6Jc2VjcDI1NmsxoQK6S-Cii_KmfFdUJL2TANL3ksaKUnNXvTCv1tLwXs0QgIN1ZHCCIyk \
	--datadir /var/lib/db/devnet5/geth
