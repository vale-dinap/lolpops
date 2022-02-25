// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import './ERC2981/ERC2981ContractWideRoyalties.sol';

///// TODO: integrate final provenance proofs
///// TODO: reduce max supply to current supply after minting is over ----might edit the reounceMinting function
///// TODO: consider getting rid of lockable variables where possible (eg provenance to avoid the reduce the amount of transactions)
///// TODO: consider replacing setUnrevealedURI function with a hardcoded value

contract lolpops is Ownable, ERC721Enumerable, ERC2981ContractWideRoyalties {

  using Strings for uint256;

  ///// EVENTS /////

  event RevealedBaseURI(uint8 indexed batchId, string indexed URI);
  event LockedBaseURI(uint8 indexed batchId);
  event RoyaltiesAddressChanged(address newAddress);


  ///// CONTRACT VARIABLES /////

  // Addresses
  address public POPS_saleContract;                                                                   // Sale contract address
  // Token data - main
  uint256 public MAX_POPS;
  mapping(uint8 => string) public baseURI;                                                            // There are 20 base URIs instead of 1, (each holding data of 250 NFTs) - in combination with the randomized purchase and batch delayed revealing, this makes the system impossible to exploit
  string public unrevealedURI;                                                                        // URI to be used before reveal
  // Token data - timestamps
  mapping(uint256 => uint256) public lastTransferTimestamp;                                           // Stores the last time a token has been transferred
  mapping(address => uint256) private pastCumulativeHODL;                                             // Stores how long a token has been hodl'd by a user
  // Provenance
  string public POPS_provenance_imageFiles = "";                                                      // Hash of all image files hashes concatenated
  string public POPS_provenance_imageFileCIDs = "";// TODO: CHECK IF NEEDED                           // Hash of all image files IPFS CIDs concatenated
  // Permissions
  mapping(uint8 => bool) public baseURI_locked;                                                       // Once locked, it is forever (one per batch)
  bool public minting_disabled = false;                                                               // Once disabled, it is forever
  bool public provenanceData_locked = false;                                                          // Once locked, it is forever


  ///// MODIFIERS /////

  modifier ifMintingEnabled{                                                                          // Can lock access to functions after "renounceMinting()" has been run
    require(!minting_disabled, "Minting has been permanently disabled");
    _;
  }

  modifier ifBaseURIunlocked(uint8 URI_batchId){                                                      // Can deny access to functions if baseURI has been locked
    require(!baseURI_locked[URI_batchId], "The baseURI of this batch has been permanently locked");
    _;
  }

  modifier onlySaleContract{
    require(msg.sender == POPS_saleContract, "Access reserved to sale contract");
    _;
  }


  ///// CONSTRUCTOR /////

  constructor(string memory _name, string memory _symbol, uint256 maxSupply, address _POPS_teamWallet) Ownable() ERC721(_name, _symbol) {
    MAX_POPS = maxSupply;                                                                             // Setting the max supply
    _setRoyalties(_POPS_teamWallet, 375);                                                             // Setting to 375 (corrensponding to 3.75%)
  }


  ///// MINTING FUNCTIONS /////

  function prepareSale(address _saleContract) public onlyOwner ifMintingEnabled {                     // Links the external sale contract
    require(POPS_saleContract == address(0));                                                         // Once set, can't be overridden
    POPS_saleContract = _saleContract;
  }

  function mint(address to, uint256 tokenId) external virtual ifMintingEnabled onlySaleContract {     // Mint function used by the sale contarct
    _safeMint(to, tokenId);
  }

  function renounceMinting() public onlyOwner ifMintingEnabled {                                      // Warning: disables minting forever
    POPS_saleContract = address(0);                                                                   // Unlink sale contract addess
    MAX_POPS = totalSupply();                                                                         // Override max supply with current supply
    minting_disabled = true;                                                                          // Flag minting as disabled
  }

  // Add supply cap to _safeMint function
  function _safeMint(address to, uint256 tokenId) internal virtual override {
    require(tokenId < MAX_POPS, "Max supply");                                                        // Ensures this mint doesn't exceed max supply
    super._safeMint(to, tokenId);                                                                     // Base contract's _safeMint
  }


  ///// PROVENANCE FUNCTIONS /////

  function setProvenance(string memory imageFilesHash, string memory imageCIDsHash) public onlyOwner {
    require(!provenanceData_locked, "The provenance hash has been locked forever");
    POPS_provenance_imageFiles = imageFilesHash;
    POPS_provenance_imageFileCIDs = imageCIDsHash;
  }
  function lockProvenance() public onlyOwner{                                                         // Lock provenance data forever
    require(!provenanceData_locked, "The provenance hash is already locked");
    provenanceData_locked=true;
  }


  ///// TOKEN URI FUNCTIONS /////

  function setUnrevealedURI(string memory _unrevealedUri) public onlyOwner {
    unrevealedURI = _unrevealedUri;
  }
  // Set base URI (by batch ID - 20 batches in total)
  function setBaseURI(string memory _URI, uint8 batchId, bool _lock) public onlyOwner ifBaseURIunlocked(batchId) {
    baseURI[batchId] = _URI;
    emit RevealedBaseURI(batchId, _URI);
    if(_lock) lockBaseURI(batchId);                                                                   // Optionally, also lock the URI
  }
  // Lock Base URI forever
  function lockBaseURI(uint8 batchId) public onlyOwner ifBaseURIunlocked(batchId) {
    baseURI_locked[batchId] = true;
    emit LockedBaseURI(batchId);
  }
  // Get Base URI
  function _baseURI(uint8 batchId) internal view virtual returns (string memory) {
    return baseURI[batchId];
  }
  // Actual function to get the final URI (also used by Opensea etc.)
  function tokenURI(uint256 _tokenId) public view override returns (string memory){
    bool revealed = abi.encode(baseURI[getURIbatchId(_tokenId)]).length > 0;                          // If the base URI is empty, consider the token as NOT revealed,
    if (!revealed) { return unrevealedURI; }                                                          // then return the alternative URI
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");                    // Check if the token exists
    return string(abi.encodePacked(baseURI[getURIbatchId(_tokenId)], (_tokenId + 1).toString()));     // Retrieve the base URI and combine it with the token ID to return the final token URI
  }
  // Retrieve batch ID from token ID
  function getURIbatchId(uint256 tokenId) pure private returns(uint8 batchId){
    batchId = uint8((tokenId-(tokenId%250))/250);
  }


  ///// HODL TIMESTAMP FUNCTIONS /////
  
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);                                                    // Run base contract's beforeTokenTransfer function
    uint256 timeHodld = block.timestamp - lastTransferTimestamp[tokenId];                             // Compute how long the token has been held by the address "from"
    if (from != address(0)) {                                                                         // If not just minted,
      pastCumulativeHODL[from] += timeHodld;                                                          // compute how long the token has been held cumulatively by the user
    }
    lastTransferTimestamp[tokenId] = block.timestamp;                                                 // Override the last transfer timestamp with the current time
  }
  // Get Cumulative HODL
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

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981Base) returns (bool){
    return super.supportsInterface(interfaceId);                                                      // ERC2981 IMPLEMENTATION
  }

  function updateRoyaltiesOwner(address newAddress) external onlySaleContract returns(bool success){  // Allows the sale contract to update the royalties address (requires the whole team to sign)
    _setRoyalties(newAddress, 375);
    emit RoyaltiesAddressChanged(newAddress);
    success = true;
  }

}