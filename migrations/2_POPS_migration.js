const POPSteamWallet = artifacts.require("POPSteamWallet");
const POPS = artifacts.require("lolpops");

module.exports = async function (deployer) {
  await deployer.deploy(POPSteamWallet, "LOLPOPS team shares", "POPSshares");
  let walletContract = await POPSteamWallet.deployed();
  await deployer.deploy(POPS, "LOLPOPS", "POPS", 10000, walletContract.address);
};