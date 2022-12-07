require("@nomicfoundation/hardhat-toolbox");

const goerliApiKey = process.env.GOERLI_ALCHEMY_API_KEY || "";
const privateKey = process.env.PRIVATE_KEY;

const config = {
  solidity: {
    compilers: [
      {
        version: "0.6.11",
      },
    ],
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${goerliApiKey}`,
      accounts: privateKey !== undefined ? [privateKey] : [],
    },
  },
};

module.exports = config;
