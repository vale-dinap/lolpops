// SPDX-License-Identifier: MIT

// Base contract for whitelist

pragma solidity ^0.8.0;

contract Whitelist{

    event Whitelisted(address[] indexed _addresses, uint256 _allowance, uint256 _totalAllowance);

    mapping(address => uint256) private whitelistAllowance;
    uint256 private whitelistTotalAllowance;

    // Tests have demonstrated that a combinaton of for loop and explicitly repeated commands is the most efficient (and less gas-consuming) way to loop through thousands of addresses
    // For ~2500 addresses, looping through 16 repeated lines has proven to give the best results
    function batchWhitelist(address[] calldata _addresses, uint256 _allowance) internal virtual returns(bool){
        uint256 remainder = _addresses.length%16;
        for (uint256 index=0; index<(_addresses.length-remainder); index+=16){
            whitelistAllowance[_addresses[index    ] ] = _allowance;
            whitelistAllowance[_addresses[index + 1] ] = _allowance;
            whitelistAllowance[_addresses[index + 2] ] = _allowance;
            whitelistAllowance[_addresses[index + 3] ] = _allowance;
            whitelistAllowance[_addresses[index + 4] ] = _allowance;
            whitelistAllowance[_addresses[index + 5] ] = _allowance;
            whitelistAllowance[_addresses[index + 6] ] = _allowance;
            whitelistAllowance[_addresses[index + 7] ] = _allowance;
            whitelistAllowance[_addresses[index + 8] ] = _allowance;
            whitelistAllowance[_addresses[index + 9] ] = _allowance;
            whitelistAllowance[_addresses[index +10] ] = _allowance;
            whitelistAllowance[_addresses[index +11] ] = _allowance;
            whitelistAllowance[_addresses[index +12] ] = _allowance;
            whitelistAllowance[_addresses[index +13] ] = _allowance;
            whitelistAllowance[_addresses[index +14] ] = _allowance;
            whitelistAllowance[_addresses[index +15] ] = _allowance;
        }
        for (uint256 i=(_addresses.length-remainder); i<_addresses.length; i++){
            whitelistAllowance[_addresses[i]] = _allowance;
        }

        whitelistTotalAllowance+=(_addresses.length * _allowance);

        emit Whitelisted(_addresses, _allowance, whitelistTotalAllowance);
        return true;
    }

    // Get whitelist allowance of given address
    function getWhitelistAllowance(address _address) view public returns(uint allowance){
        allowance = whitelistAllowance[_address];
    }

    // Get whitelist total allowance
    function getWhitelistTotalAllowance() view public returns(uint totalAllowance){
        totalAllowance = whitelistTotalAllowance;
    }

    // Reduce allowance
    function _reduceWhitelistAllowance(address _address, uint256 _amount) internal virtual returns(bool){
        if (_amount >= whitelistAllowance[_address]){
            delete whitelistAllowance[_address];                                                          // Free up storage in exchange of gas discount
            whitelistTotalAllowance-=whitelistAllowance[_address];
        }                      
        else {
            whitelistAllowance[_address] -= _amount;
            whitelistTotalAllowance -= _amount;
        }
        return true;
    }
}