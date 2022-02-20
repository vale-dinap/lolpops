// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import './ERC2981/ERC2981ContractWideRoyalties.sol';

///// TO_DO: Add events
///// SALE CONTRACT INTERFACE ///// ----- TO_DO: CHECK IF STILL NEEDED AS IT IS

interface SaleContract {  // Initialize the interface required to run the sale contract from the contract "WaveLockSale"
  function loadSale(uint256 saleCount, uint256 swapCount, uint256 lpCount) external;
}

contract lolpops is Ownable, ERC721Enumerable, ERC2981ContractWideRoyalties {

  ///// CONTRACT VARIABLES /////

  // Addresses
  address public POPS_teamWallet;                                                 // Team wallet address
  address public POPS_saleContract;                                               // Sale contract address
  // Token data - main
  uint256 public immutable MAX_POPS;
  string public baseURI;                                                          // To be locked after reveal / when minting is over
  // Token data - timestamps
  mapping(uint256 => uint256) public lastTransferTimestamp;                       // Stores the last time a token has been transferred
  mapping(address => uint256) private pastCumulativeHODL;                         // Stores how long a token has been hodl'd by a user
  // Provenance
  string public POPS_provenanceHash_imageFiles = "";                              // Hash of all image files hashes concatenated
  string public POPS_provenanceHash_imageFileCIDs = "";// TO_DO: CHECK IF I NEED  // Hash of all image files IPFS CIDs concatenated
  // Permissions
  bool public minting_disabled = false;                                           // Once disabled, it is forever
  bool public baseURI_locked = false;                                             // Once locked, it is forever
  bool public provenanceData_locked = false;                                      // Once locked, it is forever
  bool public royalties_locked = false;                                           // Once locked, it is forever


  ///// MODIFIERS /////

  modifier ifMintingEnabled{                                                      // Can lock access to functions after "renounceMinting()" has been run
    require(!minting_disabled, "Minting has been permanently disabled");
    _;
  }

  modifier ifBaseURInotLocked{                                                    // Can deny access to functions if baseURI has been locked
    require(!baseURI_locked, "BaseURI has been permanently locked");
    _;
  }

  modifier ifRoyaltiesNotLocked{                                                  // Can avoid using functions if royalties have been locked
    require(!royalties_locked, "Royalties data have been permanently locked");
    _;
  }


  ///// CONSTRUCTOR /////

  constructor(string memory _name, string memory _symbol, uint256 maxSupply, address _POPS_teamWallet) Ownable() ERC721(_name, _symbol) {
    MAX_POPS = maxSupply;                                                         // Setting the max supply (IMMUTABLE)
    POPS_teamWallet = _POPS_teamWallet;                                           // Storing team wallet contract address
    _setRoyalties(POPS_teamWallet, 250);                                          // Setting to 250 (corrensponding to 2.5%)
  }


  ///// MINTING FUNCTIONS /////

  function prepareSale(address _saleContract) public onlyOwner ifMintingEnabled { // Links the external sale contract
    require(POPS_saleContract == address(0));                                     // Once set, can't be overridden
    POPS_saleContract = _saleContract;
  }

  function mint(address to, uint256 tokenId) external virtual ifMintingEnabled {
    require(msg.sender == saleContract, "Only the sale contract is allowed to mint");
    _safeMint(to, tokenId);
  }

  function renounceMinting() public onlyOwner ifMintingEnabled {                  // Warning: disables minting forever
    saleContract = address(0);
    minting_disabled = true;
  }

  // Nobody can mint over the max supply.
  function _safeMint(address to, uint256 tokenId) internal virtual override {     // Add supply cap to _safeMint function
    require(tokenId < MAX_POPS, "Max supply");
    super._safeMint(to, tokenId);
  }

  // Reserve POPS for the team -------> TO_DO: CHECK IF STILL NEEDED <----------------------------------------------------------------!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  function reservePOPS(uint16 _amount) public onlyOwner onlyIfMintingEnabled {
    uint supply = totalSupply();
    for (uint16 i = 0; i < _amount; i++) {
      _safeMint(msg.sender, supply + uint256(i));
    }
  }


  ///// PROVENANCE FUNCTIONS /////

  function setProvenanceHash(string memory imageFilesHash, string memory imageCIDsHash) public onlyOwner {
    require(!provenanceData_locked, "The provenance hash has been locked forever");
    if(imageFilesHash != ""){POPS_provenanceHash_imageFiles = imageFilesHash;}
    if(imageCIDsHash != ""){POPS_provenanceHash_imageFileCIDs = imageCIDsHash;}
  }
  function lockProvenanceHash() public onlyOwner{                                 // Lock provenance data forever
    require(!provenanceData_locked, "The provenance hash is already locked");
    provenanceData_locked=true;
  }


  ///// BASE URI FUNCTIONS /////

  function setBaseURI(string memory newURI) public onlyOwner ifBaseURInotLocked { // Set Base URI
    baseURI = newURI;
  }
  function lockBaseURI() public onlyOwner ifBaseURInotLocked {                    // Lock Base URI forever
    baseURI_locked = true;
  }
  function _baseURI() internal view virtual override returns (string memory) {    // Get Base URI
    return baseURI;
  }


  ///// HODL TIMESTAMP FUNCTIONS /////
  
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);                                // Run base contract's beforeTokenTransfer function
    uint256 timeHodld = block.timestamp - lastTransferTimestamp[tokenId];         // Compute how long the token has been held by the address "from"
    if (from != address(0)) {                                                     // If not just minted,
      pastCumulativeHODL[from] += timeHodld;                                      // compute how long the token has been held cumulatively by the user
    }
    lastTransferTimestamp[tokenId] = block.timestamp;                             // Override the last transfer timestamp with the current time
  }
  // Get Cumulative HODL
  function cumulativeHODL(address user) public view returns (uint256) {           // Return how long the user has hodl'd the tokens in his wallet cumulatively
    uint256 _cumulativeHODL = pastCumulativeHODL[user];
    uint256 bal = balanceOf(user);
    for (uint256 i = 0; i < bal; i++) {
      uint256 tokenId = tokenOfOwnerByIndex(user, i);
      uint256 timeHodld = block.timestamp - lastTransferTimestamp[tokenId];
      _cumulativeHODL += timeHodld;
    }
    return _cumulativeHODL;
  }


  ///// TEAM WALLET FUNCTIONS /////
  //TO DO: add functions to change the teamWallet address to redirect sale revenues in the emergency case that something goes really badly (also consider a multiSig approach)
  // IF THESE ARE NOT IMPLEMENTED, FLAG TEAMWALLET VARIABLE AS IMMUTABLE

  ///// ROYALTIES FUNCTIONS /////
  // (these only apply where ERC2981 is supported)

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981Base) returns (bool){
    return super.supportsInterface(interfaceId);                                  // ERC2981 IMPLEMENTATION
  }
  function setRoyalties(uint256 value) public onlyOwner ifRoyaltiesNotLocked {    // Set the royalties (owned by POPS_teamWallet)
    require(value <= 1250, "Attempting to set royalties higher than 12.5% - don't be a greedy ass");
    _setRoyalties(POPS_teamWallet, value);
  }
  function lockRoyalties() public onlyOwner ifRoyaltiesNotLocked {                // Lock royalties forever
    royalties_locked=true;
  }

}