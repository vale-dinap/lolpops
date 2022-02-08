// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "../node_modules/@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "../node_modules/@openzeppelin/contracts/security/PullPayment.sol";

contract POPsWallet is Ownable, Pausable, ReentrancyGuard, PullPayment{
    //// PLACEHOLDER

}