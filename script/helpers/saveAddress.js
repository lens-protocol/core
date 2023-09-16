const path = require('path');
const fs = require('fs');

const addressesPath = '../../addresses.json';

const addresses = require(path.join(__dirname, addressesPath));
const [targetEnv, contract, address] = process.argv.slice(2);
addresses[targetEnv][contract] = address;

fs.writeFileSync(path.join(__dirname, addressesPath), JSON.stringify(addresses, null, 2) + '\n');
console.log('Updated `addresses.json`');
