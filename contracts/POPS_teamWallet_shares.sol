// SPDX-License-Identifier: MIT

/*
Team members will receive an amount of tokens representing their shares. When a POPS NFT is sold, each
token holder receives a revenue proportional to the amount of tokens. The total supply is 100 (actually
10000, with 2 decimals), so the address holding 10 tokens will receive 10% of the revenues, the address
holding 7.5 tokens will receive 7.5% of the revenues and so on. By using this approach, shareholders
are free to transfer their shares to other wallets (or even trade them), the new holders will
automatically start earing the dividends from new earnings as soon as they receive the tokens.
*/

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

contract POPSteamWallet is ERC20, Ownable, Pausable, ReentrancyGuard {

    ///// TOKEN EVENTS /////
    event AddedShareholder(address indexed shareHolder, address[] shareholderList);
    event RemovedShareholder(address indexed shareHolder, address[] shareholderList);
    ///// WALLET EVENTS /////
    event PaymentReceived(address, uint);
    event DividendsClaimed(address indexed, uint);
    
    using SafeMath for uint256;

    ///// TOKEN VARIABLES /////
    address[] shareholders;                                                                              // Array keeping track of the shareholders
    uint256[] shares;                                                                                    // Array keeping track of the shares, the indices will match with the shareholders list
    mapping (address => uint256) shareholderIndex;                                                       // Shareholder index in the two arrays above
    mapping (address => bool) isShareholder;                                                             // Flags which addresses are shareholders
    ///// WALLET VARIABLES /////
    mapping (address => uint256) dividends;                                                              // Accrued dividends for each shareholder
    uint256 dividendsToDistribute;
    ///// EMERGENCY VARIABLES /////
    address payable emergencyAddress;                                                                    // Address to send the funds to in case something goes really wrong. Needs the whole team to sign.
    address[] emergencyWithdraw_signatories;

    ///// CONSTRUCTOR /////
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 100 * 10 ** decimals());                                                       // Mint 10k shares - such amount is fixed
    }

    ///// FUNCTIONS /////
    function decimals() public pure override returns (uint8) {                                           // Overloading the decimals function
        return 2;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override{   // Also updates shareholders database
        bool isMinting = from == address(0);                                                             // Checks if the transaction is a minting
        require(isMinting || amount <= balanceOf(from), "The amount exceeds the sender's balance");      // Check if sender has enough funds
        distributeDividends();                                                                           // Distribute dividends before updating the shareholder list
        addShareholder(to);                                                                              // Add recipient to the shareholder list (the function performs no action if the address is already in the list)
        shares[ shareholderIndex[to] ] = balanceOf(to) + amount;                                         // Update recipient's value in the shares array
        if(isMinting || amount == balanceOf( from )){ removeShareholder( from ); }                       // Remove sender from the shareholders if transfers all shares, does nothing if the transfer is a minting
        else{shares[ shareholderIndex[ from ] ] = balanceOf( from ) - amount;}                           // Update sender's value in the shares array (if not zero)
        super._beforeTokenTransfer(from, to, amount);
    }

    // Add new shareholder
    function addShareholder(address newShareholder) private returns(bool added){
        if(!isShareholder[newShareholder]){                                                              // Do if not a shareholder yet
            shareholderIndex[newShareholder] = shareholders.length;                                      // Store shareholder's index in array
            shareholders.push(newShareholder);                                                           // Append shareholder's address to array
            shares.push(balanceOf(newShareholder));                                                      // Append shareholder's balance to array
            isShareholder[newShareholder]=true;                                                          // Flag the address as a shareholder
            emit AddedShareholder(newShareholder, shareholders);                                         // Emit event
            added=true;
        }
        else{ added=false; }
    }

    // Remove shareholder from database
    function removeShareholder(address shareholder) private returns(bool removed){
        if(isShareholder[shareholder]){                                                                  // Execute if the address is a shareholder
            shareholders[ shareholderIndex[shareholder] ] = shareholders[ shareholders.length - 1 ];     // Override item to be deleted with last item in array (address)
            shares[ shareholderIndex[shareholder] ] = shares[ shareholders.length - 1 ];                 // Override item to be deleted with last item in array (balance)
            shareholderIndex[ shareholders[ shareholders.length - 1 ] ] = shareholderIndex[shareholder]; // Update index of the array item being "moved"
            shareholders.pop();                                                                          // Remove last array item (address array)
            shares.pop();                                                                                // Remove last array item (balance array)
            isShareholder[shareholder] = false;                                                          // Flag address removed from array as NOT a shareholder
            emit RemovedShareholder(shareholder, shareholders);                                          // Emit event
            removed = true;
        }
        else{ removed=false; }                                                                           // Do nothing if not a shareholder
    }

    // Get current amount of shareholders
    function countShareholders() view public returns(uint count){
        count=shareholders.length;
    }

    // Get shareholders list
    function listShareholders() view public returns(address[] memory){
        return shareholders;
    }

    // Get shares list
    function listShares() view public returns(uint256[] memory){
        return shares;
    }

     // Get the total accrued dividends (aka contract's balance)
    function totalAccruedDividends() view public returns(uint256){
        return address(this).balance;
    }

    // Get the accrued dividends of the given shareholder
    function accruedDividends(address shareholder) view public returns(uint256 accrued){
        accrued = dividends[shareholder] + calculateDividend(shareholder, dividendsToDistribute);
    }

    // Calculate dividend proportional to shares
    function calculateDividend(address shareholder, uint256 value) view private returns(uint256 dividend){
        dividend = value.mul(balanceOf(shareholder)).div(100 * 10 ** decimals());
    }

    // Distribute dividends
    function distributeDividends() private returns(bool){
        if(dividendsToDistribute>0){
            uint256 dividendsToDistribute_before = dividendsToDistribute;                                // Used at the end to check invariances
            uint256 distributed;                                                                         // Keeps the count of dividends distributed in the for loop below
            for(uint256 i=0; i<countShareholders(); i++){
                address shareholder = shareholders[i];
                uint256 dividend = calculateDividend(shareholder, dividendsToDistribute);
                dividends[shareholder] += dividend;
                distributed += dividend;
            }
            dividendsToDistribute -= distributed;                                                        // Use subtract instead of overriding to zero in case there is any reminder
            assert(distributed <= dividendsToDistribute_before);
            return true;
        }
        else{return false;}
    }

    // Fallback for incoming payments
    receive() external payable nonReentrant {
        dividendsToDistribute+=msg.value;
        emit PaymentReceived(msg.sender, msg.value);
    }

    // Claim the accrued dividends
    function claimDividends() public whenNotPaused nonReentrant returns(bool){
        require( accruedDividends(msg.sender)>0, "This address has no dividends to claim");
        distributeDividends();                                                                           // Make sure all dividends are distributed before claiming
        uint256 value = dividends[msg.sender];
        dividends[msg.sender]=0;
        (bool sent, ) = msg.sender.call{value: value}("");
        emit DividendsClaimed(msg.sender, value);
        return sent;
    }

    ///// EMERGENCY FUNCTIONS /////
    // Propose an emergency withdraw (the whole team must sign or no action will be performed)
    function emergencyWithdraw_propose(address payable _withdrawTo) public onlyOwner {                    // Only Owner can request this
        require (_withdrawTo != address(this) );                                                          // Ensure a new address is being proposed
        emergencyAddress = _withdrawTo;
        emergencyWithdraw_signatories = listShareholders();
        removeAddressItem(emergencyWithdraw_signatories, msg.sender);                                     // Remove Owner from signatories (Owner's signature is implicit)
    }
    // Get proposed emergency address
    function emergencyWithdraw_getAddress() view public returns(address){                                 // Show the current candidate
        return (emergencyAddress);
    }
    // Get addresses required to sign in order to approve the withdraw                                    // Show the addresses required to sign in order to perform the change
    function emergencyWithdraw_requiredSignatories() view public returns(address[] memory){
        return(emergencyWithdraw_signatories);
    }
    // Approve emergency withdraw
    function emergencyWithdraw_approve() public {
        require(emergencyAddress != address(0) && emergencyAddress!=address(this));
        if(!removeAddressItem(emergencyWithdraw_signatories, msg.sender)){ revert("Sender is not allowed to sign or has already signed"); }
        if(emergencyWithdraw_signatories.length == 0){                                                    // If no signatories are left to sign,
            (bool success, ) = emergencyAddress.call{value: address(this).balance}("");                   // perform the withdraw
            delete emergencyAddress;                                                                      // Clear the emergency address variable
        }
    }
    // Remove List Item
    function removeAddressItem(address[] storage _list, address _item) private returns(bool success){     //Not a very efficient implementation but unlikely to run this function, ever
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