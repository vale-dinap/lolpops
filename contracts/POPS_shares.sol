// SPDX-License-Identifier: MIT

/*
This token represents the amount of shares that each team member has. When a POPS NFT is sold, each token holder receives a revenue
proportional to the amount of tokens. The total supply is 100 (actually 10000, with 2 decimals), so the address holding 10 tokens will
receive 10% of the revenues, the address holding 7.5 tokens will receive 7.5% of the revenues and so on.
By using this approach, shareholders are free to transfer their shares to other wallets (or even trade them),
the new holders will automatically receive the dividends
from that time on.
*/

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract POPSshares is ERC20 {

    event AddedShareholder(address indexed shareHolder, address[] shareholderList);
    event RemovedShareholder(address indexed shareHolder, address[] shareholderList);

    address[] shareholders;                                                                              // Array keeping track of the shareholders
    uint256[] shares;                                                                                    // Array keeping track of the shares, the indices will match with the shareholders list
    mapping (address => uint256) shareholderIndex;                                                       // Shareholder index in the two arrays above
    mapping (address => bool) isShareholder;                                                             // Flags which addresses are shareholders

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 100 * 10 ** decimals());                                                       // Mint 10k shares - such amount is fixed
    }

    function decimals() public pure override returns (uint8) {                                           // Overloading the decimals function
        return 2;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override{   // Also updates shareholders database
        bool isMinting = from == address(0);                                                             // Check if the transaction is a minting
        require(isMinting || amount <= balanceOf(from), "The amount exceeds the sender's balance");      // Check if sender has enough funds
        addShareholder(to);                                                                              // Add recipient to the shareholder list (the function performs no action if the address is already in the list)
        shares[ shareholderIndex[to] ] = balanceOf(to) + amount;                                         // Update recipient's value in the shares array
        if(isMinting || amount == balanceOf( from )){ removeShareholder( from ); }                       // Remove sender from the shareholders if transfers all shares, does nothing if the transfer is a minting
        else{shares[ shareholderIndex[ from ] ] = balanceOf( from ) - amount;}                           // Update sender's value in the shares array (if not zero)
        super._beforeTokenTransfer(from, to, amount);
    }

    function countShareholders() view external returns(uint count){
        count=shareholders.length;
    }

    function listShareholders() view external returns(address[] memory){
        return shareholders;
    }

    function listShares() view external returns(uint256[] memory){
        return shares;
    }

    // Add new shareholder
    function addShareholder(address newShareholder) internal returns(bool added){
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
    function removeShareholder(address shareholder) internal returns(bool removed){
        if(isShareholder[shareholder]){                                                                  // Execute if the address is a shareholder
            shareholders[ shareholderIndex[shareholder] ] = shareholders[ shareholders.length - 1 ];     // Override item to delete with last item in array (address)
            shares[ shareholderIndex[shareholder] ] = shares[ shareholders.length - 1 ];                 // Override item to delete with last item in array (balance)
            shareholderIndex[ shareholders[ shareholders.length - 1 ] ] = shareholderIndex[shareholder]; // Update index of the array item being "moved"
            shareholders.pop();                                                                          // Remove last array item (address array)
            shares.pop();                                                                                // Remove last array item (balance array)
            isShareholder[shareholder] = false;                                                          // Flag address removed from array as NOT a shareholder
            emit RemovedShareholder(shareholder, shareholders);                                          // Emit event
            removed = true;
        }
        else{ removed=false; }                                                                           // Do nothing if not a shareholder
    }

}