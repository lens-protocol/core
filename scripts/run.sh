source .env

set -e

TARGET="devnet"

NETWORK=$(node scripts/helpers/readNetwork.js $TARGET)
if [[ "$NETWORK" == "" ]]
    then
        echo "No network found for $TARGET environment target in addresses.json. Terminating"
        exit 1
fi
echo "Using network: $NETWORK"

CALLDATA=$(cast calldata "run(string)" $TARGET)

echo "Interactions calldata:"
echo "$CALLDATA"

forge script scripts/$1.s.sol:$1 -s $CALLDATA --rpc-url $NETWORK -vvvvv

read -p "Please verify the data and confirm the interactions logs (y/n):" CONFIRMATION

if [[ "$CONFIRMATION" == "y" || "$CONFIRMATION" == "Y" ]]
    then
        echo "Broadcasting on-chain..."

        FORGE_OUTPUT=$(forge script scripts/$1.s.sol:$1 -s $CALLDATA --rpc-url $NETWORK --broadcast --legacy)
        echo "$FORGE_OUTPUT"
    else
        echo "Deployment cancelled. Execution terminated."
        exit 1
fi
