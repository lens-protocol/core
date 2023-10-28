# Read $CALLDATA from calldata.txt
CALLDATA=$(cat script/calldata.txt)

LENSHUB="0x7582177F9E536aB0b6c721e11f383C326F2Ad1D5"
GOVERNANCE="0x2e3d1ba5C11Ad2D672740934C14b3c632c01C5f6"
#GOVOWNER="0x532BbA5445e306cB83cF26Ef89842d4701330A45"

# cast send --rpc-url mumbai --unlocked --from $GOVOWNER $GOVERNANCE "executeAsGovernance(address,bytes)" $LENSHUB $CALLDATA
cast send --rpc-url mumbai --mnemonic-path mnemonic.txt --mnemonic-index 1 $GOVERNANCE "executeAsGovernance(address,bytes)" $LENSHUB $CALLDATA
