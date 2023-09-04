const fs = require('fs').promises;
const path = require('path');
const { utils } = require('ethers');

// Capture the command line arguments
const [_, __, DeploymentName, ChainId, ChainName] = process.argv;

if (!DeploymentName || !ChainId || !ChainName) {
  console.error('Please provide DeploymentName, ChainId and ChainName as command line arguments.');
  process.exit(1);
}

async function findDeploymentDirectory(basePath, prefix, chainId) {
  const dirs = await fs.readdir(basePath);
  const filtered = dirs.filter((dir) => dir.startsWith(prefix));

  if (filtered.length !== 1) {
    for (const dir of filtered) {
      console.error(dir);
    }
    throw new Error(`Expected to find one directory, but found the above ${filtered.length} dirs.`);
  }

  if (chainId) {
    return path.join(basePath, filtered[0], ChainId);
  } else {
    return path.join(basePath, filtered[0]);
  }
}

async function findApiDirectory(basePath, prefix) {
  const dirs = await fs.readdir(basePath);
  const filteredDirs = dirs.filter((dir) => dir.startsWith(prefix) && !dir.includes('.t.'));

  const foundDirs = [];

  for (const dir of filteredDirs) {
    const contents = await fs.readdir(path.join(basePath, dir));
    if (contents.includes(`${prefix}.json`)) {
      foundDirs.push(dir);
    }
  }

  if (foundDirs.length !== 1) {
    for (const dir of foundDirs) {
      console.error(dir);
    }
    throw new Error(
      `Expected to find one directory, but found the above ${foundDirs.length} dirs.`
    );
  }

  return path.join(basePath, foundDirs[0]);
}

function transformArgsForEncoding(args, inputs) {
  if (typeof args === 'string' && args.startsWith('(') && args.endsWith(')')) {
    // Convert the tuple string into an array
    args = args
      .slice(1, -1)
      .split(',')
      .map((item) => item.trim());
  }

  return args.map((arg, index) => {
    if (inputs[index].type === 'tuple') {
      // If the type is a tuple, recursively transform its arguments
      return transformArgsForEncoding(arg, inputs[index].components);
    } else {
      return arg;
    }
  });
}

async function encodeConstructorArgs(contractName, args) {
  const contractDirectory = await findApiDirectory('out', contractName);
  const filePath = path.join(contractDirectory, `${contractName}.json`);
  const fileContents = await fs.readFile(filePath, 'utf-8');

  const data = JSON.parse(fileContents);
  const abi = data.abi;

  // Example usage
  const constructorAbi = abi.find((item) => item.type === 'constructor');
  // console.log('\n\nABI tuple definition:', constructorAbi.inputs);

  if (!constructorAbi) {
    throw new Error('Constructor ABI not found for the contract.');
  }

  // Convert tuple string representation to arrays
  const transformedArgs = transformArgsForEncoding(args, constructorAbi.inputs);
  const encodedArgs = utils.defaultAbiCoder.encode(constructorAbi.inputs, transformedArgs);

  return encodedArgs;
}

async function outputLibrariesMessage(data) {
  if (data.libraries && data.libraries.length > 0) {
    console.log(
      '\n\nPlease make sure you have the following libraries added into your foundry.toml file:\n'
    );
    console.log('libraries = [');
    data.libraries.forEach((lib) => {
      console.log(`\t"${lib}",`);
    });
    console.log(']');
  } else {
    console.log('No libraries found in the broadcast JSON.');
  }
}

async function generateBashScript() {
  const deploymentPath = await findDeploymentDirectory('broadcast', DeploymentName, ChainId);
  const files = await fs.readdir(deploymentPath);

  const targetFile = files.find((file) => file.endsWith('-latest.json'));
  if (!targetFile) {
    throw new Error('No matching JSON file found.');
  }

  const fileContents = await fs.readFile(path.join(deploymentPath, targetFile), 'utf-8');
  const data = JSON.parse(fileContents);
  const transactions = data.transactions.filter(
    (transaction) => transaction.transactionType === 'CREATE'
  );

  const bashCommands = await Promise.all(
    transactions.map(async (transaction) => {
      let baseCmd = `forge verify-contract ${transaction.contractAddress} ${transaction.contractName} --chain ${ChainName} --watch`;
      if (transaction.arguments && transaction.arguments.length > 0) {
        // Placeholder for abi encoding
        const abiEncodedArgs = await encodeConstructorArgs(
          transaction.contractName,
          transaction.arguments
        );
        baseCmd += ` --constructor-args ${abiEncodedArgs}`;
      }
      return baseCmd;
    })
  );

  await fs.writeFile('verify.sh', bashCommands.join('\n'));

  console.log('verify.sh has been generated successfully.');

  // Call the function
  outputLibrariesMessage(data);
}

generateBashScript().catch((error) => {
  console.error('An error occurred:', error);
});
