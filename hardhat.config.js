require("dotenv").config();

require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-etherscan");
// require("@jobinleung/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
// require("hardhat-gas-reporter");
require("solidity-coverage");
// require('hardhat-contract-sizer');
require("@nomiclabs/hardhat-etherscan");


// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  compilers: [
    {
        version: "0.8.2"
    }
  ],
  networks: {
    // ropsten: {
    //   url: process.env.ROPSTEN_URL || "",
    //   accounts:
    //     process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    // },
    localhost:{
      // url:"http://172.20.10.6:9090/",
      url:"http://192.168.31.58:9090/",
      blockGasLimit: 300000000,  // 设置为你需要的Gas限制
      allowUnlimitedContractSize: true
    }
    // arbtest:{
    //   blockGasLimit: 300000000,  // 设置为你需要的Gas限制
    //   url: process.env.ARB_TEST_URL,
    //   accounts:[process.env.ARB_TEST_PRIVATE_KEY]
    // }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
