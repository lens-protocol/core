source .env

set -e

if [[ $(colordiff --help 2>/dev/null) ]]
then
    shopt -s expand_aliases
    alias diff='colordiff'
    echo "Detected colordiff - using it"
fi

if [[ "$1" == "" || "$2" == "" || "$2" == "" ]]
    then
        echo "This script compares two onchain deployed bytecodes"
        echo "Can be useful to compare old and new implementations"
        echo ""
        echo "Usage:"
        echo "  compareDeployedBytecodes.sh [target environment] [address1] [address2]"
        echo "    where"
        echo "               target environment: mainnet / testnet / sandbox"
        echo "                    first address: address of the first deployed Contract"
        echo "                   second address: address of the second deployed Contract"
        echo ""
        echo "Example:"
        echo "  verifyDeployedBytecode.sh sandbox 0x12...34 0x56...78"
        exit 1
fi

TARGET=$1
FIRST_ADDRESS=$2
SECOND_ADDRESS=$3

NETWORK=$(node script/helpers/readNetwork.js $TARGET)
if [[ "$NETWORK" == "" ]]
    then
        echo "No network found for $TARGET environment target in addresses.json. Terminating"
        exit 1
fi

echo "Getting bytecode of $FIRST_ADDRESS on ${TARGET}/${NETWORK}"
cast code --rpc-url $NETWORK $FIRST_ADDRESS | fold -w 80 > bytecode_$FIRST_ADDRESS.txt

echo "Getting bytecode of $SECOND_ADDRESS on ${TARGET}/${NETWORK}"
cast code --rpc-url $NETWORK $SECOND_ADDRESS | fold -w 80 > bytecode_$SECOND_ADDRESS.txt


diff bytecode_$FIRST_ADDRESS.txt bytecode_$SECOND_ADDRESS.txt -c || true

echo ""
echo "------------------------------"
echo ""
echo "Bytecodes saved as:"
echo "  bytecode_$FIRST_ADDRESS.txt"
echo "  bytecode_$SECOND_ADDRESS.txt"
echo ""
echo "Use and diff tool of your favor to compare these"
echo ""
echo "When using different compiler/optimizer settings - bytecodes can be completely different"
