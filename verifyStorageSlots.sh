# This script compares the Storage Layout differences before/after the upgrade ("old"/"new" implementations).
# The address of previous implentation if fetched from TransparentProxy "implementation()" slot.
# The previous implementation source code is fetched from the block explorer.
# New implementation is assumed to be in the current repo
# Storage Layouts are generated from both implementations and compared using diff
# (It is normal for the numbers in end of type names to be different)
source .env

if [[ $1 == "" ]]
    then
        echo "Usage:"
        echo "  verifyStorageSlots.sh [network] [contractName]"
        echo "    e.g. network (required): polygon or mumbai"
        echo "    e.g. contractName (optional): LensHub is default"
        echo ""
        echo "Example:"
        echo "    verifyStorageSlots.sh polygon LensHub"
        exit 1
fi

# TransparentUpgradeableProxy implementation slot
implementationSlot="0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"

if [[ $2 != "" ]]
    then
        contractName=$2
    else
        contractName="LensHub"
fi

case $1 in
    'polygon' | 'matic')
        echo "Network: Polygon mainnet"
        rpcUrl=$POLYGON_RPC_URL
        proxyAddress=$LENS_HUB_POLYGON
        blockexplorerKey=$POLYGONSCAN_MAINNET_KEY
        chain='polygon'
        ;;
    'mumbai')
        echo "Network: Polygon mainnet"
        rpcUrl=$MUMBAI_RPC_URL
        proxyAddress=$LENS_HUB_MUMBAI
        blockexplorerKey=$POLYGONSCAN_MUMBAI_KEY
        chain='mumbai'
        ;;
    *)
        echo "ERROR: Unsupported network"
        exit 1
        ;;
esac

echo "Proxy address:" $proxyAddress
echo "Contract name:" $contractName

# Fetching the old implementation address
rawOldImplAddress=$(cast storage $proxyAddress $implementationSlot --rpc-url $rpcUrl)
oldImplAddress="0x${rawOldImplAddress:(-40)}"
echo "Old Implementation address: $oldImplAddress"

# Fetching the old implementation source code and saving it to oldImpl folder
rm -rf oldImpl
cast etherscan-source -d oldImpl $oldImplAddress --chain $chain --etherscan-api-key $blockexplorerKey
echo "Old Implementation code saved to ./oldImpl/"

# Generating the Storage Layout JSON of the old implementation
echo "Generating the Storage Layout JSON of the old implementation..."
forge inspect $contractName storage --contracts oldImpl > oldImplStorageLayout.json

# Generating the Storage Layout JSON of the new implementation
echo "Generating the Storage Layout JSON of the new implementation..."
forge inspect $contractName storage > newImplStorageLayout.json

diff <(awk '/astId/{next} /"types"/{found=0} {if(found) print} /"storage"/{found=1}' oldImplStorageLayout.json) <(awk '/astId/{next} /"types"/{found=0} {if(found) print} /"storage"/{found=1}' newImplStorageLayout.json) -c
