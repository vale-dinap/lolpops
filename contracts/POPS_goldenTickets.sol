// SPDX-License-Identifier: MIT

/*
This token represents the golden tickets that can be used to redeem LOLPOPS NFTs for free. 
When a golden ticket is used, 1 token unit is burnt.
*/

///// TO DO: Complete this after the sale contract is ready
/////// 48h validity (counting from sale start)
///// Golden ticket token - reserves 1 token per address, expires after 2 days - CAN be transferred

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Timers.sol";

interface IPOPS{
    function MAX_POPS() view external returns(uint256);
    function totalSupply() view external returns(uint256);
}

interface IPOPSsale{
    function saleStart() view external returns (bool); /////// PLACEHOLDER!!!!! 
}

contract POPSgoldenTickets is ERC20, Ownable, Pausable {

    // EVENTS

    event Minted(address indexed, uint16);
    event Burned(address indexed, uint16);
    event MintingRenounced();


    // CONTRACT VARIABLES

    address immutable public POPS_contract;
    address immutable public POPS_sale_contract;
    bool mintingEnabled;
    uint256 immutable public validity;
    

    // CONSTRUCTOR

    constructor(string memory name, string memory symbol, address _POPS_sale_contract, address _POPS_contract) ERC20(name, symbol) {
        POPS_sale_contract = _POPS_sale_contract;
        POPS_contract = _POPS_contract;
        mintingEnabled = true;
        validity = 2; // Days - TO DO: double check required validity
    }


    // MODIFIERS

    modifier onlyPOPSsaleContract(){ //TO DO: Not used so far, consider removing
        require(msg.sender == POPS_sale_contract, "Access denied");
        _;
    }

    modifier ifMintingEnabled(){
        require(mintingEnabled == true, "Minting has been permanently disabled");
        _;
    }

    modifier duringValidity(){ // TO DO: UPDATE THIS WITH PROPER LOGICS
        require(block.timestamp < validity, "Tickets are expired");
        _;
    }


    // FUNCTIONS

    // Overriding the decimals function - no decimals are needed
    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function availablePOPS() view internal returns(uint256 POPSavailable){ ///// IF I IMPLEMENT A SIMILAR FUNCTION IN THE SALE CONTRACT, I CAN FETCH THE DATA FROM THERE AND AVOID IMPORTING THE POPS CONTRACT IN THIS CONTRACT
        POPSavailable = IPOPS(POPS_contract).MAX_POPS() - IPOPS(POPS_contract).totalSupply();
    }

    function mintTickets(address recipient, uint16 amount) public onlyOwner whenNotPaused ifMintingEnabled duringValidity returns (bool){
        require(amount <= availablePOPS(), "Attempting to mint a number of tickets greater than the amount of redeemable POPS");
        _mint(recipient, amount);
        emit Minted(recipient, amount);
        return true;
    }

    function burnTickets(address account, uint16 amount) external whenNotPaused returns (bool){
        require(account == msg.sender || msg.sender == POPS_sale_contract, "Access denied");
        _burn(account, amount);
        emit Burned(account, amount);
        return true;
    }

    function renounceMinting() public onlyOwner whenNotPaused ifMintingEnabled {
        mintingEnabled=false;
        emit MintingRenounced();
    }

    // TO DO - check of this is actually needed or if the burn fuction is enough
    // Override transferFrom function to allow POPS sale contract to use the tickets without approval
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        super._transfer(sender, recipient, amount);

        uint256 currentAllowance = super.allowance(sender, super._msgSender());
        require(currentAllowance >= amount || super._msgSender() == POPS_sale_contract, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

}