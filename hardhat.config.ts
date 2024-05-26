import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";


const optimizerconfig: HardhatUserConfig = {
  solidity: { version: "0.8.24", settings: { optimizer: { enabled: true, runs: 200 } } }
};

const defaultconfig: HardhatUserConfig = {
  solidity: "0.8.24"
};

export default defaultconfig;
