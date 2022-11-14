import { config } from 'dotenv';
config({ path: '../.env' });
const { env } = process;

export const MNEMONIC: string = env.MNEMONIC || '';
export const PRIVATE_KEY: string = env.PRIVATE_KEY || '';
export const DEFENDER_API_KEY: string = env.DEFENDER_API_KEY || '';
export const DEFENDER_SECRET_KEY: string = env.DEFENDER_SECRET_KEY || '';
export const SKIP_LOAD: boolean = (env.SKIP_LOAD && env.SKIP_LOAD === 'true') || false;
export const MAINNET_FORK: boolean = (env.MAINNET_FORK && env.MAINNET_FORK === 'true') || false;
export const TRACK_GAS: boolean = (env.TRACK_GAS && env.TRACK_GAS === 'true') || false;
export const BLOCK_EXPLORER_KEY: string = env.BLOCK_EXPLORER_KEY || '';
export const TENDERLY_FORK_ID: string = env.TENDERLY_FORK_ID || '';
export const KOVAN_RPC_URL: string = env.KOVAN_RPC_URL || '';
export const ROPSTEN_RPC_URL: string = env.ROPSTEN_RPC_URL || '';
export const MAINNET_RPC_URL: string = env.MAINNET_RPC_URL || '';
export const MUMBAI_RPC_URL: string = env.MUMBAI_RPC_URL || '';
export const POLYGON_RPC_URL: string = env.POLYGON_RPC_URL || '';
