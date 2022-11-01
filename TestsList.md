Collecting
Generic
Negatives
[ ] User two should fail to collect without being a follower
[ ] User two should follow, then transfer the followNFT and fail to collect
[ ] User two should fail to collect a nonexistent publication
Scenarios
[ ] Collecting should work if the collector is the publication owner even when he is not following himself and follow NFT was not deployed
[ ] Collecting should work if the collector is the publication owner even when he is not following himself and follow NFT was deployed
[ ] Should return the expected token IDs when collecting publications
[ ] UserTwo should follow, then collect, receive a collect NFT with the expected properties
[ ] UserTwo should follow, then mirror, then collect on their mirror, receive a collect NFT with expected properties
[ ] UserTwo should follow, then mirror, mirror their mirror then collect on their latest mirror, receive a collect NFT with expected properties
Meta-tx
Negatives
[ ] TestWallet should fail to collect with sig with signature deadline mismatch
[ ] TestWallet should fail to collect with sig with invalid deadline
[ ] TestWallet should fail to collect with sig with invalid nonce
[ ] TestWallet should fail to collect with sig without being a follower
[ ] TestWallet should sign attempt to collect with sig, cancel via empty permitForAll, fail to collect with sig
Scenarios
[ ] TestWallet should follow, then collect with sig, receive a collect NFT with expected properties
[ ] TestWallet should follow, mirror, then collect with sig on their mirror

Following
Generic
Negatives
[ ] UserTwo should fail to follow a nonexistent profile
[ ] UserTwo should fail to follow with array mismatch
[ ] UserTwo should fail to follow a profile that has been burned
[ ] UserTwo should fail to follow profile with id 0
Scenarios
[ ] UserTwo should follow profile 1, receive a followNFT with ID 1, followNFT properties should be correct
[ ] UserTwo should follow profile 1 twice, receiving followNFTs with IDs 1 and 2
[ ] UserTwo should follow profile 1 3 times in the same call, receive IDs 1,2 and 3
[ ] Should return the expected token IDs when following profiles
Meta-tx
Negatives
[ ] TestWallet should fail to follow with sig with signature deadline mismatch
[ ] TestWallet should fail to follow with sig with invalid deadline
[ ] TestWallet should fail to follow with sig with invalid nonce
[ ] TestWallet should fail to follow a nonexistent profile with sig
[ ] TestWallet should sign attempt to follow with sig, cancel with empty permitForAll, then fail to follow with sig
Scenarios
[ ] TestWallet should follow profile 1 with sig, receive a follow NFT with ID 1, follow NFT name and symbol should be correct
[ ] TestWallet should follow profile 1 with sig twice in the same call, receive follow NFTs with IDs 1 and 2

Governance Functions
Negatives
[ ] User should not be able to call governance functions
Scenarios
[ ] Governance should successfully whitelist and unwhitelist modules
[ ] Governance should successfully change the governance address

Multi-State Hub
Common
Negatives
[ ] User should fail to set the state on the hub
[ ] User should fail to set the emergency admin
[ ] Governance should set user as emergency admin, user should fail to set protocol state to Unpaused
[ ] Governance should set user as emergency admin, user should fail to set protocol state to PublishingPaused or Paused from Paused
Scenarios
[ ] Governance should set user as emergency admin, user sets protocol state but fails to set emergency admin, governance sets emergency admin to the zero address, user fails to set protocol state
[ ] Governance should set the protocol state, fetched protocol state should be accurate
[ ] Governance should set user as emergency admin, user should set protocol state to PublishingPaused, then Paused, then fail to set it to PublishingPaused
Paused State
Scenarios
[ ] User should create a profile, governance should pause the hub, transferring the profile should fail
[ ] Governance should pause the hub, profile creation should fail, then governance unpauses the hub and profile creation should work
[ ] Governance should pause the hub, setting follow module should fail, then governance unpauses the hub and setting follow module should work
[ ] Governance should pause the hub, setting follow module with sig should fail, then governance unpauses the hub and setting follow module with sig should work
[ ] Governance should pause the hub, setting dispatcher should fail, then governance unpauses the hub and setting dispatcher should work
[ ] Governance should pause the hub, setting dispatcher with sig should fail, then governance unpauses the hub and setting dispatcher with sig should work
[ ] Governance should pause the hub, setting profile URI should fail, then governance unpauses the hub and setting profile URI should work
[ ] Governance should pause the hub, setting profile URI with sig should fail, then governance unpauses the hub and setting profile URI should work
[ ] Governance should pause the hub, setting follow NFT URI should fail, then governance unpauses the hub and setting follow NFT URI should work
[ ] Governance should pause the hub, setting follow NFT URI with sig should fail, then governance unpauses the hub and setting follow NFT URI should work
[ ] Governance should pause the hub, posting should fail, then governance unpauses the hub and posting should work
[ ] Governance should pause the hub, posting with sig should fail, then governance unpauses the hub and posting with sig should work
[ ] Governance should pause the hub, commenting should fail, then governance unpauses the hub and commenting should work
[ ] Governance should pause the hub, commenting with sig should fail, then governance unpauses the hub and commenting with sig should work
[ ] Governance should pause the hub, mirroring should fail, then governance unpauses the hub and mirroring should work
[ ] Governance should pause the hub, mirroring with sig should fail, then governance unpauses the hub and mirroring with sig should work
[ ] Governance should pause the hub, burning should fail, then governance unpauses the hub and burning should work
[ ] Governance should pause the hub, following should fail, then governance unpauses the hub and following should work
[ ] Governance should pause the hub, following with sig should fail, then governance unpauses the hub and following with sig should work
[ ] Governance should pause the hub, collecting should fail, then governance unpauses the hub and collecting should work
[ ] Governance should pause the hub, collecting with sig should fail, then governance unpauses the hub and collecting with sig should work
PublishingPaused State
Scenarios
[ ] Governance should pause publishing, profile creation should work
[ ] Governance should pause publishing, setting follow module should work
[ ] Governance should pause publishing, setting follow module with sig should work
[ ] Governance should pause publishing, setting dispatcher should work
[ ] Governance should pause publishing, setting dispatcher with sig should work
[ ] Governance should pause publishing, setting profile URI should work
[ ] Governance should pause publishing, setting profile URI with sig should work
[ ] Governance should pause publishing, posting should fail, then governance unpauses the hub and posting should work
[ ] Governance should pause publishing, posting with sig should fail, then governance unpauses the hub and posting with sig should work
[ ] Governance should pause publishing, commenting should fail, then governance unpauses the hub and commenting should work
[ ] Governance should pause publishing, commenting with sig should fail, then governance unpauses the hub and commenting with sig should work
[ ] Governance should pause publishing, mirroring should fail, then governance unpauses the hub and mirroring should work
[ ] Governance should pause publishing, mirroring with sig should fail, then governance unpauses the hub and mirroring with sig should work
[ ] Governance should pause publishing, burning should work
[ ] Governance should pause publishing, following should work
[ ] Governance should pause publishing, following with sig should work
[ ] Governance should pause publishing, collecting should work
[ ] Governance should pause publishing, collecting with sig should work

Publishing Comments
Generic
Negatives
[X] UserTwo should fail to publish a comment to a profile owned by User
[X] User should fail to comment with an unwhitelisted collect module
[X] User should fail to comment with an unwhitelisted reference module
[-] (Module Tests) User should fail to comment with invalid collect module data format
[-] (Module Tests) User should fail to comment with invalid reference module data format
[X] User should fail to comment on a publication that does not exist
[X] User should fail to comment on the same comment they are creating (pubId = 2, commentCeption)
Scenarios
[X] User should create a comment with empty collect module data, reference module, and reference module data, fetched comment data should be accurate
[X] Should return the expected token IDs when commenting publications
[X] User should create a post using the mock reference module as reference module, then comment on that post
Meta-tx
Negatives
[X] Testwallet should fail to comment with sig with signature deadline mismatch
[X] Testwallet should fail to comment with sig with invalid deadline
[X] Testwallet should fail to comment with sig with invalid nonce
[X] Testwallet should fail to comment with sig with unwhitelisted collect module
[X] TestWallet should fail to comment with sig with unwhitelisted reference module
[X] TestWallet should fail to comment with sig on a publication that does not exist
[X] TestWallet should fail to comment with sig on the comment they are creating (commentCeption)
[X] TestWallet should sign attempt to comment with sig, cancel via empty permitForAll, then fail to comment with sig
Scenarios
[X] TestWallet should comment with sig, fetched comment data should be accurate

Publishing mirrors
Generic
Negatives
[X] UserTwo should fail to publish a mirror to a profile owned by User
[X] User should fail to mirror with an unwhitelisted reference module
[-] (Module Tests) User should fail to mirror with invalid reference module data format
[X] User should fail to mirror a publication that does not exist
Scenarios
[X] Should return the expected token IDs when mirroring publications
[X] User should create a mirror with empty reference module and reference module data, fetched mirror data should be accurate
[X] User should mirror a mirror with empty reference module and reference module data, fetched mirror data should be accurate and point to the original post
[X] User should create a post using the mock reference module as reference module, then mirror that post
Meta-tx
Negatives
[X] Testwallet should fail to mirror with sig with signature deadline mismatch
[X] Testwallet should fail to mirror with sig with invalid deadline
[X] Testwallet should fail to mirror with sig with invalid nonce
[X] Testwallet should fail to mirror with sig with unwhitelisted reference module
[X] TestWallet should fail to mirror a publication with sig that does not exist yet
[X] TestWallet should sign attempt to mirror with sig, cancel via empty permitForAll, then fail to mirror with sig
Scenarios
[X] Testwallet should mirror with sig, fetched mirror data should be accurate
[X] TestWallet should mirror a mirror with sig, fetched mirror data should be accurate

Publishing Posts
Generic
Negatives
[X] UserTwo should fail to post to a profile owned by User
[X] User should fail to post with an unwhitelisted collect module
[X] User should fail to post with an unwhitelisted reference module
[-] (Modules tests) User should fail to post with invalid collect module data format
[-] (Modules Tests) User should fail to post with invalid reference module data format
Scenarios
[X] Should return the expected token IDs when ~~mirroring~~ posting publications
[X] User should create a post with empty collect and reference module data, fetched post data should be accurate
[X] User should create a post with a whitelisted collect and reference module
Meta-tx
Negatives
[X] Testwallet should fail to post with sig with signature deadline mismatch
[X] Testwallet should fail to post with sig with invalid deadline
[X] Testwallet should fail to post with sig with invalid nonce
[X] Testwallet should fail to post with sig with an unwhitelisted collect module
[X] Testwallet should fail to post with sig with an unwhitelisted reference module
[X] (Replaced it with another post with same nonce) TestWallet should sign attempt to post with sig, cancel via empty permitForAll, then fail to post with sig
[ ] TestWallet should deploy bad EIP1271 implementer, transfer profile to it, then fail to post with sig
Scenarios
[X] TestWallet should post with sig, fetched post data should be accurate
[ ] TestWallet should deploy EIP1271 implementer, transfer profile to it, then post with sig

Default profile Functionality
Generic
Negatives
[ ] UserTwo should fail to set the default profile as a profile owned by user 1
Scenarios
[ ] User should set the default profile
[ ] User should set the default profile and then be able to unset it
[ ] User should set the default profile and then be able to change it to another
[ ] User should set the default profile and then transfer it, their default profile should be unset
Meta-tx
Negatives
[ ] TestWallet should fail to set default profile with sig with signature deadline mismatch
[ ] TestWallet should fail to set default profile with sig with invalid deadline
[ ] TestWallet should fail to set default profile with sig with invalid nonce
[ ] TestWallet should sign attempt to set default profile with sig, cancel with empty permitForAll, then fail to set default profile with sig
Scenarios
[ ] TestWallet should set the default profile with sig
[ ] TestWallet should set the default profile with sig and then be able to unset it
[ ] TestWallet should set the default profile and then be able to change it to another

Dispatcher Functionality
Generic
Negatives
[ ] UserTwo should fail to set dispatcher on profile owned by user 1
[ ] UserTwo should fail to publish on profile owned by user 1 without being a dispatcher
Scenarios
[ ] User should set user two as a dispatcher on their profile, user two should post, comment and mirror
Meta-tx
Negatives
[ ] TestWallet should fail to set dispatcher with sig with signature deadline mismatch
[ ] TestWallet should fail to set dispatcher with sig with invalid deadline
[ ] TestWallet should fail to set dispatcher with sig with invalid nonce
[ ] TestWallet should sign attempt to set dispatcher with sig, cancel via empty permitForAll, fail to set dispatcher with sig
Scenarios
[ ] TestWallet should set user two as dispatcher for their profile, user two should post, comment and mirror

Profile Creation
Generic
Negatives
[ ] User should fail to create a profile with a handle longer than 31 bytes
[ ] User should fail to create a profile with an empty handle (0 length bytes)
[ ] User should fail to create a profile with a handle with a capital letter
[ ] User should fail to create a profile with a handle with an invalid character
[ ] User should fail to create a profile with a unwhitelisted follow module
[ ] User should fail to create a profile with with invalid follow module data format
[ ] User should fail to create a profile when they are not a whitelisted profile creator
[ ] User should fail to create a profile with invalid image URI length
Scenarios
[ ] User should be able to create a profile with a handle, receive an NFT and the handle should resolve to the NFT ID, userTwo should do the same
[ ] Should return the expected token IDs when creating profiles
[ ] User should be able to create a profile with a handle including "-" and "\_" characters
[ ] User should be able to create a profile with a handle 16 bytes long, then fail to create with the same handle, and create again with a different handle
[ ] User should be able to create a profile with a whitelisted follow module
[ ] User should create a profile for userTwo

Profile URI Functionality
Generic
Negatives
[ ] UserTwo should fail to set the profile URI on profile owned by user 1
[ ] UserTwo should fail to set the profile URI on profile owned by user 1
[ ] UserTwo should fail to change the follow NFT URI for profile one
Scenarios
[ ] User should have a custom image tokenURI after setting the profile imageURI
[ ] User should set a custom image URI under 32 bytes of length, profile image URI should be accurate
[ ] Default image should be used when no imageURI set
[ ] Default image should be used when imageURI contains double-quotes
[ ] Should return the correct tokenURI after transfer
[ ] Should return the correct tokenURI after a follow
[ ] User should set user two as a dispatcher on their profile, user two should set the profile URI
[ ] User should follow profile 1, user should change the follow NFT URI, URI is accurate before and after the change
Meta-tx
Negatives
[ ] TestWallet should fail to set profile URI with sig with signature deadline mismatch
[ ] TestWallet should fail to set profile URI with sig with invalid deadline
[ ] TestWallet should fail to set profile URI with sig with invalid nonce
[ ] TestWallet should sign attempt to set profile URI with sig, cancel with empty permitForAll, then fail to set profile URI with sig
[ ] TestWallet should fail to set the follow NFT URI with sig with signature deadline mismatch
[ ] TestWallet should fail to set the follow NFT URI with sig with invalid deadline
[ ] TestWallet should fail to set the follow NFT URI with sig with invalid nonce
[ ] TestWallet should sign attempt to set follow NFT URI with sig, cancel with empty permitForAll, then fail to set follow NFT URI with sig
Scenarios
[ ] TestWallet should set the profile URI with sig
[ ] TestWallet should set the follow NFT URI with sig

Setting Follow Module
Generic
Negatives
[ ] UserTwo should fail to set the follow module for the profile owned by User
[ ] User should fail to set a follow module that is not whitelisted
[ ] User should fail to set a follow module with invalid follow module data format
Scenarios
[ ] User should set a whitelisted follow module, fetching the profile follow module should return the correct address, user then sets it to the zero address and fetching returns the zero address
Meta-tx
Negatives
[ ] TestWallet should fail to set a follow module with sig with signature deadline mismatch
[ ] TestWallet should fail to set a follow module with sig with invalid deadline
[ ] TestWallet should fail to set a follow module with sig with invalid nonce
[ ] TestWallet should fail to set a follow module with sig with an unwhitelisted follow module
[ ] TestWallet should sign attempt to set follow module with sig, then cancel with empty permitForAll, then fail to set follow module with sig
Scenarios
[ ] TestWallet should set a whitelisted follow module with sig, fetching the profile follow module should return the correct address

Collect NFT
Negatives
[ ] User should fail to reinitialize the collect NFT
[ ] User should fail to mint on the collect NFT
[ ] UserTwo should fail to burn user's collect NFT
[ ] User should fail to get the URI for a token that does not exist
[ ] User should fail to change the royalty percentage if he is not the owner of the publication
[ ] User should fail to change the royalty percentage if the value passed exceeds the royalty basis points
Scenarios
[ ] Collect NFT URI should be valid
[ ] Collect NFT source publication pointer should be accurate
[ ] User should burn their collect NFT
[ ] Default royalties are set to 10%
[ ] User should be able to change the royalties if owns the profile and passes a valid royalty percentage in basis points
[ ] User should be able to get the royalty info even over a token that does not exist yet
[ ] Publication owner should be able to remove royalties by setting them as zero
[ ] If the profile authoring the publication is transferred the royalty info now returns the new owner as recipient

Follow NFT
generic
Negatives
[ ] User should follow, and fail to re-initialize the follow NFT
[ ] User should follow, userTwo should fail to burn user's follow NFT
[ ] User should follow, then fail to mint a follow NFT directly
[ ] User should follow, then fail to get the power at a future block
[ ] user should follow, then fail to get the URI for a token that does not exist
Scenarios
[ ] User should follow, then burn their follow NFT, governance power is zero before and after
[ ] User should follow, delegate to themself, governance power should be zero before the last block, and 1 at the current block
[ ] User and userTwo should follow, governance power should be zero, then users delegate multiple times, governance power should be accurate throughout
[ ] User and userTwo should follow, delegate to themselves, 10 blocks later user delegates to userTwo, 10 blocks later both delegate to user, governance power should be accurate throughout
[ ] user and userTwo should follow, user delegates to userTwo twice, governance power should be accurate
[ ] User and userTwo should follow, then transfer their NFTs to the helper contract, then the helper contract batch delegates to user one, then user two, governance power should be accurate
[ ] user should follow, then get the URI for their token, URI should be accurate
meta-tx
negatives
[ ] TestWallet should fail to delegate with sig with signature deadline mismatch
[ ] TestWallet should fail to delegate with sig with invalid deadline
[ ] TestWallet should fail to delegate with sig with invalid nonce
[ ] TestWallet should sign attempt to delegate by sig, cancel with empty permitForAll, then fail to delegate by sig
Scenarios
[ ] TestWallet should delegate by sig to user, governance power should be accurate before and after

Lens NFT Base Functionality
generic
[ ] Domain separator fetched from contract should be accurate
meta-tx
Negatives
[ ] TestWallet should fail to permit with zero spender
[ ] TestWallet should fail to permit with invalid token ID
[ ] TestWallet should fail to permit with signature deadline mismatch
[ ] TestWallet should fail to permit with invalid deadline
[ ] TestWallet should fail to permit with invalid nonce
[ ] TestWallet should sign attempt to permit, cancel with empty permitForAll, then fail to permit
[ ] TestWallet should fail to permitForAll with zero spender
[ ] TestWallet should fail to permitForAll with signature deadline mismatch
[ ] TestWallet should fail to permitForAll with invalid deadline
[ ] TestWallet should fail to permitForAll with invalid nonce
[ ] TestWallet should sign attempt to permitForAll, cancel with empty permitForAll, then fail to permitForAll
[ ] TestWallet should fail to burnWithSig with invalid token ID
[ ] TestWallet should fail to burnWithSig with signature deadline mismatch
[ ] TestWallet should fail to burnWithSig with invalid deadline
[ ] TestWallet should fail to burnWithSig with invalid nonce
[ ] TestWallet should sign attempt to burnWithSig, cancel with empty permitForAll, then fail to burnWithSig
[ ] TestWallet should deploy bad EIP1271 implementer, transfer NFT to it, sign message and permit user, permit should fail with invalid sig
Scenarios
[ ] TestWallet should permit user, user should transfer NFT, send back NFT and fail to transfer it again
[ ] TestWallet should permitForAll user, user should transfer NFT, send back NFT and transfer it again
[ ] TestWallet should sign burnWithSig, user should submit and burn NFT
[ ] TestWallet should deploy EIP1271 implementer, transfer NFT to it, sign message and permit user, user should transfer NFT, send back NFT and fail to transfer it again

deployment validation
[ ] Should fail to deploy a LensHub implementation with zero address follow NFT impl
[ ] Should fail to deploy a LensHub implementation with zero address collect NFT impl
[ ] Should fail to deploy a FollowNFT implementation with zero address hub
[ ] Should fail to deploy a CollectNFT implementation with zero address hub
[ ] Deployer should not be able to initialize implementation due to address(this) check
[ ] User should fail to initialize lensHub proxy after it's already been initialized via the proxy constructor
[ ] Deployer should deploy a LensHub implementation, a proxy, initialize it, and fail to initialize it again
[ ] User should not be able to call admin-only functions on proxy (should fallback) since deployer is admin
[ ] Deployer should be able to call admin-only functions on proxy
[ ] Deployer should transfer admin to user, deployer should fail to call admin-only functions, user should call admin-only functions
[ ] Should fail to deploy a fee collect module with zero address hub
[ ] Should fail to deploy a fee collect module with zero address module globals
[ ] Should fail to deploy a fee follow module with zero address hub
[ ] Should fail to deploy a fee follow module with zero address module globals
[ ] Should fail to deploy module globals with zero address governance
[ ] Should fail to deploy module globals with zero address treasury
[ ] Should fail to deploy module globals with treausury fee > BPS_MAX / 2
[ ] Should fail to deploy a fee module with treasury fee equal to or higher than maximum BPS
[ ] Validates LensHub name & symbol

Events
Misc
[ ] Proxy initialization should emit expected events
Hub Governance
[ ] Governance change should emit expected event
[ ] Emergency admin change should emit expected event
[ ] Protocol state change by governance should emit expected event
[ ] Protocol state change by emergency admin should emit expected events
[ ] Follow module whitelisting functions should emit expected event
[ ] Reference module whitelisting functions should emit expected event
[ ] Collect module whitelisting functions should emit expected event
Hub Interaction
[ ] Profile creation for other user should emit the correct events
[ ] Profile creation should emit the correct events
[ ] Setting follow module should emit correct events
[ ] Setting dispatcher should emit correct events
[ ] Posting should emit the correct events
[ ] Commenting should emit the correct events
[ ] Mirroring should emit the correct events
[ ] Following should emit correct events
[ ] Collecting should emit correct events
[ ] Collecting from a mirror should emit correct events
Module Globals Governance
[ ] Governance change should emit expected event
[ ] Treasury change should emit expected event
[ ] Treasury fee change should emit expected event
[ ] Currency whitelisting should emit expected event

Misc
NFT Transfer Emitters
[ ] User should not be able to call the follow NFT transfer event emitter function
[ ] User should not be able to call the collect NFT transfer event emitter function
Lens Hub Misc
[ ] UserTwo should fail to burn profile owned by user without being approved
[ ] User should burn profile owned by user
[ ] UserTwo should burn profile owned by user if approved
[ ] Governance getter should return proper address
[ ] Profile handle getter should return the correct handle
[ ] Profile dispatcher getter should return the zero address when no dispatcher is set
[ ] Profile creator whitelist getter should return expected values
[ ] Profile dispatcher getter should return the correct dispatcher address when it is set, then zero after it is transferred
[ ] Profile follow NFT getter should return the zero address before the first follow, then the correct address afterwards
[ ] Profile follow module getter should return the zero address, then the correct follow module after it is set
[ ] Profile publication count getter should return zero, then the correct amount after some publications
[ ] Follow NFT impl getter should return the correct address
[ ] Collect NFT impl getter should return the correct address
[ ] Profile tokenURI should return the accurate URI
[ ] Publication reference module getter should return the correct reference module (or zero in case of no reference module)
[ ] Publication pointer getter should return an empty pointer for posts
[ ] Publication pointer getter should return the correct pointer for comments
[ ] Publication pointer getter should return the correct pointer for mirrors
[ ] Publication content URI getter should return the correct URI for posts
[ ] Publication content URI getter should return the correct URI for comments
[ ] Publication content URI getter should return the correct URI for mirrors
[ ] Publication collect module getter should return the correct collectModule for posts
[ ] Publication collect module getter should return the correct collectModule for comments
[ ] Publication collect module getter should return the zero address for mirrors
[ ] Publication type getter should return the correct publication type for all publication types, or nonexistent
[ ] Profile getter should return accurate profile parameters
Follow Module Misc
[ ] User should fail to call processFollow directly on a follow module inheriting from the FollowValidatorFollowModuleBase
[ ] Follow module following check when there are no follows, and thus no deployed Follow NFT should return false
[ ] Follow module following check with zero ID input should return false after another address follows, but not the queried address
[ ] Follow module following check with specific ID input should revert after following, but the specific ID does not exist yet
[ ] Follow module following check with specific ID input should return false if another address owns the specified follow NFT
[ ] Follow module following check with specific ID input should return true if the queried address owns the specified follow NFT
Collect Module Misc
[ ] Should fail to call processCollect directly on a collect module inheriting from the FollowValidationModuleBase contract
Module Globals
Negatives
[ ] User should fail to set the governance address on the module globals
[ ] User should fail to set the treasury on the module globals
[ ] User should fail to set the treasury fee on the module globals
Scenarios
[ ] Governance should set the governance address on the module globals
[ ] Governance should set the treasury on the module globals
[ ] Governance should set the treasury fee on the module globals
[ ] Governance should fail to whitelist the zero address as a currency
[ ] Governance getter should return expected address
[ ] Treasury getter should return expected address
[ ] Treasury fee getter should return the expected fee
UI Data Provider
[ ] UI Data Provider should return expected values
LensPeriphery
ToggleFollowing
Generic
Negatives
[ ] UserTwo should fail to toggle follow with an incorrect profileId
[ ] UserTwo should fail to toggle follow with array mismatch
[ ] UserTwo should fail to toggle follow from a profile that has been burned
[ ] UserTwo should fail to toggle follow for a followNFT that is not owned by them
Scenarios
[ ] UserTwo should toggle follow with true value, correct event should be emitted
[ ] User should create another profile, userTwo follows, then toggles both, one true, one false, correct event should be emitted
[ ] UserTwo should toggle follow with false value, correct event should be emitted
Meta-tx
Negatives
[ ] TestWallet should fail to toggle follow with sig with signature deadline mismatch
[ ] TestWallet should fail to toggle follow with sig with invalid deadline
[ ] TestWallet should fail to toggle follow with sig with invalid nonce
[ ] TestWallet should fail to toggle follow a nonexistent profile with sig
Scenarios
[ ] TestWallet should toggle follow profile 1 to true with sig, correct event should be emitted
[ ] TestWallet should toggle follow profile 1 to false with sig, correct event should be emitted
// TODO: The whole section is questionable (removed in foundry branch)
Profile Metadata URI
Generic
Negatives
[ ] User two should fail to set profile metadata URI for a profile that is not theirs while they are not the dispatcher
Scenarios
[ ] User should set user two as dispatcher, user two should set profile metadata URI for user one's profile, fetched data should be accurate
[ ] Setting profile metadata should emit the correct event
[ ] Setting profile metadata via dispatcher should emit the correct event
Meta-tx
Negatives
[ ] TestWallet should fail to set profile metadata URI with sig with signature deadline mismatch
[ ] TestWallet should fail to set profile metadata URI with sig with invalid deadline
[ ] TestWallet should fail to set profile metadata URI with sig with invalid nonce
Scenarios
[ ] TestWallet should set profile metadata URI with sig, fetched data should be accurate and correct event should be emitted

Mock Profile Creation Proxy
Negatives
[ ] Should fail to create profile if handle length before suffix does not reach minimum length
[ ] Should fail to create profile if handle contains an invalid character before the suffix
[ ] Should fail to create profile if handle starts with a dash, underscore or period
Scenarios
[ ] Should be able to create a profile using the whitelisted proxy, received NFT should be valid

Profile Creation Proxy
Negatives
[ ] Should fail to create profile if handle length before suffix does not reach minimum length
[ ] Should fail to create profile if handle contains an invalid character before the suffix
[ ] Should fail to create profile if handle starts with a dash, underscore or period
Scenarios
[ ] Should be able to create a profile using the whitelisted proxy, received NFT should be valid

Upgradeability
[ ] Should fail to initialize an implementation with the same revision
[ ] Should upgrade and set a new variable's value, previous storage is unchanged, new value is accurate
