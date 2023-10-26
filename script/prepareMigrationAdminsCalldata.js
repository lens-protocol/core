// Read migrationAdmins.csv
// In the format of:
// index,address
// 0,0x1234...
// 1,0x5678...
// ...

const fs = require('fs');
const file = 'migrationAdmins.csv';

const migrationAdmins = [];

// Read file line by line and save to the array
// Skip the first line
fs.readFileSync(file, 'utf-8')
  .split(/\r?\n/)
  .slice(1)
  .forEach(function (line) {
    // If line is empty, skip
    if (!line) return;
    const [index, address] = line.split(',');
    migrationAdmins.push(address);
  });

// Function setMigrationAdmins(address[] memory migrationAdmins, bool whitelisted)
// Construct the calldata using migrationAdmins and bool true, using ethers
const ethers = require('ethers');

const abi = [
  {
    inputs: [
      {
        internalType: 'address[]',
        name: 'migrationAdmins',
        type: 'address[]',
      },
      {
        internalType: 'bool',
        name: 'whitelisted',
        type: 'bool',
      },
    ],
    name: 'setMigrationAdmins',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
];

const iface = new ethers.utils.Interface(abi);
const data = iface.encodeFunctionData('setMigrationAdmins', [migrationAdmins, true]);

console.log(data);
