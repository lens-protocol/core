```                                                                                                                       
     &&&&&                        &&&&&&&&&&&&&&&&&&&&&&&&     &&&&&&&&&&              &&&&&         /&&&&&&&&&&&&&&&&&           
     &&&&&                        &&&&&&&&&&&&&&&&&&&&&&&&     &&&&  &&&&&             &&&&&       &&&&&&(        .&&&&&&*        
     &&&&&                        &&&&&                        &&&&   &&&&&            &&&&&      &&&&/               &&&&&       
     &&&&&                        &&&&&                        &&&&    &&&&&           &&&&&     &&&&&                 &&&&,      
     &&&&&                        &&&&&                        &&&&     &&&&&          &&&&&     &&&&&                 &&&&&      
     &&&&&                        &&&&&                        &&&&      &&&&&         &&&&&      &&&&&&                          
     &&&&&                        &&&&&                        &&&&       &&&&%        &&&&&        &&&&&&&&&&&                   
     &&&&&                        &&&&&&&&&&&&&&&&&&&&         &&&&        &&&&/       &&&&&             &&&&&&&&&&&&&&           
     &&&&&                        &&&&&                        &&&&         &&&&*      &&&&&                     ,&&&&&&&&        
     &&&&&                        &&&&&                        &&&&          &&&&      &&&&&                          (&&&&&      
     &&&&&                        &&&&&                        &&&&           &&&&     &&&&&    &&&&&                   &&&&      
     &&&&&                        &&&&&                        &&&&            &&&&    &&&&&     &&&&                   &&&&      
     &&&&&                        &&&&&                        &&&&            *&&&&   &&&&&     /&&&&&                &&&&&      
     &&&&&&&&&&&&&&&&&&&&&&&&&    &&&&&&&&&&&&&&&&&&&&&&&&     &&&&             (&&&&  &&&&&       &&&&&&&         &&&&&&&        
     &&&&&&&&&&&&&&&&&&&&&&&&&    &&&&&&&&&&&&&&&&&&&&&&&&     &&&&              %&&&&&&&&&&          &&&&&&&&&&&&&&&&&,          
                                                                                                                                  
                                                                                                                                  
                                                                                                                                  

                  _( )_      _                  wWWWw   _                        _( )_      _                  wWWWw   _       
      @@@@       (_   _)    ( )     _     @@@@  (___) _( )_          @@@@       (_   _)    ( )     _     @@@@  (___) _( )_     
     @@()@@ wWWWw  (_)\     ( )   _( )_  @@()@@   Y  (_   _)        @@()@@ wWWWw  (_)\     ( )   _( )_  @@()@@   Y  (_   _)    
      @@@@  (___)      |/   ( )  (_____)  @@@@   \|/   (_)\          @@@@  (___)      |/   ( )  (_____)  @@@@   \|/   (_)\      
       /      Y       \|    (_)     |     \|      |/       |          /      Y       \|    (_)     |     \|      |/      |     
    \ |      \|/       | / \ | /   \|/      |/    \       \|/      \ |      \|/       | / \ | /   \|/      |/    \       \|/   
      |       |        |     |      |       |     |        |         |       |        |     |      |       |     |        |    
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   _//|\_     |        |\ _//|\_   /|\      |\_   |\___    |\     _//|\_     |        |\ _//|\_   /|\      |\_   |\___    |\   
      | \_/  / \__    / \_   |        \   _/      |       _|         | \_/  / \__    / \_   |        \   _/      |       _|    
     /|\_  _/       _/\       \__     /\_        / \_      |_       /|\_  _/       _/\       \__     /\_        / \_      |_    
    / |     |        \___      \_     /\         \        /        / |     |        \___      \_     /\         \        /                         

```

# Lens Protocol

The Lens Protocol is a decentralized, non-custodial social graph. Lens implements unique, on-chain social interaction mechanisms analogous to commonly understood Web2 social media interactions, but significantly expanded with unique functionality that empower communities to form and participants to own their own social graph.

## Setup

> For now only Linux and macOS are known to work
>
> We are now figuring out what works for Windows, instructions will be updated soon
>
> (feel free to experiment and submit PR's)

The environment is built using Docker Compose, note that your `.env` file must have the RPC URL of the network you want to use, and an optional `MNEMONIC` and `BLOCK_EXPLORER_KEY`, defined like so, assuming you choose to use Mumbai network:

```
MNEMONIC="MNEMONIC YOU WANT TO DERIVE WALLETS FROM HERE"
MUMBAI_RPC_URL="YOUR RPC URL HERE"
BLOCK_EXPLORER_KEY="YOUR BLOCK EXPLORER API KEY HERE"
```

With the environment file set up, you can move on to using Docker:

```bash
export USERID=$UID && docker-compose build && docker-compose run --name lens contracts-env bash
```

If you need additional terminals:

```bash
docker exec -it lens bash
```

From there, have fun!

Here are a few self-explanatory scripts:

```bash
npm run test
npm run coverage
npm run compile
```

Cleanup leftover Docker containers:

```bash
USERID=$UID docker-compose down
```

### Foundry Setup

We also support writing tests in Solidity via [Foundry](https://github.com/foundry-rs/foundry).

1. Install Foundry as per the installation instructions here: https://getfoundry.sh/
2. You can now run tests simply by running `forge test`
3. You can get a full Lens environment setup by running:
```bash
# In one terminal run a local anvil node
anvil

# In another terminal, deploy the contracts
# This uses anvil's default mnemonic. The 1st, 2nd and 3rd addresses are for the deployer, governance and treasury respectively.
forge script scripts/Deploy.sol --rpc-url http://localhost:8545 --broadcast \
--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
-s "run(address,address)" 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc

# Now, whitelist the required modules and proxy creator. Also unpause the protocol
forge script scripts/Whitelist.sol --rpc-url http://localhost:8545 --broadcast \
--private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \
-s "run(address, address, address, address, address, address, address, address, address, address, address, address, address, address, address, address, address, address, address, address)" "(0xcf7ed3acca5a467e9e704c703e8d87f634fb0fc9, 0xdc64a140aa3e981100a9beca4e685f962f0cf6c9, 0x5fc8d32690cc91d4c39d9d3abcbd16989f875707, 0x0165878a594ca255338adfa4d48449f69242eb8f, 0xa513e6e4b8f2a923d98304ec87f64353c4d5c853, 0xa513e6e4b8f2a923d98304ec87f64353c4d5c853, 0x2279b7a0a67db372996a5fab50d91eaa73d2ebe6, 0x8a791620dd6260079bf849dc5567adc3f2fdc318, 0x610178da211fef7d417bc0e6fed39f05609ad788, 0xb7f8bc63bbcad18155201308c8f3540b07f84f5e, 0xa51c1fc2f0d1a1b8494ed1fe312d7c3a78ed91c0, 0x0dcd1bf9a1b36ce34237eeafef220932846bcd82, 0x9a676e781a523b5d0c0e43731313a708cb607508, 0x0b306bf915c4d645ff596e518faf3f9669b97016, 0x959922be3caee4b8cd9a407cc3ac1c251c2007b1, 0x9a9f2ccfde556a7e9ff0848998aa4a0cfd8863ae, 0x68b1d87f95878fe05b998f19b66f4baba5de1aed, 0x3aa5ebb10dc797cac828524e59a333d0a371443c, 0xc6e7df5e7b4f2a278906862b61205850344d4e7d, 0x59b670e9fa9d0a427751af201d676719a970857b)"
```

## Protocol Overview

The Lens Protocol transfers ownership of social graphs to the participants of that graph themselves. This is achieved by creating direct links between `profiles` and their `followers`, while allowing fine-grained control of additional logic, including monetization, to be executed during those interactions on a profile-by-profile basis.

Here's how it works...

### Profiles

Any address can create a profile and receive an ERC-721 `Lens Profile` NFT. Profiles are represented by a `ProfileStruct`:

```
/**
 * @notice A struct containing profile data.
 *
 * @param pubCount The number of publications made to this profile.
 * @param followNFT The address of the followNFT associated with this profile, can be empty..
 * @param followModule The address of the current follow module in use by this profile, can be empty.
 * @param handle The profile's associated handle.
 * @param uri The URI to be displayed for the profile NFT.
 */
struct ProfileStruct {
    uint256 pubCount;
    address followNFT;
    address followModule;
    string handle;
    string uri;
}
```

Profiles have a specific URI associated with them, which is meant to include metadata, such as a link to a profile picture or a display name for instance, the JSON standard for this URI is not yet determined. Profile owners can always change their follow module or profile URI.

#### Publications

Profile owners can `publish` to any profile they own. There are three `publication` types: `Post`, `Comment` and `Mirror`. Profile owners can also set and initialize the `Follow Module` associated with their profile.

Publications are on-chain content created and published via profiles. Profile owners can create (publish) three publication types, outlined below. They are represented by a `PublicationStruct`:

```
/**
 * @notice A struct containing data associated with each new publication.
 *
 * @param profileIdPointed The profile token ID this publication points to, for mirrors and comments.
 * @param pubIdPointed The publication ID this publication points to, for mirrors and comments.
 * @param contentURI The URI associated with this publication.
 * @param referenceModule The address of the current reference module in use by this profile, can be empty.
 * @param collectModule The address of the collect module associated with this publication, this exists for all publication.
 * @param collectNFT The address of the collectNFT associated with this publication, if any.
 */
struct PublicationStruct {
    uint256 profileIdPointed;
    uint256 pubIdPointed;
    string contentURI;
    address referenceModule;
    address collectModule;
    address collectNFT;
}
```

#### Publication Types

##### Post

This is the standard publication type, akin to a regular post on traditional social media platforms. Posts contain:

1. A URI, pointing to the actual publication body's metadata JSON, including any images or text.
2. An uninitialized pointer, since pointers are only needed in mirrors and comments.

##### Comment

This is a publication type that points back to another publication, whether it be a post, comment or mirror, akin to a regular comment on traditional social media. Comments contain:

1. A URI, just like posts, pointing to the publication body's metadata JSON.
2. An initialized pointer, containing the profile ID and the publication ID of the publication commented on.

##### Mirror

This is a publication type that points to another publication, note that mirrors cannot, themselves, be mirrored (doing so instead mirrors the pointed content). Mirrors have no original content of its own. Akin to a "share" on traditional social media. Mirrors contain:

1. An empty URI, since they cannot have content associated with them.
2. An initialized pointer, containing the profile ID and the publication ID of the mirrored publication.

### Profile Interaction

There are two types of profile interactions: follows and collects.

#### Follows

Wallets can follow profiles, executing modular follow processing logic (in that profile's selected follow module) and receiving a `Follow NFT`. Each profile has a connected, unique `FollowNFT` contract, which is first deployed upon successful follow. Follow NFTs are NFTs with integrated voting and delegation capability.

The inclusion of voting and delegation right off the bat means that follow NFTs have the built-in capability to create a spontaneous DAO around any profile. Furthermore, holding follow NFTs allows followers to `collect` publications from the profile they are following (except mirrors, which are equivalent to shares in Web2 social media, and require following the original publishing profile to collect).

#### Collects

Collecting works in a modular fashion as well, every publication (except mirrors) requires a `Collect Module` to be selected and initialized. This module, similarly to follow modules, can contain any arbitrary logic to be executed upon collects. Successful collects result in a new, unique NFT being minted, essentially as a saved copy of the original publication. There is one deployed collect NFT contract per publication, and it's deployed upon the first successful collect.

When a mirror is collected, what happens behind the scenes is the original, mirrored publication is collected, and the mirror publisher's profile ID is passed as a "referrer." This allows neat functionality where collect modules that incur a fee can, for instance, reward referrals. Note that the `Collected` event, which is emitted upon collection, indexes the profile and publication directly being passed, which, in case of a mirror, is different than the actual original publication getting collected (which is emitted unindexed).

Alright, that was a mouthful! Let's move on to more specific details about Lens's core principle: Modularity.

## Lens Modularity

Stepping back for a moment, the core concept behind modules is to allow as much freedom as possible to the community to come up with new, innovative interaction mechanisms between social graph participants. For security purposes, this is achieved by including a whitelisted list of modules controlled by governance.

To recap, the Lens Protocol has three types of modules:

1. `Follow Modules` contain custom logic to be executed upon follow.
2. `Collect Modules` contain custom logic to be executed upon collect. Typically, these modules include at least a check that the collector is a follower.
3. `Reference Modules` contain custom logic to be executed upon comment and mirror. These modules can be used to limit who is able to comment and interact with a profile.

Note that collect and reference modules should _not_ assume that a publication cannot be re-initialized, and thus should include front-running protection as a security measure if needed, as if the publication data was not static. This is even more prominent in follow modules, where it can absolutely be changed for a given profile.

Lastly, there is also a `ModuleGlobals` contract which acts as a central data provider for modules. It is controlled by a specific governance address which can be set to a different executor compared to the Hub's governance. It's expected that modules will fetch dynamically changing data, such as the module globals governance address, the treasury address, the treasury fee as well as a list of whitelisted currencies.

### Upgradeability

This iteration of the Lens Protocol implements a transparent upgradeable proxy for the central hub to be controlled by governance. There are no other aspects of the protocol that are upgradeable. In an ideal world, the hub will not require upgrades due to the system's inherent modularity and openness, upgradeability is there only to implement new, breaking changes that would be impossible, or unreasonable to implement otherwise.

This does come with a few caveats, for instance, the `ModuleGlobals` contract implements a currency whitelist, but it is not upgradeable, so the "removal" of a currency whitelist in a module would require a specific new module that does not query the `ModuleGlobals` contract for whitelisted currencies.
