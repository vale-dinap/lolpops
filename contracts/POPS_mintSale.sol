// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Timers.sol";
import "./Whitelist.sol";
import "./MintingRandomizer.sol";

// TODO: multiple mints at once
// TODO: dynamically reduce mintable supply depending on GT and WL
// TODO: modifier to restrict operations (eg whitelisting) until sale hasn't started

interface IPOPS{
    function mint(address to, uint256 tokenId) external;
    function updateRoyaltiesOwner(address newAddress) external;
}

interface TeamWallet {
  function listShareholders() external view returns(address[] memory);
}

contract POPSsale is Ownable, Pausable, Whitelist, MintingRandomizer{

    address payable POPS_teamWallet;
    address immutable POPS_address;

    uint8 whitelistValidity = 4; ///// 4 days - convert to blocks or use block.timestamp
    uint8 whitelistAllowance = 2;
    uint8 goldenTicketValidity = 2; ///// 2 days
    uint256[6] priceCurve = [80000000000000000, 83000000000000000, 90000000000000000,
                            103000000000000000, 121000000000000000, 144000000000000000];                            // In WEI
    uint16[6] priceStep   = [0, 1801, 3601, 5401, 7201, 9001];                                                      // Sold pieces required to unlock next price

    mapping(uint256 => bool) minted;
    uint256 requestId;

    // Team Wallet address change request                                                                           // In case of emergency, Owner can request to amend the address payments are sent to, however the whole team must sign.
    address candidateTeamWallet = address(0);                                                                       // Candidate address
    address[] candidateTeamWallet_signatories;                                                                      // Team members required to sign

    constructor(address _POPS, address payable _teamWallet){
        POPS_address = _POPS;
        POPS_teamWallet = _teamWallet;
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
        batchWhitelist(_addresses, whitelistAllowance);
        success = true;
    }


    ///// TEAM WALLET EMERGENCY FUNCTIONS /////
    // Candidate new team wallet
    function teamWalletChange_setCandidate(address _newAddress) public onlyOwner {                                  // Only Owner can request this
        require (_newAddress != POPS_teamWallet);                                                                   // Ensure a new address is being proposed
        candidateTeamWallet = _newAddress;
        candidateTeamWallet_signatories = TeamWallet(POPS_teamWallet).listShareholders();
        removeAddressItem(candidateTeamWallet_signatories, msg.sender);                                             // Remove Owner from signatories (Owner's signature is implicit)
    }
    // Shows current candidate
    function teamWalletChange_getCandidate() view public returns(address){                                          // Show the current candidate
        return (candidateTeamWallet);
    }
    // Show addresses required to sign in order to perform the change                                               // Show the addresses required to sign in order to perform the change
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
    function removeAddressItem(address[] storage _list, address _item) internal returns(bool success){              //Not a very efficient implementation but unlikely to run this function, ever
        for(uint i=0; i<_list.length; i++){
            if(_item == _list[i]){
                _list[i]=_list[_list.length-1];
                _list.pop();
                success=true;
                break;
            }
        }
    }

}