#!/usr/bin/env bash

contracts=$(forge script scripts/Deploy.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 -s "run(address,address)" 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc)
contracts=$(echo $contracts | sed -n 's/== Return ==\(.*\)/\1/p')

echo $contracts;
