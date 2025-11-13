import "dotenv/config"; // opcional: usar .env para claves/URLs
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@typechain/hardhat";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  // Rutas (ajusta si tus contratos/tests están en subcarpetas)
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },

  // TypeChain (genera types en typechain-types/)
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v6",
    alwaysGenerateOverloads: false,
    externalArtifacts: [],
  },

  networks: {
    hardhat: {
      chainId: 1337,
      // accounts: puede configurarse aquí si quieres claves fijas para reproducibilidad
    },
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    // ejemplo comentado para cuando uses una RPC real:
    // goerli: {
    //   url: process.env.GOERLI_RPC ?? "",
    //   accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    // },
  },

  mocha: {
    timeout: 20000,
  },
};

export default config;
