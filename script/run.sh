source .env

set -e

SCRIPT_NAME=$1
TARGET=$2

if [[ "$TARGET" == "" ]]
    then
        echo "No TARGET specified. Terminating"
        exit 1
fi
echo "Using target: $TARGET"

NETWORK=$(node script/helpers/readNetwork.js $TARGET)
if [[ "$NETWORK" == "" ]]
    then
        echo "No network found for $TARGET environment target in addresses.json. Terminating"
        exit 1
fi
echo "Using network: $NETWORK"

CALLDATA=$(cast calldata "run(string)" $TARGET)

echo "Interactions calldata:"
echo "$CALLDATA"

forge script script/$SCRIPT_NAME.s.sol:$SCRIPT_NAME -s $CALLDATA --rpc-url $NETWORK -vv --skip test --ffi

read -p "Please verify the data and confirm the interactions logs (y/n):" CONFIRMATION

if [[ "$CONFIRMATION" == "y" || "$CONFIRMATION" == "Y" ]]
    then
        echo "Broadcasting on-chain..."

        FORGE_OUTPUT=$(forge script script/$SCRIPT_NAME.s.sol:$SCRIPT_NAME -s $CALLDATA --rpc-url $NETWORK --broadcast --legacy --skip test --ffi --slow -vvvv)
        echo "$FORGE_OUTPUT"
    else
        echo "Deployment cancelled. Execution terminated."
        exit 1
fi
