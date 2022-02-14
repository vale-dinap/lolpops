// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import './ERC2981/ERC2981ContractWideRoyalties.sol';

interface SaleContract {  //// Initialize the interface required to run the sale contract from the contract "WaveLockSale"
  function loadSale(uint256 saleCount, uint256 swapCount, uint256 lpCount) external;
}

contract lolpops is Ownable, ERC721Enumerable, ERC2981ContractWideRoyalties {

  address immutable POPS_teamWallet;
  address public saleContract;  //// Initialize variable holding the sale contract address
  /* WHAT IS THIS USED FOR? */ address public extraContract;  //// Initialize variable holding the extra contract address

  //uint256 nextTokenId; ----- TO DO: CHECK IF NEEDED OR ALREADY IMPLEMENTED IN BASE CONTRACT
  uint256 public immutable MAX_POPS;  //// Define the limit of mintable NFTs - the value will be set via constructor

  string public POPS_PROVENANCE = "";
  string public baseURI;    //// Initialize variable defining the base URI of the images

  mapping(uint256 => uint256) public lastTransferTimestamp; //// Stores the last time a token has been transferred
  mapping(address => uint256) private pastCumulativeHODL;   //// Stores how long a token has been held by a user

  bool mintingDisabled = false;
  modifier onlyIfMintingEnabled{ //// This modifier prevents certain functions from running after "renounceMinting" has been used
    require(mintingDisabled == false, "Minting has been permanently disabled");
    _;
  }

  constructor(string memory _name, string memory _symbol, uint256 maxSupply, address _POPS_teamWallet) Ownable() ERC721(_name, _symbol) { //// Constructor required to implement ERC721 - also implementing Ownership functoinality
    MAX_POPS = maxSupply; //// Also setting the max supply
    POPS_teamWallet = _POPS_teamWallet; //// Storing team wallet contract address
    _setRoyalties(POPS_teamWallet, 200); //// Setting royalties (between 0 and 10000) to be sent to team wallet address (only for NFT marketplaces that support ERC2981) - set to 200 (corrensponding to 2%) as default
  }


  ///	ERC2981 (royalties) IMPLEMENTATION
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981Base) returns (bool){
    return super.supportsInterface(interfaceId);
  }
  //// This only allows to modify the royalties, but not their beneficiary (which is the team wallet)
  function setRoyalties(uint256 value) public onlyOwner {
    require(value <= 2500, "Attempting to set royalties higher than 25% - don't be so greedy");
    _setRoyalties(POPS_teamWallet, value);
  }


  function mint(address to, uint256 tokenId) public virtual onlyIfMintingEnabled {
    require(msg.sender == saleContract, "Nice try lol"); //// Makes sure that only the sale contract can run this function
    _safeMint(to, tokenId);  //// NEED TO CHECK ASAP
  }

  function prepareSale(address _saleContract) public onlyOwner onlyIfMintingEnabled {   //// This can be only executed by owner, links the external sale contract (that must be deployed first)
    require(saleContract == address(0));   //// Run only if the saleContract variable is "empty"
    saleContract = _saleContract;  //// Assign the argument address to saleContract
  }

  function renounceMinting() public onlyOwner onlyIfMintingEnabled { //// This disables minting forever
    saleContract = address(0);
    extraContract = address(0);
    mintingDisabled = true;
  }

  // Reserve POPS for the team -------> CHECK IF STILL NEEDED <----------------------------------------------------------------!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  function reservePOPS(uint16 _amount) public onlyOwner onlyIfMintingEnabled { //// This was set to mint 50 tokens and send them to the owner's wallet - I replaced the hardcoded value with an input parameter
    uint supply = totalSupply();
    for (uint16 i = 0; i < _amount; i++) {
      _safeMint(msg.sender, supply + uint256(i));
    }
  }

  // Provenance Hash
  function setProvenanceHash(string memory provenanceHash) public onlyOwner {  //// This sets the "POPS_PROVENANCE" variable with the string specified
    POPS_PROVENANCE = provenanceHash;
  }

  // Set Base URI
  function setBaseURI(string memory newURI) public onlyOwner { //// This sets the base URI containing the images - a suffix will define the URI pointing to the individual image
    baseURI = newURI;
  }

  // Nobody can mint over the max supply.
  function _safeMint(address to, uint256 tokenId) internal virtual override { //// Adds supply cap to inherited safeMint function
    require(tokenId < MAX_POPS, "Max supply");
    super._safeMint(to, tokenId);
  }

  // Get/Fetch Base URI
  function _baseURI() internal view virtual override returns (string memory) {  //// This returns the base URI containing the images - a suffix defines the final URI pointing to the individual image
    return baseURI;
  }

  function _beforeTokenTransfer( //// Adds commands to store timestamp info to the ERC721Enumerable's beforeTokenTransfer function
      address from,
      address to,
      uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId); //// Runs beforeTokenTransfer function inherited from ERC721Enumerable

    uint256 timeHodld = block.timestamp - lastTransferTimestamp[tokenId]; //// Computes how long the token has been held by the address "from"
    if (from != address(0)) { //// If not just minted
      pastCumulativeHODL[from] += timeHodld; //// Computes how long the token has been held cumulatively by the user
    }
    lastTransferTimestamp[tokenId] = block.timestamp; //// Overrides the last transfer timestamp with the current time
  }

  // Get/Fetch Cumulative HODL
  function cumulativeHODL(address user) public view returns (uint256) { //// Returns how long the user has kept the tokens in his wallet cumulatively
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