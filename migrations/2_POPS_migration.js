const Migrations = artifacts.require("POPS");

module.exports = function (deployer) {
  deployer.deploy(lolpops);
};
