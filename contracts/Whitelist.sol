// SPDX-License-Identifier: MIT

// Base contract for whitelist

import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

pragma solidity ^0.8.0;

contract Whitelist{

    uint16 private whitelist_totalAllowance;
    mapping(address => uint8) whitelist_claimed;
    bytes32 public whitelist_merkleRoot;

    /*
    functoin inspectMerkleTree (bytes32[] calldata merkleProof, bytes32 merkleRoot, address account){
        require(whitelist_claimed[account] < 2, "Address already claimed");
        bytes32 leaf = keccak256(abi.encode(_account));
        require(MerkleProof.verify(_merkleProof, _merkleRoot, leaf), "Caller is not a claimer");
    }*/

    // Get whitelist allowance of given address
    function getWhitelistAllowance(address _account, bytes32[] calldata _merkleProof, bytes32 _merkleRoot) view public returns(uint allowance){
        if(whitelist_claimed[_account]>0) allowance = 2-whitelist_claimed[_account];
        else{
            bytes32 leaf = keccak256(abi.encode(_account));
            allowance = ( MerkleProof.verify(_merkleProof, _merkleRoot, leaf) ? 2 : 0 );
        }
    }
    // Get whitelist total allowance
    function getWhitelistTotalAllowance() view public returns(uint totalAllowance){
        totalAllowance = whitelist_totalAllowance;
    }
    // Use allowance
    function _useWhitelistAllowance(address _address, uint8 _amount) internal virtual returns(bool){
        if (_amount + whitelist_claimed[_address] > 1){
            whitelist_totalAllowance -= (2-whitelist_claimed[_address]);
            whitelist_claimed[_address]=2;
        }                      
        else {
            whitelist_claimed[_address] += _amount;
            whitelist_totalAllowance -= _amount;
        }
        return true;
    }
}