source .env

set -e

TARGET=$1

if [[ "$TARGET" == "" ]]
    then
        echo "No TARGET specified. Terminating"
        exit 1
fi
echo "Using target: $TARGET"


IMPLEMENTATION_SLOT="0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
LENSHUB=$(node script/helpers/readAddress.js $TARGET LensHubProxy)
PROXY_CONTRACT=$(node script/helpers/readAddress.js $TARGET ProxyAdminContract)
PROXY_CONTRACT_OWNER=$(cast call $PROXY_CONTRACT "owner()(address)")

cast rpc anvil_impersonateAccount $PROXY_CONTRACT_OWNER
cast send $PROXY_CONTRACT "proxy_upgrade(address)" "0xb4A26f55Cc2d1473b8A7649d90d34ba52A480391" --unlocked --from $PROXY_CONTRACT_OWNER

NEW_IMPLEMENTATION=$(cast parse-bytes32-address $(cast storage $LENSHUB $IMPLEMENTATION_SLOT))

echo "Successfully upgraded LensHub to $NEW_IMPLEMENTATION"

cast rpc anvil_stopImpersonatingAccount $PROXY_CONTRACT_OWNER
