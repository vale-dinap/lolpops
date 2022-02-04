// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface Minter {
  function mint(address to, uint256 tokenId) external;
}

// Setup
contract POPSWaveLockMintSale is Ownable, ReentrancyGuard {
  // Contract Variables
  address public nft;
  uint256 constant BASE = 10**18;
  uint256 public price;
  uint256 public amountForSale;
  uint256 public amountSold;
  uint256 public startBlock;
  uint256 public wave = 0;
  uint256 public waveBlockLength = 20;

  mapping(uint256 => mapping(address => bool)) blockLock;
  mapping(address => uint256) balance;

  constructor(address _nft, uint256 _startBlock) Ownable() ReentrancyGuard() {
    nft = _nft;
    startBlock = _startBlock;
  }

  // Main Sale Loading
  function loadSale(uint256 count) external {
    require(msg.sender == nft);
    amountForSale = count;
  }

  // Main Buy
  function buy(uint256 count) external payable nonReentrant {
    require(block.number > startBlock, "Contract: Lolpops sale has not started.");
    require(count > 0, "Contract: You must mint at least 1 Lolpop.");
    require(amountSold < amountForSale, "Contract: Lolpops are sold out, sorry!");

    refreshWave();

    require(!blockLock[wave][msg.sender], "Contract: Locked for this wave");
    require(count < maxPerTX(wave), "Cap");

    // Last mint is incomplete, adjust.
    uint256 ethAmountOwed;
    if (amountSold + count > amountForSale) {
      uint256 amountRemaining = amountForSale-amountSold;
      ethAmountOwed = price * (count-amountRemaining);
      count = amountRemaining;
    }

    // Update max available someone is able to mint.
    amountSold += count;
    balance[msg.sender] += count;
    // Lock the address in this mint wave.
    blockLock[wave][msg.sender] = true;

    // If Owed ETH > 0 then:
    if (ethAmountOwed > 0) {
      (bool success, ) = msg.sender.call{ value: ethAmountOwed }("");
      require(success, "Address: unable to send value, recipient may have reverted.");
    }
  }

  // Main minting functionality.
  function mint(uint256 count) external {
    require(count > 0);
    require(count <= balance[msg.sender]);
    balance[msg.sender] -= count;

    // Mint to the owner.
    uint256 currentSupply = IERC721Enumerable(nft).totalSupply();
    for (uint256 i = 0; i < count; i++) {
      Minter(nft).mint(msg.sender, currentSupply + i);
    }
  }

  // Refresh the current wave on the blockchain.
  function refreshWave() internal {
    uint256 blocksSinceStart = block.number - startBlock;
    uint256 newWave = blocksSinceStart/waveBlockLength;
    if (newWave != wave) {
      wave = newWave;
    }
  }

  // Max per transaction -- wave set.
  function maxPerTX(uint256 _wave) internal pure returns (uint256) {
    if (_wave == 0) {
      return 2;
    } else if (_wave == 1) {
      return 8;
    } else if (_wave == 2) {
      return 20;
    } else {
      return 50;
    }
  }
}
