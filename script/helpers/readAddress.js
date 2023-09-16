const path = require('path');

const addressesPath = '../../addresses.json';

const addresses = require(path.join(__dirname, addressesPath));
const [targetEnv, contract] = process.argv.slice(2);

if (!addresses[targetEnv]) {
  console.error(`ERROR: Target environment "${targetEnv}" not found in addresses.json`);
  process.exit(1);
}

const address = addresses[targetEnv][contract];

console.log(address ?? '');
