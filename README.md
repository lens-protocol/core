```
                                              @@@@@@@@@
                                        @@@@@@@@@@@@@@@@@@@@@
                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
              @@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@
      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@   @@@@@@@@@         @@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@  @@        @@@@@@@@  @@@@@@   @       @@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

# Lens Protocol

The Lens Protocol is a decentralized, non-custodial social graph. Lens implements unique, on-chain social interaction mechanisms analogous to commonly understood Web2 social media interactions, but significantly expanded with unique functionality that empower communities to form and participants to own their own social graph.

## Setup

### 1. Clone the Repository

```
git clone git@github.com:lens-protocol/core.git
```

### 2. Install Foundry

Follow the instructions from [their repository](https://book.getfoundry.sh/getting-started/installation) or just do:

```
curl -L https://foundry.paradigm.xyz | bash
```

```
foundryup
```

### 3. Install dependencies in submodules

You can do it either with forge:

```
forge install
```

or directly with git:

```
git submodule update --init --recursive
```

### 4. Create Your `.env` File

Copy the `.env.example` file into `.env` and fill the necessary fields:

```
MNEMONIC=
POLYGON_RPC_URL=
MUMBAI_RPC_URL=
KOVAN_RPC_URL=
ROPSTEN_RPC_URL=
MAINNET_RPC_URL=
BLOCK_EXPLORER_KEY=
TENDERLY_PROJECT=
TENDERLY_USERNAME=
TENDERLY_FORK_ID=
TENDERLY_HEAD_ID=

# Forking setup (uncomment to test using a fork)
# TESTING_FORK=mainnet
# TESTING_FORK_CURRENT_VERSION=1
# TESTING_FORK_BLOCK=45504400
```

If you just want to test locally without a fork, then you can skip this step.

### 5. Build

You can compile the project using:

```
forge build
```

You may notice a warning about some files exceeding code size.

To avoid the warning, you can compile Via IR but it will take more time:

```
forge build --via-ir
```

### 6. Test

You can run unit tests using:

```
forge test
```

To run the tests on a fork you need to fill the `.env` file from the step above, and uncomment the `TESTING_FORK` variables.

### 7. Coverage

You can run coverage using:

```
forge coverage
```
