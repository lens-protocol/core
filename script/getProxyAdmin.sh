source .env

if [[ $1 == "" ]]
    then
        echo "Usage:"
        echo "  bash getProxyAdmin.sh [address]"
        echo "       Where [address] is the TransparentUpgradeableProxy address"
        exit 1
fi

# TransparentUpgradeableProxy implementation slot
adminSlot="0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103"

rawOldImplAddress=$(cast storage $1 $adminSlot --rpc-url $POLYGON_RPC_URL)

echo "Admin of $1 TransparentUpgradeableProxy is:"
echo "0x${rawOldImplAddress:26}"
