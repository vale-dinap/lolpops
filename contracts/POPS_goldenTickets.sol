// SPDX-License-Identifier: MIT

/*
This token represents the golden tickets that can be used to redeem LOLPOPS NFTs for free. 
When a golden ticket is used, 1 token unit is burnt.
*/

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

interface IPOPS{
    function MAX_POPS() view external returns(uint256);
    function totalSupply() view external returns(uint256);
}

contract POPSgoldenTickets is ERC20, Ownable {

    // EVENTS
    event MintingDisabled();

    // CONTRACT VARIABLES
    bool mintingEnabled;
    address immutable public POPS_contract;
    address immutable public POPS_sale_contract;
    
    // CONSTRUCTOR
    constructor(string memory name, string memory symbol, address _POPS_sale_contract, address _POPS_contract) Ownable() ERC20(name, symbol) {
        POPS_sale_contract = _POPS_sale_contract;
        POPS_contract = _POPS_contract;
        mintingEnabled = true;
    }

    // FUNCTIONS
    // [Pure][Public] Overriding the decimals function - no decimals are needed
    function decimals() public pure override returns (uint8) {
        return 0;
    }
    // [Tx][Public][Owner] Mint function, takes an array of addresses as first argument. To mint to a single address, input an array with a single element.
    function mintTickets(address[] calldata _accounts, uint16 _amount) public onlyOwner{
        require(mintingEnabled == true, "Minting has been permanently disabled");
        require(_amount < 1+IPOPS(POPS_contract).MAX_POPS() - IPOPS(POPS_contract).totalSupply(), "Attempting to mint a number of tickets greater than the amount of redeemable POPS");
        for(uint256 i; i<_accounts.length; i++){
            _mint(_accounts[i], _amount);
        }
    }
    // [Tx][External] Burn tickets, only the sale contract can access this. Holders can get rid of tokens by sending them to blackhole address
    function burnTickets(address account, uint16 amount) external returns (bool){
        require(msg.sender == POPS_sale_contract, "Access denied");
        _burn(account, amount);
        return true;
    }
    // [Tx][Public][Owner] Disable minting forever
    function renounceMinting() public onlyOwner {
        require(mintingEnabled == true, "Minting has been already disabled");
        mintingEnabled=false;
        emit MintingDisabled();
    }
}