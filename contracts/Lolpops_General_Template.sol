{\rtf1\ansi\ansicpg1252\cocoartf2636
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 AndaleMono;}
{\colortbl;\red255\green255\blue255;\red171\green173\blue176;\red35\green37\blue41;}
{\*\expandedcolortbl;;\cssrgb\c72549\c73333\c74510;\cssrgb\c18431\c19216\c21176;}
\margl1440\margr1440\vieww19260\viewh14160\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs28 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 pragma solidity ^0.8.0;\
\
import "../tokens/ERC721Enumerable.sol";\
import "../tokens/IERC20.sol";\
import "../utils/Ownable.sol";\
\
interface SaleContract \{\
  function loadSale(uint256 count) external;\
\}\
\
contract lolpops is Ownable, ERC721Enumerable \{\
  address public saleContract;\
\
  uint256 constant BASE = 10**18;\
  uint256 constant MAX_SUPPLY = 10000;\
  uint256 public amountToLP;\
\
  constructor(string memory _name, string memory _symbol) Ownable() ERC721(_name, _symbol) \{\
  \}\
\
  function mint(address to, uint256 tokenId) public virtual \{\
    require(msg.sender == saleContract, "Nice try lol");\
    require(tokenId < MAX_SUPPLY, "Max supply");\
    super._safeMint(to, tokenId);\
  \}\
\
  function prepareSale(address _saleContract) public onlyOwner \{\
    require(saleContract == address(0));\
    saleContract = _saleContract;\
    SaleContract(_saleContract).loadSale(MAX_SUPPLY);\
  \}\
\}}