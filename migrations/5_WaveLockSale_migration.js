const Migrations = artifacts.require("POPs_WaveLockSale");

module.exports = function (deployer) {
  deployer.deploy(POPSWaveLockMintSale);
};
