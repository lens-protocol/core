# This script adds 10 Ether to the address specified in the first CLI argument

# Get the first CLI argument and save it to $ADDRESS variable
ADDRESS=$1

cast rpc --rpc-url mumbai tenderly_addBalance "[[\"$ADDRESS\"], \"0x8AC7230489E80000\"]" --raw

# cast rpc --rpc-url polygon anvil_autoImpersonateAccount "[true]" --raw
