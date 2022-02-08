// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "../node_modules/@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "../node_modules/@openzeppelin/contracts/security/PullPayment.sol";

contract POPsWallet is Ownable, Pausable, ReentrancyGuard, PullPayment{

    // Each wallet will be assigned an amount of shares - might mint an ERC20 token for that
    // 10000 shares equal to 100% of the revenue
    

    struct mystruct{
        uint hello; /////// PLACEHOLDER!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    }

    constructor() Ownable() Pausable() ReentrancyGuard() {}


}