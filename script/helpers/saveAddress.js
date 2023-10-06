const path = require('path');
const fs = require('fs');

const addressesPath = '../../addresses.json';

const addresses = require(path.join(__dirname, addressesPath));

// If no arguments are passed - fail
if (process.argv.length < 5) {
  console.error('Usage: node saveAddress.js <targetEnv> <contractName> <address>');
  process.exit(1);
}

// If 3 arguments are passed - save the contract address
if (process.argv.length === 5) {
  const [targetEnv, contract, address] = process.argv.slice(2);
  addresses[targetEnv][contract] = address;

  fs.writeFileSync(path.join(__dirname, addressesPath), JSON.stringify(addresses, null, 2) + '\n');
  console.log('Updated `addresses.json`');
  process.exit(0);
}

// If 5 arguments are passed - save the module address in modules
if (process.argv.length === 7) {
  const [targetEnv, moduleName, moduleAddress, lensVersion, moduleType] = process.argv.slice(2);
  if (addresses[targetEnv]['Modules'][lensVersion][moduleType] === undefined) {
    addresses[targetEnv]['Modules'][lensVersion][moduleType] = [];
  }

  // Check if the module with a same name is already in the list
  const moduleIndex = addresses[targetEnv]['Modules'][lensVersion][moduleType].findIndex(
    (module) => module.name === moduleName
  );

  if (moduleIndex === -1) {
    addresses[targetEnv]['Modules'][lensVersion][moduleType].push({
      name: moduleName,
      addy: moduleAddress,
    });
  } else {
    // Get the module object from the list by index and change the addy:
    addresses[targetEnv]['Modules'][lensVersion][moduleType][moduleIndex].addy = moduleAddress;
  }

  fs.writeFileSync(path.join(__dirname, addressesPath), JSON.stringify(addresses, null, 2) + '\n');
  console.log('Updated `addresses.json`');
  process.exit(0);
}
