#!/bin/bash
#set -x
set -e

CHAINID=32382
GENESIS=$(($(date +%s) + 5))
echo "genesis time: $GENESIS"

GETH=$HOME/src/mdehoog/go-ethereum/build/bin/geth
PRYSMSRC=$HOME/src/prysmaticlabs/prysm
SCRIPTDIR=$PWD # assumes this is run from the dir where the script lives

DATADIR=/var/lib/db/deneb-interop-${GENESIS}
mkdir -p $DATADIR

CL_DATADIR_1=$DATADIR/cl-1
CL_DATADIR_2=$DATADIR/cl-2
GETHDATA=$DATADIR/el-1
mkdir -p $GETHDATA/keystore

LOGDIR=$DATADIR/logs
mkdir -p $LOGDIR
CL_LOGS_1=$LOGDIR/beacon-node_1.log
VAL_LOGS_1=$LOGDIR/validator_1.log
CL_LOGS_2=$LOGDIR/beacon-node_2.log
GETH_LOG=$LOGDIR/geth.log

echo "all logs and stdout/err for each program redirected to log dir = $LOGDIR"

JWT_PATH=$DATADIR/jwt.secret
cp $SCRIPTDIR/jwt.secret $JWT_PATH
cp $SCRIPTDIR/genesis.json $DATADIR/genesis.json
cp $SCRIPTDIR/config.yml $DATADIR/config.yml
cp $SCRIPTDIR/config.yml $DATADIR/config.yml

cp $SCRIPTDIR/keystore/* $GETHDATA/keystore
GETH_PASSWORD_FILE=$DATADIR/geth_password.txt
cp $SCRIPTDIR/geth_password.txt $GETH_PASSWORD_FILE

SHANGHAI=$(($GENESIS + 108))
sed -i  -e 's/XXX/'$SHANGHAI'/' $DATADIR/genesis.json
echo "shanghai fork time: $SHANGHAI"
CANCUN=$(($GENESIS + 144))
sed -i  -e 's/YYY/'$CANCUN'/' $DATADIR/genesis.json
echo "cancun fork time: $CANCUN"

pushd $PRYSMSRC
bazel run //cmd/prysmctl -- testnet generate-genesis --num-validators=256 --output-ssz=$DATADIR/genesis.ssz --chain-config-file=$DATADIR/config.yml --genesis-time=$GENESIS 1> $LOGDIR/prysmctl-genesis.stdout 2> $LOGDIR/prymctl-genesis.stderr

echo "beacon-node 1 logs at $CL_LOGS_1"
setsid $(bazel run //cmd/beacon-chain -- \
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
	--suggested-fee-recipient=0x0000000000000000000000000000000000000000 --verbosity=debug \
	1> $LOGDIR/beacon-1.stdout 2> $LOGDIR/beacon-1.stderr) &
echo "beacon-node 1 pid = $!"

echo "validator 1 logs at $VAL_LOGS_1"
setsid $(bazel run //cmd/validator -- \
	--datadir=$CL_DATADIR_1 \
	--log-file=$VAL_LOGS_1 \
        --accept-terms-of-use \
        --interop-num-validators=256 \
        --interop-start-index=0 \
	--chain-config-file=$DATADIR/config.yml \
	1> $LOGDIR/validator-1.stdout 2> $LOGDIR/validator-2.stderr) &
echo "validator 1 pid = $!"

echo "geth logs at $GETH_LOG"
$GETH --datadir $GETHDATA init $DATADIR/genesis.json 1> $LOGDIR/geth-init.stdout 2> $LOGDIR/geth-init.stderr
setsid $($GETH \
	--log.file=$GETHDATA/geth.log \
	--http \
        --datadir=$GETHDATA \
        --nodiscover \
        --syncmode=full \
        --allow-insecure-unlock \
        --unlock=0x123463a4b065722e99115d6c222f267d9cabb524 \
        --password=$GETH_PASSWORD_FILE \
        --mine \
	--authrpc.jwtsecret=$JWT_PATH \
	--miner.etherbase=0x123463a4b065722e99115d6c222f267d9cabb524 console \
	1> $LOGDIR/geth-1.stdout 2> $LOGDIR/geth-2.stderr) &
echo "geth pid = $!"

WAITTIME=$(($CANCUN - $(date +%s)))
echo "sleeping $WAITTIME seconds to wait for cancun fork"
sleep $WAITTIME

setsid $(bazel run //cmd/beacon-chain -- \
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
  	--rpc-port=4001 \
  	--p2p-tcp-port=13001 \
	--p2p-udp-port=12001 \
	--grpc-gateway-port=3501 \
	--monitoring-port=8082 \
	--force-clear-db \
	--verbosity=debug \
	1> $LOGDIR/beacon-2.stdout 2> $LOGDIR/beacon-2.stderr) &
echo "beacon-node 2 pid = $!"

echo "sleeping until infinity or ctrl+c, whichever comes first"
sleep infinity

# ~/blob-utils master* ❯ ./blob-utils tx --blob-file ~/Desktop/test.png  --private-key 2e0834786285daccd064ca17f1654f67b4aef298acbb82cef9ec422fb4975622 --to 0x0 --gas-price 100000000000 --gas-limit 1000000 --chain-id $CHAINID --rpc-url http://localhost:8545
