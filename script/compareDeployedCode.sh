# This script compares the Source code differences before/after the upgrade ("old"/"new" implementations).
# The addresses are provided in command line.
# The source code is fetched from the block explorer.
source .env

if [[ $(colordiff --help 2>/dev/null) ]]
then
    shopt -s expand_aliases
    alias diff='colordiff'
    echo "Detected colordiff - using it"
fi

if [[ $1 == "" ]]
    then
        echo "This script compares the code of two deployed contracts"
        echo "Used during upgrades to make sure which changes actually were made"
        echo ""
        echo "Usage:"
        echo "  compareDeployedCode.sh [target] [address1] [address2]"
        echo "    e.g. target (required): mainnet/testnet/sandbox"
        echo "             first address: address of the first deployed Contract"
        echo "            second address: address of the second deployed Contract"
        echo ""
        echo "Example:"
        echo "    compareDeployedCode.sh mainnet 0x12...34 0x56...78"
        exit 1
fi

TARGET=$1
FIRST_ADDRESS=$2
SECOND_ADDRESS=$3

NETWORK=$(node script/helpers/readNetwork.js $TARGET)
if [[ $NETWORK == "" ]]
    then
        echo "No network found for $TARGET environment target in addresses.json. Terminating"
        exit 1
fi

if [[ $NETWORK == "mumbai" ]]
    then
        NETWORK="polygon-mumbai"
fi

echo "Network: $NETWORK $TARGET"
echo "Fetching code..."

# Fetching the first contract source code and saving it to a folder
rm -rf deployedCode_$FIRST_ADDRESS
cast etherscan-source -d deployedCode_$FIRST_ADDRESS $FIRST_ADDRESS --chain $NETWORK
echo "First contract code saved to ./deployedCode_$FIRST_ADDRESS/"

# Fetching the second contract source code and saving it to a folder
rm -rf deployedCode_$SECOND_ADDRESS
cast etherscan-source -d deployedCode_$SECOND_ADDRESS $SECOND_ADDRESS --chain $NETWORK
echo "Second contract code saved to ./deployedCode_$SECOND_ADDRESS/"

echo ""
echo "Differences:"
echo "------------"

diff -qr deployedCode_$FIRST_ADDRESS deployedCode_$SECOND_ADDRESS | sort

echo "------------"
echo ""

read -p "Show detailed differences in these files? (y/n):" CONFIRMATION
if [[ "$CONFIRMATION" == "y" || "$CONFIRMATION" == "Y" ]]
    then
        echo ""
        echo "------------"
        echo ""

        diff -rub deployedCode_$FIRST_ADDRESS/ deployedCode_$SECOND_ADDRESS/

        echo ""
        echo "------------"
        echo ""
fi

read -p "Delete fetched sources? (y/n):" CONFIRMATION
if [[ "$CONFIRMATION" == "y" || "$CONFIRMATION" == "Y" ]]
    then
        rm -rf deployedCode_$FIRST_ADDRESS
        rm -rf deployedCode_$SECOND_ADDRESS
fi
