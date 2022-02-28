// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Whitelist.sol";
import "./MintingRandomizer.sol";

// TODO: multiple mints at once
// TODO: dynamically reduce mintable supply depending on GT and WL
// TODO: modifier to restrict operations (eg whitelisting) until sale hasn't started

interface IPOPS{
    function mint(address to, uint256 tokenId) external;
    function updateRoyaltiesOwner(address newAddress) external;
    function totalSupply() view external returns(uint256);
}

interface TeamWallet {
    function listShareholders() external view returns(address[] memory);
}

interface GoldenTicket {
    function balanceOf(address account) external view returns(uint256);
}

contract POPSsale is Ownable, Pausable, ReentrancyGuard, Whitelist, MintingRandomizer{


    ///// CONTRACT VARIABLES /////

    // Addresses
    address payable POPS_teamWallet;
    address public immutable POPS_address;
    address public immutable POPS_goldenTicket;
    // Whitelist and golden tickets
    uint256 goldenTicketValidity = 2 days;
    uint256 whitelistValidity = 4 days;
    uint8 whitelistAllowance = 2;
    // Price
    uint16 priceStep = 1800;                                                                                        // Price increase every N sales
    uint256[6] priceCurve = [0.08 ether, 0.083 ether, 0.09 ether, 0.103 ether, 0.121 ether, 0.144 ether];           // Prices have been pre-calculated algorithmically and hardcoded to reduce gas usage
    // Time
    uint256 public saleStart;
    uint256 public saleEnd;

    mapping(uint256 => bool) minted;
    uint256 requestId;

    // Team Wallet address change request                                                                           // In case of emergency, Owner can request to amend the address payments are sent to, however the whole team must sign.
    address candidateTeamWallet = address(0);                                                                       // Candidate address
    address[] candidateTeamWallet_signatories;                                                                      // Team members required to sign


    ///// CONSTRUCTOR /////

    constructor(address _POPS, address payable _teamWallet, address _goldenTicket){
        POPS_address = _POPS;
        POPS_teamWallet = _teamWallet;
        POPS_goldenTicket = _goldenTicket;
    }


    ///// MODIFIERS /////

    modifier onlyDuringSale{
        require(block.timestamp >= saleStart, "Sale hasn't started yet");
        require(block.timestamp <= saleEnd, "Sale is over");
        _;
    }

    modifier useWhitelist{ ///// TODO: complete this
        if(block.timestamp < (saleStart + whitelistValidity)){  /////// TODO: COMPLETE THIS

        }
        _;
    }


    ///// FUNCTIONS - Misc /////

    function currentPrice() view public returns(uint256 price){
        price = priceCurve[ IPOPS(POPS_address).totalSupply() / priceStep ];
    }

    function nonReserved() view private returns(uint32 amount){} /////// TODO: COMPLETE THIS

    ///// FUNCTIONS - Time /////

    // Start the sale
    function startSale(uint256 _duration_days) public onlyOwner whenNotPaused returns(bool success){
        require(saleStart != 0, "Sale has already started");
        saleStart = block.timestamp;
        saleEnd = saleStart + (_duration_days * 1 days);
        success = true;
    }
    // Get time left before sale ends
    function sale_timeLeft() view public returns(uint256 time_left){
        require(saleEnd>0, "Sale hasn't started yet");
        if(saleEnd < block.timestamp){time_left = 0;}
        else{time_left = saleEnd - block.timestamp;}
    }

    // Main mint function
    function mint(uint8 _amount, uint8 _goldenTicketsToRedeem) payable public onlyDuringSale whenNotPaused nonReentrant returns(bool success){
        require(_amount > 0 && _amount <= 10, "You cannot mint more than 10 POPS at once");
        uint256 ethOwed; // placeholder
        require(msg.value > ethOwed, "Please make sure to send enough eth");
        (bool paid, ) = POPS_teamWallet.call{value: msg.value}("");
        bool mintOk = true; // placeholder
        success = (paid && mintOk);
    }

    /*
    function drawMint() public{
        _setMinterById(_nextMinterId(), msg.sender);
        minterRequestBlock[nextMinterId] = block.number;
        _shuffle();
        _setNextMinterId();
        if(!minted[requestId-2]){
            //_mint(_minterById(_nextMinterId()), _useMintId(0, MAX_POPS) );
        }
        requestId+=1;
    }
    */

    // Adds a list of addresses to the whitelist - input as an array ["address1", "address2", ...]                  // The functions to check whitelist allowance and
    function addToWhitelist(address[] calldata _addresses) public onlyOwner whenNotPaused returns(bool success){    // use it are already derived from the base contract
        require(block.timestamp < saleStart, "Sale has already started - whitelist permanently locked");
        batchWhitelist(_addresses, whitelistAllowance);
        success = true;
    }


    ///// EMERGENCY FUNCTIONS /////

    // Manually forward to teamWallet any balance stuck in the contract                                             // Unlikely to ever use but better safe than sorry
    function manualWithdraw() public onlyOwner whenPaused nonReentrant returns(bool success){
        require(address(this).balance>0, "Nothing to withdraw");
        (success, ) = POPS_teamWallet.call{value: address(this).balance}("");
    }
    // Candidate new team wallet
    function teamWalletChange_setCandidate(address _newAddress) public onlyOwner {                                  // Only Owner can request this
        require (_newAddress != POPS_teamWallet);                                                                   // Ensure a new address is being proposed
        candidateTeamWallet = _newAddress;
        candidateTeamWallet_signatories = TeamWallet(POPS_teamWallet).listShareholders();
        removeAddressItem(candidateTeamWallet_signatories, msg.sender);                                             // Remove Owner from signatories (Owner's signature is implicit)
    }
    // Get current candidate
    function teamWalletChange_getCandidate() view public returns(address){                                          // Show the current candidate
        return (candidateTeamWallet);
    }
    // Get addresses required to sign in order to approve the change                                               // Show the addresses required to sign in order to perform the change
    function teamWalletChange_requiredSignatories() view public returns(address[] memory){
        return(candidateTeamWallet_signatories);
    }
    // Approve candidate
    function teamWalletChange_approve() public {
        require(candidateTeamWallet != address(0) && candidateTeamWallet!=POPS_teamWallet);
        if(!removeAddressItem(candidateTeamWallet_signatories, msg.sender)){ revert("Sender is not allowed to sign or has already signed"); }
        if(candidateTeamWallet_signatories.length == 0){                                                            // If no signatories are left to sign,
        POPS_teamWallet = payable(candidateTeamWallet);                                                             // perform the change
        IPOPS(POPS_address).updateRoyaltiesOwner(candidateTeamWallet);                                              // Also update the royalties address
        }
    }
    // Remove List Item
    function removeAddressItem(address[] storage _list, address _item) private returns(bool success){              //Not a very efficient implementation but unlikely to run this function, ever
        for(uint i=0; i<_list.length; i++){
            if(_item == _list[i]){
                _list[i]=_list[_list.length-1];
                _list.pop();
                success=true;
                break;
            }
        }
    }
    // Pause the contract
    function pauseContract() public onlyOwner {
        _pause();
    }

    // Unpause the contract
    function unpauseContract() public onlyOwner {
        _unpause();
    }
}