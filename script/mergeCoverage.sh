lcov -a lcov.info -a coverage/lcov.info -o lcov_merged.info
lcov -r lcov_merged.info 'test/*' '*contracts/core/modules/collect/*' '*contracts/core/modules/deprecated/*' '*contracts/core/modules/follow/*' '*contracts/core/modules/reference/*' '*contracts/core/modules/*Base.sol' '*contracts/mocks/*' -o lcov_merged_clean.info
genhtml lcov_merged_clean.info --rc lcov_branch_coverage=1 -o coverage_merged -s
