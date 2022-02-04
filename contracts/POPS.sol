// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

interface SaleContract {  //// Initialize the interface required to run the sale contract from the contract "WaveLockSale"
  function loadSale(uint256 saleCount, uint256 swapCount, uint256 lpCount) external;
}

contract lolpops is Ownable, ERC721Enumerable {
  address public saleContract;  //// Initialize variable holding the sale contract address
  /* WHAT IS THIS USED FOR? */ address public extraContract;  //// Initialize variable holding the extra contract address

  uint256 public immutable MAX_POPS;  //// Define the limit of mintable NFTs - the value will be set via constructor

  /* WHAT IS THIS USED FOR? */ string public POPS_PROVENANCE = "";
  string public baseURI;    //// Initialize variable defining the base URI of the images

  /* NEED TO INVESTIGATE FURTHER */ mapping(uint256 => uint256) public lastTransferTimestamp;
  /* NEED TO INVESTIGATE FURTHER */ mapping(address => uint256) private pastCumulativeHODL;   //// Apparently seems to store the time a token has been held

  constructor(string memory _name, string memory _symbol, uint256 maxSupply) Ownable() ERC721(_name, _symbol) { //// Constructor required to implement ERC721 - also implementing Ownership functoinality
    MAX_POPS = maxSupply; //// Also setting the max supply
  }

  function mint(address to, uint256 tokenId) public virtual {
    require(msg.sender == saleContract, "Nice try lol"); //// Makes sure that only the sale contract can run this function
    _safeMint(to, tokenId);  //// NEED TO CHECK ASAP
  }

  function prepareSale(address _saleContract) public onlyOwner {   //// This can be only executed by owner, links the external sale contract (that must be deployed first)
    require(saleContract == address(0));   //// Run only if the saleContract variable is "empty"
    saleContract = _saleContract;  //// Assign the argument address to saleContract
  }

  function renounceMinting() public onlyOwner { //// This overrides the contract addresses variables with zeroes, so that minting is no longer possible
    /* WARNING: THIS MAKES THE FUNCTION prepareSale() USABLE AGAIN*/ saleContract = address(0);
    extraContract = address(0);
  }

  // Reserve POPS for the team
  function reservePOPS(uint16 _amount) public onlyOwner { //// This was set to mint 50 tokens and send them to the owner's wallet - I replaced the hardcoded value with an input parameter
    uint supply = totalSupply();
    for (uint16 i = 0; i < _amount; i++) {
      _safeMint(msg.sender, supply + uint256(i));
    }
  }

  // Provenance Hash
  /* Need to figure out what this is used for */ function setProvenanceHash(string memory provenanceHash) public onlyOwner {  //// This sets the "POPS_PROVENANCE" variable with the string specified
    POPS_PROVENANCE = provenanceHash;
  }

  // Set Base URI
  function setBaseURI(string memory newURI) public onlyOwner { //// This sets the base URI containing the images - a suffix will define the URI pointing to the individual image
    baseURI = newURI;
  }

  // Nobody can mint over the max supply.
  function _safeMint(address to, uint256 tokenId) internal virtual override {
    require(tokenId < MAX_POPS, "Max supply");
    super._safeMint(to, tokenId);
  }

  // Get/Fetch Base URI
  function _baseURI() internal view virtual override returns (string memory) {  //// This returns the base URI containing the images - a suffix defines the final URI pointing to the individual image
    return baseURI;
  }

  function _beforeTokenTransfer( //// STILL NEED TO CHECK WHAT THIS DOES
      address from,
      address to,
      uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    uint256 timeHodld = block.timestamp - lastTransferTimestamp[tokenId];
    if (from != address(0)) {
      pastCumulativeHODL[from] += timeHodld;
    }
    lastTransferTimestamp[tokenId] = block.timestamp;
  }

  // Get/Fetch Cumulative HODL
  function cumulativeHODL(address user) public view returns (uint256) {
    uint256 _cumulativeHODL = pastCumulativeHODL[user];
    uint256 bal = balanceOf(user);
    for (uint256 i = 0; i < bal; i++) {
      uint256 tokenId = tokenOfOwnerByIndex(user, i);
      uint256 timeHodld = block.timestamp - lastTransferTimestamp[tokenId];
      _cumulativeHODL += timeHodld;
    }
    return _cumulativeHODL;
  }
}
