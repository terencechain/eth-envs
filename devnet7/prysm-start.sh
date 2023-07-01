#! /usr/bin/env bash

ETHENVS=/home/kasey/src/kasey/eth-envs/devnet7
ENVRUN=/var/lib/db/devnet7

pushd $HOME/src/prysmaticlabs/prysm

bazel run //cmd/beacon-chain -c dbg -- \
--chain-config-file=${ETHENVS}/config.yaml \
--contract-deployment-block=0 \
--min-sync-peers=1 \
--verbosity=debug \
--subscribe-all-subnets \
--genesis-state=${ETHENVS}/genesis.ssz \
--bootstrap-node=enr:-Iq4QBskSEWq0jSk12p8nNe5OYUVcWBpGJEqODbpl8YWMgaDfrmZ6mzc24B1_j7gGqQOoiUI0TOxD9Q3G0tYm33WtXKGAYkL4s02gmlkgnY0gmlwhM69aUyJc2VjcDI1NmsxoQPZLBX2rEiQ20AfN2f1SQLfnGMQd_t7Rq0-HNkYA9d4uoN1ZHCCIyk \
--bootstrap-node=enr:-MS4QCmm0gqL1vXvgB4tES2uzLrTPU_A8U0b-qhBltSIFOd0Jj8k0M3UcwsHbc6jQB4gv1CVVbcjmUPY9bHDjgxAY4UHh2F0dG5ldHOIAAAAAAAAAACEZXRoMpAmnuLCQHFGOQUAAAAAAAAAgmlkgnY0gmlwhM69aUyJc2VjcDI1NmsxoQKHgIEQ_if0loI5NE2FGtAfxM0y_iLBTVuOye6Y3zn6tYhzeW5jbmV0c4gAAAAAAAAAAIN0Y3CCIyiDdWRwgiMo \
--execution-endpoint=http://localhost:8551 \
--datadir=${ENVRUN}/prysm \
--accept-terms-of-use \
--enable-debug-rpc-endpoints \
--grpc-max-msg-size=65568081 \
--jwt-secret=${ETHENVS}/jwt.hex \
--log-file=${ENVRUN}/prysm/beacon.log

popd

