const Migrations = artifacts.require("POPs_TeamWallet");

module.exports = function (deployer) {
  deployer.deploy(POPsWallet);
};
