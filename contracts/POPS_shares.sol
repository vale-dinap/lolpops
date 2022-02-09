// SPDX-License-Identifier: MIT

/*
This token represents the amount of shares that each team member has. When a POPS NFT is sold, each token holder receives a revenue
proportional to the amount of tokens. The total supply is 10'000, so the address holding 1000 tokens will receive 10% of the revenues,
the address holding 750 tokens will receive 7.5% of the revenues and so on. By using this approach, shareholders are free to transfer/split
their shares among their wallets, or even trade/gift them.
*/

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract POPsShares is ERC20 {

    event AddedShareholder(address indexed shareHolder, address[] shareholderList);
    event RemovedShareholder(address indexed shareHolder, address[] shareholderList);

    address[] shareholders;
    mapping (address => bool) isShareholder;
    mapping (address => uint256) shareholderIndex;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 10000);
        addShareholder(msg.sender);
    }
    
    function transfer(address recipient, uint256 amount) public override returns(bool){ // Also updates shareholders database
        require(amount <= balanceOf(msg.sender), "The amount exceeds the sender's balance");
        addShareholder(recipient);
        if(amount == balanceOf(msg.sender)){ removeShareholder(msg.sender); }
        super.transfer(recipient, amount);
        return true;
    }

    function countShareholders() view external returns(uint count){
        count=shareholders.length;
    }

    function listShareholders() view external returns(address[] memory){
        return shareholders;
    }

    function addShareholder(address newShareholder) internal returns(bool added){
        if(!isShareholder[newShareholder]){
            shareholderIndex[newShareholder] = shareholders.length; // Store shareholder's index in array
            shareholders.push(newShareholder);  // Append shareholder's address to array
            isShareholder[newShareholder]=true; // Flag the address as a shareholder
            emit AddedShareholder(newShareholder, shareholders);
            added=true;
        }
        else{ added=false; }
    }

    function removeShareholder(address shareholder) internal returns(bool removed){
        if(isShareholder[shareholder]){ // Execute if the address is a shareholder
            shareholders[ shareholderIndex[shareholder] ] = shareholders[ shareholders.length - 1 ]; // Override item to delete with last item in array
            shareholderIndex[ shareholders[ shareholders.length - 1 ] ] = shareholderIndex[shareholder]; // Update index of the array item being "moved"
            shareholders.pop(); // Remove last array item
            isShareholder[shareholder] = false; // Flag address removed from array as NOT a shareholder
            emit RemovedShareholder(shareholder, shareholders);
            removed = true;
        }
        else{ removed=false; } // Do noyhing if not a shareholder
    }

}