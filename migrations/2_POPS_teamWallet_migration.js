const POPSshares = artifacts.require("POPSshares");
const POPSwallet = artifacts.require("POPSwallet");

module.exports = async function (deployer) {
  await deployer.deploy(POPSshares, "POPSteamShares", "POPSshares");
  let sharesContract = await POPSshares.deployed();
  await deployer.deploy(POPSwallet, sharesContract.address);
};