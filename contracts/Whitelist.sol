// SPDX-License-Identifier: MIT

// Base contract for whitelist

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

pragma solidity ^0.8.0;

contract Whitelist{

    uint8 whitelist_allowance = 2;                                                                        // Allowance per address
    uint16 private whitelist_totalAllowance;                                                              // Total allowance of whitelist, set via constructor
    mapping(address => uint8) whitelist_claimed;                                                          // Tracks whitelist addresses that have already claimed
    bytes32 public whitelist_merkleRoot;                                                                  // MerkleRoot of the whitelist, set via constructor

    ///// FUNCTIONS /////

    // [Tx][Internal] Initialize whitelist - NOTE: restrict to owner before exposing
    function _whitelistInitialize (uint16 _whitelist_length, bytes32 _whitelist_merkleRoot) internal returns (bool success){
        whitelist_totalAllowance = _whitelist_length*whitelist_allowance;
        whitelist_merkleRoot = _whitelist_merkleRoot;
        success=true;
    }

    // [View][Public] Get whitelist allowance of given address
    function getWhitelistAllowance(address _account, bytes32[] calldata _merkleProof) view public returns(uint8 allowance){
        if(whitelist_claimed[_account]>0) allowance = 2-whitelist_claimed[_account];
        else{
            bytes32 leaf = keccak256(abi.encode(_account));
            allowance = ( MerkleProof.verify(_merkleProof, whitelist_merkleRoot, leaf) ? whitelist_allowance : 0 );
        }
    }

    // [View][Public] Get whitelist total allowance
    function getWhitelistTotalAllowance() view public returns(uint totalAllowance){
        totalAllowance = whitelist_totalAllowance;
    }

    // [Tx][Internal] Use whitelist allowance
    function _useWhitelistAllowance(address _address, uint8 _amount, bytes32[] calldata _merkleProof) internal virtual returns(uint8 used){
        uint8 addressAllowance;
        if(whitelist_claimed[_address]>0) addressAllowance = 2-whitelist_claimed[_address];
        else addressAllowance = getWhitelistAllowance(_address, _merkleProof);
        if(addressAllowance>0){
            if (_amount < addressAllowance) used = addressAllowance - _amount;                     
            else used = addressAllowance;
            whitelist_totalAllowance -= used;
            whitelist_claimed[_address] += used;
        }
        else used=0;
    }
}