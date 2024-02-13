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
echo "LensHub Proxy: $LENSHUB"

LENSHUB_NEW_IMPL=$(node script/helpers/readAddress.js $TARGET LensHubV2Impl)
echo "LensHub New Impl: $LENSHUB_NEW_IMPL"

EXISTING_IMPLEMENTATION=$(cast parse-bytes32-address $(cast storage $LENSHUB $IMPLEMENTATION_SLOT))

if [[ "$EXISTING_IMPLEMENTATION" == "$LENSHUB_NEW_IMPL" ]]
    then
        echo "LensHub already upgraded to $LENSHUB_NEW_IMPL"
        exit 0
fi

PROXY_CONTRACT=$(node script/helpers/readAddress.js $TARGET ProxyAdminContract)
echo "ProxyAdminContract: $PROXY_CONTRACT"

PROXY_CONTRACT_OWNER=$(cast call $PROXY_CONTRACT "owner()(address)")
echo "ProxyAdminContract owner: $PROXY_CONTRACT_OWNER"

echo "ProxyAdminContract Owner balance: $(cast balance $PROXY_CONTRACT_OWNER)"

cast rpc anvil_setBalance "[\"$PROXY_CONTRACT_OWNER\", \"0x8AC7230489E800000000\"]" --raw

echo "ProxyAdminContract Owner balance: $(cast balance $PROXY_CONTRACT_OWNER)"

GOVERNANCE_CONTRACT=$(node script/helpers/readAddress.js $TARGET GovernanceContract)
echo "GovernanceContract: $GOVERNANCE_CONTRACT"

GOVERNANCE_CONTRACT_OWNER=$(cast call $GOVERNANCE_CONTRACT "owner()(address)")
echo "GovernanceContract owner: $GOVERNANCE_CONTRACT_OWNER"

echo "GovernanceContract Owner balance: $(cast balance $GOVERNANCE_CONTRACT_OWNER)"

cast rpc anvil_setBalance "[\"$GOVERNANCE_CONTRACT_OWNER\", \"0x8AC7230489E800000000\"]" --raw

echo "GovernanceContract Owner balance: $(cast balance $GOVERNANCE_CONTRACT_OWNER)"

PERMISSIONLESS_CREATOR=$(node script/helpers/readAddress.js $TARGET PermissionlessCreator)
echo "PermissionlessCreator: $PERMISSIONLESS_CREATOR"

cast rpc anvil_impersonateAccount $PROXY_CONTRACT_OWNER
cast send $PROXY_CONTRACT "proxy_upgrade(address)" "$LENSHUB_NEW_IMPL" --unlocked --from $PROXY_CONTRACT_OWNER --legacy

NEW_IMPLEMENTATION=$(cast parse-bytes32-address $(cast storage $LENSHUB $IMPLEMENTATION_SLOT))

if [[ "$NEW_IMPLEMENTATION" == "$LENSHUB_NEW_IMPL" ]]
    then
        echo "LensHub successfully upgraded to $NEW_IMPLEMENTATION"
    else
        echo "LensHub upgrade failed. Expected $LENSHUB_NEW_IMPL, got $NEW_IMPLEMENTATION"
        exit 1
fi

# cast send 0x0b5e6100243f793e480DE6088dE6bA70aA9f3872 "upgradeTo(address)" "0x9f077d03DBf4aB8c68e181baA3308F3B12C52Ae8" --unlocked --from $PROXY_CONTRACT_OWNER --legacy

cast rpc anvil_stopImpersonatingAccount $PROXY_CONTRACT_OWNER

cast rpc anvil_impersonateAccount $GOVERNANCE_CONTRACT_OWNER
cast send $GOVERNANCE_CONTRACT "lensHub_whitelistProfileCreator(address,bool)" $PERMISSIONLESS_CREATOR true --unlocked --from $GOVERNANCE_CONTRACT_OWNER --legacy
cast rpc anvil_stopImpersonatingAccount $GOVERNANCE_CONTRACT_OWNER

cast rpc anvil_mine

cast rpc anvil_mine
