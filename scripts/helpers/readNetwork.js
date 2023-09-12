const path = require('path');

const addressesPath = '../../addresses.json';

const addresses = require(path.join(__dirname, addressesPath));
const [targetEnv] = process.argv.slice(2);

if (!addresses[targetEnv]) {
  console.error(`ERROR: Target environment "${targetEnv}" not found in addresses.json`);
  process.exit(1);
}

const network = addresses[targetEnv].network;

if (!network) {
  console.error(
    `ERROR: "network" parameter not found under "${targetEnv}" target environment in addresses.json`
  );
  process.exit(1);
}

console.log(network);
