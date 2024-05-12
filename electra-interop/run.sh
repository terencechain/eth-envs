#!/bin/bash
set -x
set -e

CHAINID=32382
PRYSMSRC=/Users/t/go/src/github.com/prysmaticlabs/prysm # TODO: change this to your prysm source dir

# do the slow build stuff before computing genesis time
pushd $PRYSMSRC

INTEROP_BIN=$PRYSMSRC/interop-bin
mkdir -p $INTEROP_BIN

bazel build //cmd/prysmctl -c dbg
BAZEL_CTL_CMD=$PRYSMSRC/bazel-bin/cmd/prysmctl/prysmctl_/prysmctl
CTL_CMD=$INTEROP_BIN/prysmctl
cp -f $BAZEL_CTL_CMD $CTL_CMD

bazel build //cmd/beacon-chain -c dbg
BAZEL_BC_CMD=$PRYSMSRC/bazel-bin/cmd/beacon-chain/beacon-chain_/beacon-chain
BC_CMD=$INTEROP_BIN/beacon-chain
cp -f $BAZEL_BC_CMD $BC_CMD

bazel build //cmd/validator -c dbg
BAZEL_V_CMD=$PRYSMSRC/bazel-bin/cmd/validator/validator_/validator
V_CMD=$INTEROP_BIN/validator
cp -f $BAZEL_V_CMD $V_CMD

GENESIS=$(($(date +%s) + 30))
echo "genesis time: $GENESIS"

GETHEXE=/Users/t/go/src/github.com/lightclient/go-ethereum/build/bin/geth # TODO: change this to your geth binary
SCRIPTDIR=/Users/t/eth-envs/electra-interop # TODO: change this to your eth-ens dir

DATADIR=/Users/t/electra-interop/${GENESIS} # TODO: change this to your tmp dir for logging and data
mkdir -p $DATADIR

CL_DATADIR_1=$DATADIR/cl-1
GETHDATA_1=$DATADIR/el-1
mkdir -p $GETHDATA_1/keystore

CL_DATADIR_2=$DATADIR/cl-2
GETHDATA_2=$DATADIR/el-2
mkdir -p $GETHDATA_2/keystore


LOGDIR=$DATADIR/logs
mkdir -p $LOGDIR
CL_LOGS_1=$LOGDIR/beacon-node_1.log
VAL_LOGS_1=$LOGDIR/validator_1.log
GETH_1_LOG=$LOGDIR/geth_1.log
#CL_LOGS_2=$LOGDIR/beacon-node_2.log
#VAL_LOGS_2=$LOGDIR/validator_2.log
#GETH_2_LOG=$LOGDIR/geth_2.log
#PID_FILE=$LOGDIR/run-pids

echo "all logs and stdout/err for each program redirected to log dir = $LOGDIR"

JWT_PATH=$DATADIR/jwt.secret
cp $SCRIPTDIR/jwt.secret $JWT_PATH
cp $SCRIPTDIR/genesis.json $DATADIR/genesis.json
cp $SCRIPTDIR/config.yml $DATADIR/config.yml
cp $SCRIPTDIR/config.yml $DATADIR/config.yml

cp $SCRIPTDIR/keystore/* $GETHDATA_1/keystore
cp $SCRIPTDIR/keystore/* $GETHDATA_2/keystore
GETH_PASSWORD_FILE=$DATADIR/geth_password.txt
cp $SCRIPTDIR/geth_password.txt $GETH_PASSWORD_FILE

pushd $PRYSMSRC

$CTL_CMD testnet generate-genesis \
	--num-validators=256 --output-ssz=$DATADIR/genesis.ssz \
	--chain-config-file=$DATADIR/config.yml --genesis-time=$GENESIS \
	--fork=capella --geth-genesis-json-in=$DATADIR/genesis.json --geth-genesis-json-out=$DATADIR/genesis.json \
	1> $LOGDIR/prysmctl-genesis.stdout 2> $LOGDIR/prymctl-genesis.stderr


$BC_CMD \
	--datadir=$CL_DATADIR_1 \
	--log-file=$CL_LOGS_1 \
        --min-sync-peers=0 \
        --genesis-state=$DATADIR/genesis.ssz \
        --interop-eth1data-votes \
        --bootstrap-node= \
        --chain-config-file=$DATADIR/config.yml \
        --chain-id=$CHAINID \
        --accept-terms-of-use \
        --jwt-secret=$JWT_PATH \
	--execution-endpoint=http://localhost:8551 \
	--suggested-fee-recipient=0x1000000000000000000000000000000000000000 --verbosity=debug \
	1> $LOGDIR/beacon-1.stdout 2> $LOGDIR/beacon-1.stderr &

$GETHEXE --datadir $GETHDATA_1 init $DATADIR/genesis.json 1> $LOGDIR/geth-init_1.stdout
$GETHEXE \
	--log.file=$GETH_1_LOG \
	--http \
        --datadir=$GETHDATA_1 \
        --nodiscover \
        --syncmode=full \
        --allow-insecure-unlock \
        --unlock=0x123463a4b065722e99115d6c222f267d9cabb524 \
        --password=$GETH_PASSWORD_FILE \
	--authrpc.port=8551 \
	--authrpc.jwtsecret=$JWT_PATH \
	1> $LOGDIR/geth-1.stdout 2> $LOGDIR/geth-1.stderr &

$V_CMD \
	--datadir=$CL_DATADIR_1 \
	--log-file=$VAL_LOGS_1 \
        --accept-terms-of-use \
        --interop-num-validators=256 \
        --interop-start-index=0 \
	--chain-config-file=$DATADIR/config.yml \
        --pprof \
	1> $LOGDIR/validator-1.stdout 2> $LOGDIR/validator-2.stderr &


#sleep 400 # until cancun fork
#
#ADDR_BN1=$(grep 'Node started p2p server' $CL_LOGS_1 | sed -E 's/.*multiAddr=\"(.*)\" prefix=.*/\1/')
#echo "beacon-node 2 will peer with beacon-node 1 multiaddr = $ADDR_BN1"
#
#echo "beacon-node 2 logs at $CL_LOGS_2"
#$BC_CMD \
#	--log-file=$CL_LOGS_2 \
#	--datadir=$CL_DATADIR_2 \
#        --min-sync-peers=1 \
#        --genesis-state=$DATADIR/genesis.ssz \
#        --interop-eth1data-votes \
#        --bootstrap-node= \
#        --chain-config-file=$DATADIR/config.yml \
#        --chain-id=$CHAINID \
#        --accept-terms-of-use \
#        --jwt-secret=$JWT_PATH \
#        --execution-endpoint=http://localhost:8552 \
#        --rpc-port=4002 \
#        --p2p-tcp-port=13002 \
#        --p2p-udp-port=12002 \
#        --grpc-gateway-port=3502 \
#        --monitoring-port=8083 \
#	--force-clear-db \
#	--verbosity=debug \
#	--peer=$ADDR_BN1 \
#	1> $LOGDIR/beacon-2.stdout 2> $LOGDIR/beacon-2.stderr &
#
#echo "geth2 logs at $GETH_2_LOG"
#$GETHEXE --datadir $GETHDATA_2 init $DATADIR/genesis.json 1> $LOGDIR/geth-init_2.stdout 2> $LOGDIR/geth-init_2.stderr
#$GETHEXE \
#	--log.file=$GETH_2_LOG \
#	--http \
#        --datadir=$GETHDATA_2 \
#        --nodiscover \
#        --syncmode=full \
#        --allow-insecure-unlock \
#        --unlock=0x123463a4b065722e99115d6c222f267d9cabb524 \
#        --password=$GETH_PASSWORD_FILE \
#	--authrpc.jwtsecret=$JWT_PATH \
#	--authrpc.port=8552 \
#	--http.port=8546 \
#	--port=30304 \
#	1> $LOGDIR/geth-2.stdout 2> $LOGDIR/geth-2.stderr &

