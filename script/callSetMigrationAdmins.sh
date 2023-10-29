# Read $CALLDATA from calldata.txt
CALLDATA=$(cat script/calldata.txt)

LENSHUB="0x60Ae865ee4C725cd04353b5AAb364553f56ceF82"
GOVERNANCE="0xB03B8801cF9D074Ea468aAA8eBd9B5EeD67Ac5B6" # Governance contract
#GOVOWNER="0x532BbA5445e306cB83cF26Ef89842d4701330A45" # Governance contract's owner

# cast send --rpc-url mumbai --unlocked --from $GOVOWNER $GOVERNANCE "executeAsGovernance(address,bytes)" $LENSHUB $CALLDATA
cast send --rpc-url mumbai --mnemonic-path mnemonic.txt --mnemonic-index 1 $GOVERNANCE "executeAsGovernance(address,bytes)" $LENSHUB $CALLDATA
