// SPDX-License-Identifier: MIT

/*
This token represents the golden tickets that can be used to redeem the LOLPOPS NFTs for free. When a golden ticket is used, 1 token unit is burnt.
*/

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";

interface POPSI{
    function maxPOPS() view external returns(uint256);
}

contract POPSgoldenTickets is ERC20Burnable, Ownable, Pausable {

    address immutable public POPS_contract;
    uint256 max_supply;

    constructor(string memory name, string memory symbol, address _POPS_contract) ERC20(name, symbol) {
        POPS_contract = _POPS_contract;
    }

    // Overloading the decimals function - no decimals are needed
    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function 

    function mint(address _recipient, uint16 _amount) external onlyOwner whenNotPaused returns (bool){
        _mint(_recipient, _amount);
        return true;
    }

}