#! /usr/bin/env bash

pushd $HOME/src/prysmaticlabs/prysm

bazel run //cmd/beacon-chain -c dbg -- \
--chain-config-file=$HOME/eth-envs/devnet5/config.yaml \
--genesis-state=$HOME/eth-envs/devnet5/genesis.ssz \
--bootstrap-node="enr:-MS4QAE2Kmmon8Hg5ibHl-AjURv6WwaQf_MzMdsUUTUNugH2dOTON7L__1HR7E1FAqfgaY4cFGbhXnwQTLvc4WchVigHh2F0dG5ldHOIAAAAAAAAAACEZXRoMpA9CJoRUEhEBf__________gmlkgnY0gmlwhIbRx2aJc2VjcDI1NmsxoQJFO5MitYs-ZTKYf2helrG1SR5AP1bSD5mJYsmn90nWd4hzeW5jbmV0c4gAAAAAAAAAAIN0Y3CCIyiDdWRwgiMo" \
--execution-endpoint=http://localhost:8551 \
--datadir=/var/lib/db/devnet5/prysm \
--accept-terms-of-use \
--enable-debug-rpc-endpoints \
--grpc-max-msg-size=65568081 \
--jwt-secret=$HOME/eth-envs/devnet5/jwt.hex \
--peer="enr:-MK4QJ_eqgSwL3CzFPN_b2dmH6eTb2JVOiq0riEdhGl6au2INPJZe27qAdz5IlESrUDL6K0mmDu-5djdhnN6eY_jc3GGAYhOxBFoh2F0dG5ldHOIAAAAAAAAAACEZXRoMpA9CJoRUEhEBf__________gmlkgnY0gmlwhKRc0dmJc2VjcDI1NmsxoQOP-QjAVjydOJdpFDT-4gMQ3cZH3M4KmY8sPP9dFzBgp4hzeW5jbmV0cwCDdGNwgiMog3VkcIIjKA" \
--peer="enr:-Ly4QAbPg_ls1dLuqwlhR67xW-QjaP-ZJcd6GqLNj0VwFNC2ImfrVgmcBaGc4w1XzO6NRDQ9-8_xNIWDbZ4_6VF15zcBh2F0dG5ldHOIAAAAAAAAAACEZXRoMpA9CJoRUEhEBf__________gmlkgnY0gmlwhKRc3oOJc2VjcDI1NmsxoQMU15mbdNg7PVulLU4s3LJF2ChqLRtTW96Q_fc7A6npvIhzeW5jbmV0cwCDdGNwgiMog3VkcIIjKA" \
--peer="enr:-L64QC9CHGQtVuKOdDqfKZ2keUbRRqWCoKWOZThjzI44P5dXYFsggIebFehAgotsTwShiXqOA34XvUbjxShXn6_ibHCCCJ6HYXR0bmV0c4j__________4RldGgykD0ImhFQSEQF__________-CaWSCdjSCaXCEhtHFfolzZWNwMjU2azGhA7_iA8nSvyuJwS-WLrk3ehcs4gBBuCoo3E-g_KWHT90iiHN5bmNuZXRzD4N0Y3CCIyiDdWRwgiMo" \
--peer="enr:-Ly4QMCITyvzu9A6e6lNQ5nA0wIlSVyNJYss5S6KqAQwaK83LQH2nXYpU03XMAZm1bpVbZMW6g_AgTunpyPZHbEhE-4Bh2F0dG5ldHOIAAAAAAAAAACEZXRoMpA9CJoRUEhEBf__________gmlkgnY0gmlwhKEjk9yJc2VjcDI1NmsxoQJfjHrA3bDejt2GUsQxuyml1XJ-dlmsxnH55OGs1k_DYIhzeW5jbmV0cwCDdGNwgiMog3VkcIIjKA" \
--log-file=/var/lib/db/devnet5/prysm/beacon.log

popd
