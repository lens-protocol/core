rm -rf svgs
mkdir svgs
cd svgs
mkdir background
mkdir skin
mkdir legs
mkdir shoes
mkdir faces
mkdir body
mkdir logo
mkdir headwear
mkdir profiles_gold
mkdir profiles
mkdir profiles_fuzz
mkdir profiles_fuzz_json
mkdir follows
mkdir handles
cd ..

forge test --match-path "script/svg/FollowSVGGen.t.sol" --no-match-path ""
forge test --match-path "script/svg/HandleSVGGen.t.sol" --no-match-path ""
forge test --match-path "script/svg/ProfileSVGGen.t.sol" --no-match-path ""
