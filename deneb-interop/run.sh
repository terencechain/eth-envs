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
SCRIPTDIR=/Users/t/eth-envs/deneb-interop # TODO: change this to your eth-ens dir

DATADIR=/Users/t/deneb-interop/${GENESIS} # TODO: change this to your tmp dir for logging and data
mkdir -p $DATADIR

CL_DATADIR_1=$DATADIR/cl-1
GETHDATA_1=$DATADIR/el-1
mkdir -p $GETHDATA_1/keystore

LOGDIR=$DATADIR/logs
mkdir -p $LOGDIR
CL_LOGS_1=$LOGDIR/beacon-node_1.log
VAL_LOGS_1=$LOGDIR/validator_1.log
GETH_1_LOG=$LOGDIR/geth_1.log
PID_FILE=$LOGDIR/run-pids

echo "all logs and stdout/err for each program redirected to log dir = $LOGDIR"

JWT_PATH=$DATADIR/jwt.secret
cp $SCRIPTDIR/jwt.secret $JWT_PATH
cp $SCRIPTDIR/genesis.json $DATADIR/genesis.json
cp $SCRIPTDIR/config.yml $DATADIR/config.yml
cp $SCRIPTDIR/config.yml $DATADIR/config.yml

cp $SCRIPTDIR/keystore/* $GETHDATA_1/keystore
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
	1> $LOGDIR/validator-1.stdout 2> $LOGDIR/validator-2.stderr &
