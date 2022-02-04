// SPDX-License-Identifier: MIT

//// This appears to be a simpler version of POPS.sol (ERC721 token definition + sale contract prep)

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

interface SaleContract { //// Initialize the interface required to run the sale contract from the contract "WaveLockSale"
  function loadSale(uint256 count) external;
}

contract lolpops is Ownable, ERC721Enumerable {
  address public saleContract;

  /* WHERE IS THIS USED??? NOWHERE, IT SEEMS */ uint256 constant BASE = 10**18;
  uint256 constant MAX_SUPPLY = 10000; //// Define the limit of mintable NFTs
  /* WHERE IS THIS USED??? NOWHERE, IT SEEMS */ uint256 public amountToLP;

  constructor(string memory _name, string memory _symbol) Ownable() ERC721(_name, _symbol) {  //// Constructor required to implement ERC721 - also implementing Ownership functoinality
  }

  function mint(address to, uint256 tokenId) public virtual {
    require(msg.sender == saleContract, "Nice try lol"); //// Makes sure that only the sale contract can run this function
    require(tokenId < MAX_SUPPLY, "Max supply"); //// Ensures that max supply is not exceeded
    /* WHY SUPER? NONE OF THE IMPORTED CONTRACTS HAVE SUCH FUNCTION - INVESTIGATE FURTHER */ super._safeMint(to, tokenId); //// Used safemint function from base contract ---????????---
  }

  function prepareSale(address _saleContract) public onlyOwner { //// This can be only executed by contract owner and only ONCE, instances the external contract "WaveLockSale" (that must be deployed first)
    require(saleContract == address(0));  //// Run only if the saleContract variable is "empty"
    saleContract = _saleContract; //// Assign the argument address to saleContract
    SaleContract(_saleContract).loadSale(MAX_SUPPLY);  //// Istances the external SaleContract, then initializes the sale (loadSale)
  }
}
