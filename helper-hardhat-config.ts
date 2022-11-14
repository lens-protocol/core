import {
  KOVAN_RPC_URL,
  MAINNET_RPC_URL,
  MUMBAI_RPC_URL,
  POLYGON_RPC_URL,
  ROPSTEN_RPC_URL,
  TENDERLY_FORK_ID,
} from './env';

import {
  eEthereumNetwork,
  ePolygonNetwork,
  eXDaiNetwork,
  iParamsPerNetwork,
} from './helpers/types';

export const NETWORKS_RPC_URL: iParamsPerNetwork<string> = {
  [eEthereumNetwork.kovan]: KOVAN_RPC_URL,
  [eEthereumNetwork.ropsten]: ROPSTEN_RPC_URL,
  [eEthereumNetwork.main]: MAINNET_RPC_URL,
  [eEthereumNetwork.hardhat]: 'http://localhost:8545',
  [eEthereumNetwork.harhatevm]: 'http://localhost:8545',
  [eEthereumNetwork.tenderlyMain]: `https://rpc.tenderly.co/fork/${TENDERLY_FORK_ID}`,
  [ePolygonNetwork.mumbai]: MUMBAI_RPC_URL,
  [ePolygonNetwork.matic]: POLYGON_RPC_URL,
  [eXDaiNetwork.xdai]: 'https://rpc.xdaichain.com/',
};
