const POPSteamWallet = artifacts.require("POPSteamWallet");
const POPS = artifacts.require("lolpops");
const POPSsale = artifacts.require("POPSsale");
const POPSgoldenTicket = artifacts.require("POPSgoldenTickets");

module.exports = async function (deployer) {
  await deployer.deploy(POPSteamWallet, "LOLPOPS team shares", "POPSshares");
  let walletContract = await POPSteamWallet.deployed();
  await deployer.deploy(POPS, "LOLPOPS", "POPS", 10000, walletContract.address);
  let POPScontract = await POPS.deployed();
  await deployer.deploy(POPSsale, POPScontract.address, walletContract.address);
  let POPSsaleContract = await POPSsale.deployed();
  await deployer.deploy(POPSgoldenTicket, "LOLPOPS golden ticket", "POPSGT", POPSsaleContract.address, POPScontract.address);

  POPScontract.prepareSale(POPSsaleContract.address);
};