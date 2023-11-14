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
mkdir follows
mkdir handles
cd ..

forge script script/svg/FollowSVGGen.s.sol:FollowSVGGen
forge script script/svg/HandleSVGGen.s.sol:HandleSVGGen
forge script script/svg/ProfileSVGGen.s.sol:ProfileSVGGen
