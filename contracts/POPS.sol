// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import './ERC2981/ERC2981ContractWideRoyalties.sol';

//TODO: consider replacing unrevealed URI function with hardcoded value

contract lolpops is Ownable, ERC721Enumerable, ERC2981ContractWideRoyalties {

  using Strings for uint256;

  ///// EVENTS /////

  event RevealedBaseURI(uint8 indexed batchId, string indexed URI);
  event LockedBaseURI(uint8 indexed batchId);


  ///// CONTRACT VARIABLES /////

  // Permissions
  bool public minting_disabled = false;                                                               // Once disabled, it is forever
  mapping(uint8 => bool) public baseURI_locked;                                                       // Once locked, it is forever (one per batch)
  // Token data - timestamps
  mapping(address => uint256) private pastCumulativeHODL;                                             // Stores how long a token has been hodl'd by a user
  mapping(uint256 => uint256) public lastTransferTimestamp;                                           // Stores the last time a token has been transferred
  // Token data - main
  mapping(uint8 => string) public baseURI;                                                            // There are 40 base URIs instead of 1, (each holding data of 250 NFTs) - in combination with the randomized purchase and batch delayed revealing, this makes the system impossible to exploit
  uint256 public MAX_POPS;                                                                            // Max supply
  string public unrevealedURI;                                                                        // URI to be used before reveal
  // Provenance                                                                                       // Final provenance hash
  string constant public POPS_provenance = "0a08d494d977e3ab4b4e7285c1521129db91da2192ef2c903c7af3e6e31e42f1";
  // Addresses
  address public POPS_saleContract;                                                                   // Sale contract address


  ///// MODIFIERS /////

  modifier ifMintingEnabled{                                                                          // Can lock access to functions after "renounceMinting()" has been run
    require(!minting_disabled, "Minting has been permanently disabled");
    _;
  }

  modifier ifBaseURIunlocked(uint8 URI_batchId){                                                      // Can deny access to functions if baseURI has been locked
    require(!baseURI_locked[URI_batchId], "The baseURI of this batch has been permanently locked");
    _;
  }


  ///// CONSTRUCTOR /////

  constructor(string memory _name, string memory _symbol, uint256 maxSupply, address _POPS_teamWallet) Ownable() ERC721(_name, _symbol) {
    MAX_POPS = maxSupply;                                                                             // Setting the max supply
    _setRoyalties(_POPS_teamWallet, 375);                                                             // Setting to 375 (corrensponding to 3.75%)
  }


  ///// MINTING FUNCTIONS /////

  // [Tx][Public][Owner]
  function prepareSale(address _saleContract) public onlyOwner ifMintingEnabled {                     // Links the external sale contract
    require(POPS_saleContract == address(0));                                                         // Once set, can't be overridden
    POPS_saleContract = _saleContract;
  }
  // [Tx][External]
  function mint(address to, uint256 tokenId) external virtual ifMintingEnabled {                      // Mint function used by the sale contarct
    require(msg.sender == POPS_saleContract, "Access reserved to sale contract");
    _safeMint(to, tokenId);
  }
  // [Tx][Public][Owner]
  function renounceMinting() public onlyOwner ifMintingEnabled {                                      // Warning: disables minting forever
    POPS_saleContract = address(0);                                                                   // Unlink sale contract addess
    MAX_POPS = totalSupply();                                                                         // Override max supply with current supply
    minting_disabled = true;                                                                          // Flag minting as disabled
  }
  // [Tx][Internal] Add supply cap to _safeMint function
  function _safeMint(address to, uint256 tokenId) internal virtual override {
    require(tokenId < MAX_POPS, "Max supply");                                                        // Ensures this mint doesn't exceed max supply
    super._safeMint(to, tokenId);                                                                     // Base contract's _safeMint
  }


  ///// TOKEN URI FUNCTIONS /////

  // [Tx][Public][Owner]
  function setUnrevealedURI(string calldata _unrevealedUri) public onlyOwner {
    unrevealedURI = _unrevealedUri;
  }
  // [Tx][Public][Owner] Set base URI (by batch ID - 40 batches in total)
  function setBaseURI(string calldata _URI, uint8 batchId, bool _lock) public onlyOwner ifBaseURIunlocked(batchId) {
    baseURI[batchId] = _URI;
    emit RevealedBaseURI(batchId, _URI);
    if(_lock) lockBaseURI(batchId);                                                                   // Optionally, also lock the URI
  }
  // [Tx][Public][Owner] Lock Base URI forever
  function lockBaseURI(uint8 batchId) public onlyOwner ifBaseURIunlocked(batchId) {
    baseURI_locked[batchId] = true;
    emit LockedBaseURI(batchId);
  }
  // [View][Internal] Get Base URI
  function _baseURI(uint8 batchId) internal view virtual returns (string memory) {
    return baseURI[batchId];
  }
  // [View][Public] Actual function to get the final URI (also used by Opensea etc.)
  function tokenURI(uint256 _tokenId) public view override returns (string memory){
    bool revealed = abi.encode(baseURI[getURIbatchId(_tokenId)]).length > 0;                          // If the base URI is empty, consider the token as NOT revealed,
    if (!revealed) { return unrevealedURI; }                                                          // then return the alternative URI
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");                    // Check if the token exists
    return string(abi.encodePacked(baseURI[getURIbatchId(_tokenId)], (_tokenId + 1).toString()));     // Retrieve the base URI and combine it with the token ID to return the final token URI
  }
  // [Pure][Private] Retrieve batch ID from token ID
  function getURIbatchId(uint256 tokenId) pure private returns(uint8 batchId){
    batchId = uint8((tokenId-(tokenId%250))/250);
  }


  ///// HODL TIMESTAMP FUNCTIONS /////
  
  // [Tx][Internal]
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);                                                    // Run base contract's beforeTokenTransfer function
    uint256 timeHodld = block.timestamp - lastTransferTimestamp[tokenId];                             // Compute how long the token has been held by the address "from"
    if (from != address(0)) {                                                                         // If not just minted,
      pastCumulativeHODL[from] += timeHodld;                                                          // compute how long the token has been held cumulatively by the user
    }
    lastTransferTimestamp[tokenId] = block.timestamp;                                                 // Override the last transfer timestamp with the current time
  }
  // [View][Public] Get Cumulative HODL
  function cumulativeHODL(address user) public view returns (uint256) {                               // Return how long the user has hodl'd the tokens in his wallet cumulatively
    uint256 _cumulativeHODL = pastCumulativeHODL[user];
    uint256 bal = balanceOf(user);
    for (uint256 i = 0; i < bal; i++) {
      uint256 tokenId = tokenOfOwnerByIndex(user, i);
      uint256 timeHodld = block.timestamp - lastTransferTimestamp[tokenId];
      _cumulativeHODL += timeHodld;
    }
    return _cumulativeHODL;
  }

  
  ///// ROYALTIES FUNCTIONS /////
  // (these only apply where ERC2981 is supported)

  // [View][Public]
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981Base) returns (bool){
    return super.supportsInterface(interfaceId);                                                      // ERC2981 IMPLEMENTATION
  }

}