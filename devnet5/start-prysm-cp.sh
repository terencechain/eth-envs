#! /usr/bin/env bash

pushd $HOME/src/prysmaticlabs/prysm

INFURA_BASE=https://2E5ZjSknj5QUIF21gLGedGwobuG:dc0f55e1846b6850314f49467bb4d352@eth2-beacon-mainnet.infura.io

bazel run //cmd/beacon-chain -- \
--checkpoint-sync-url=$INFURA_BASE \
--genesis-beacon-api-url=$INFURA_BASE \
--execution-endpoint=http://localhost:8551 \
--datadir=/var/lib/db/prysm/mainnet-20221005/ \
--accept-terms-of-use \
--enable-debug-rpc-endpoints \
--grpc-max-msg-size=65568081 \
--jwt-secret=$HOME/eth-envs/mainnet/jwt.hex \

# bazel run //cmd/beacon-chain -- --http-web3provider=http://localhost:8545 --prater --datadir /var/lib/prysm/prater-new-gen --accept-terms-of-use --enable-debug-rpc-endpoints --grpc-max-msg-size=65568081 --genesis-state /var/lib/prysm/prater/genesis.ssz
popd
