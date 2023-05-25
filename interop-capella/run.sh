#!/bin/bash
set -x
set -e

CHAINID=32382
GENESIS=$(($(date +%s) + 5))
echo "genesis time: $GENESIS"

#GETH=$HOME/src/mdehoog/go-ethereum/build/bin/geth
GETH=$HOME/src/ethereum/go-ethereum/build/bin/geth
SRCHOME=$HOME/src
PRYSMSRC=$SRCHOME/prysmaticlabs/prysm
SCRIPTDIR=$PWD # assumes this is run from the dir where the script lives

DATADIR=/var/lib/db/capella-interop/${GENESIS}
mkdir -p $DATADIR

CL_DATADIR_1=$DATADIR/cl-1
CL_DATADIR_2=$DATADIR/cl-2
GETHDATA_1=$DATADIR/el-1
mkdir -p $GETHDATA_1/keystore
GETHDATA_2=$DATADIR/el-2
mkdir -p $GETHDATA_2/keystore


LOGDIR=$DATADIR/logs
mkdir -p $LOGDIR
CL_LOGS_1=$LOGDIR/beacon-node_1.log
VAL_LOGS_1=$LOGDIR/validator_1.log
CL_LOGS_2=$LOGDIR/beacon-node_2.log
GETH_1_LOG=$LOGDIR/geth_1.log
GETH_2_LOG=$LOGDIR/geth_2.log
PID_FILE=$LOGDIR/run-pids
touch $PID_FILE
echo "pids written to $PID_FILE"

# clean up all the processes on sigint
trap cleanup INT
trap cleanup EXIT
function cleanup() {
	$(cat $PID_FILE | cut -d' ' -f1 | xargs kill $1)
}

function log_pid() {
	SHELL_PID=$1
	PROC_NAME=$2
	OUTER_PID=$(ps -o pid,cmd --ppid=$SHELL_PID | grep 'run.sh' | tail -n1 | awk '{ print $1 }')
	GO_PID=$(ps --ppid=$OUTER_PID | tail -n1 | awk '{ print $1 }')
	echo "$GO_PID # $PROC_NAME" >> $PID_FILE
	echo "$GO_PID"
}

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

SHANGHAI=$(($GENESIS))
echo "shanghai fork time: $SHANGHAI"

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

$CTL_CMD testnet generate-genesis \
	--num-validators=256 --output-ssz=$DATADIR/genesis.ssz \
	--chain-config-file=$DATADIR/config.yml --genesis-time=$GENESIS \
	--fork=capella --geth-genesis-json-in=$DATADIR/genesis.json --geth-genesis-json-out=$DATADIR/genesis.json \
	1> $LOGDIR/prysmctl-genesis.stdout 2> $LOGDIR/prymctl-genesis.stderr

echo "beacon-node 1 logs at $CL_LOGS_1"
setsid $($BC_CMD \
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
	--suggested-fee-recipient=0x0000000000000000000000000000000000000000 --verbosity=debug \
	1> $LOGDIR/beacon-1.stdout 2> $LOGDIR/beacon-1.stderr) &
PID_BN1=$!
log_pid $PID_BN1 "beacon node 1"

echo "validator 1 logs at $VAL_LOGS_1"
setsid $($V_CMD \
	--datadir=$CL_DATADIR_1 \
	--log-file=$VAL_LOGS_1 \
        --accept-terms-of-use \
        --interop-num-validators=256 \
        --interop-start-index=0 \
	--chain-config-file=$DATADIR/config.yml \
	1> $LOGDIR/validator-1.stdout 2> $LOGDIR/validator-2.stderr) &
PID_V1=$!
log_pid $PID_V1 "validator 1"

echo "geth logs at $GETH_1_LOG"
$GETH --datadir $GETHDATA_1 init $DATADIR/genesis.json 1> $LOGDIR/geth-init_1.stdout 2> $LOGDIR/geth-init_1.stderr
setsid $($GETH \
	--log.file=$GETH_1_LOG \
	--http \
        --datadir=$GETHDATA_1 \
        --nodiscover \
        --syncmode=full \
        --allow-insecure-unlock \
        --unlock=0x123463a4b065722e99115d6c222f267d9cabb524 \
        --password=$GETH_PASSWORD_FILE \
        --mine \
	--authrpc.port=8551 \
	--authrpc.jwtsecret=$JWT_PATH \
	--miner.etherbase=0x123463a4b065722e99115d6c222f267d9cabb524 console \
	1> $LOGDIR/geth-1.stdout 2> $LOGDIR/geth-1.stderr) &
PID_GETH_1=$!
log_pid $PID_GETH_1 "geth 1"

# 5 is added as a minimum wait amount, because when shanghai and cancun are both zero,
# geth + prysm need a few seconds to start up and call FCU before geth will fork and
# accept blob txs.
WAITTIME=$((38 + $SHANGHAI - $(date +%s)))
echo "sleeping $WAITTIME seconds to wait for geth to fork"
sleep $WAITTIME

ADDR_BN1=$(grep 'Node started p2p server' $CL_LOGS_1 | sed -E 's/.*multiAddr=\"(.*)\" prefix=.*/\1/')
echo "beacon-node 2 will peer with beacon-node 1 multiaddr = $ADDR_BN1"

echo "beacon-node 2 logs at $CL_LOGS_2"
setsid $($BC_CMD \
	--log-file=$CL_LOGS_2 \
	--datadir=$CL_DATADIR_2 \
        --min-sync-peers=1 \
        --genesis-state=$DATADIR/genesis.ssz \
        --interop-eth1data-votes \
        --bootstrap-node= \
        --chain-config-file=$DATADIR/config.yml \
        --chain-id=$CHAINID \
        --accept-terms-of-use \
        --jwt-secret=$JWT_PATH \
        --execution-endpoint=http://localhost:8552 \
        --rpc-port=4002 \
        --p2p-tcp-port=13002 \
        --p2p-udp-port=12002 \
        --grpc-gateway-port=3502 \
        --monitoring-port=8083 \
	--force-clear-db \
	--verbosity=debug \
	--peer=$ADDR_BN1 \
	1> $LOGDIR/beacon-2.stdout 2> $LOGDIR/beacon-2.stderr) &
PID_BN2=$!
PID_BN2=$(log_pid $PID_BN2 "beacon node 2")

echo "geth2 logs at $GETH_2_LOG"
$GETH --datadir $GETHDATA_2 init $DATADIR/genesis.json 1> $LOGDIR/geth-init_2.stdout 2> $LOGDIR/geth-init_2.stderr
setsid $($GETH \
	--log.file=$GETH_2_LOG \
	--http \
        --datadir=$GETHDATA_2 \
        --nodiscover \
        --syncmode=full \
        --allow-insecure-unlock \
        --unlock=0x123463a4b065722e99115d6c222f267d9cabb524 \
        --password=$GETH_PASSWORD_FILE \
	--authrpc.jwtsecret=$JWT_PATH \
	--authrpc.port=8552 \
	--http.port=8546 \
	--port=30304 \
	1> $LOGDIR/geth-2.stdout 2> $LOGDIR/geth-2.stderr) &
PID_GETH_2=$!
log_pid $PID_GETH_2 "geth 2"

sleep 1

#echo "attaching dlv to bn2 pid $PID_BN2 at port 2345"
#setsid $(dlv --listen=:2345 --headless=true --api-version=2 attach $PID_BN2 1> $LOGDIR/dlv.stdout 2> $LOGDIR/dlv.stderr) &
#PID_DLV=$!
#log_pid $PID_DLV "dlv connected to bn2"

echo "sleeping until infinity or ctrl+c, whichever comes first"
sleep infinity

