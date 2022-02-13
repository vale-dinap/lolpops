// SPDX-License-Identifier: MIT

/*
This token represents the golden tickets that can be used to redeem LOLPOPS NFTs for free. 
When a golden ticket is used, 1 token unit is burnt.
*/

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";

interface POPSI{
    function MAX_POPS() view external returns(uint256);
}

contract POPSgoldenTickets is ERC20, Ownable, Pausable {

    // EVENTS

    event TicketsMinted(address indexed, uint16);
    event TicketsBurned(address indexed, uint16);
    event TicketMintingRenounced();


    // STATE VARIABLES

    address immutable public POPS_contract;
    address immutable public POPS_sale_contract;
    bool mintingEnabled;
    uint256 max_supply;


    // CONSTRUCTOR

    constructor(string memory name, string memory symbol, address _POPS_sale_contract, address _POPS_contract) ERC20(name, symbol) {
        POPS_sale_contract = _POPS_sale_contract;
        POPS_contract = _POPS_contract;
        mintingEnabled = true;
    }


    // MODIFIERS

    modifier onlyPOPSsaleContract(){
        require(msg.sender == POPS_sale_contract, "Access denied");
        _;
    }

    modifier ifMintingEnabled(){
        require(mintingEnabled == true, "Minting has been permanently disabled");
        _;
    }


    // FUNCTIONS

    // Overloading the decimals function - no decimals are needed
    function decimals() public pure override returns (uint8) {
        return 0;
    }

    /*
    function availablePOPS() view internal returns(uint256){ ///// IF I IMPLEMENT A SIMILAR FUNCTION IN THE SALE CONTRACT, I CAN FETCH THE DATA FROM THERE AND AVOID IMPORTING THE POPS CONTRACT IN THIS CONTRACT
        uint256 POPSmax = POPSI(POPS_contract).MAX_POPS();
        uint256 POPSsold = 1; ///// FUNCTION TO FETCH THE AMOUNT OF POPS BEEN SOLD - 1 is a temporary placeholder to prevent errors from the compiler
        uint256 POPSavailable; ///actual math: "max - sold;" - leaving this out to avoid compiler errors while I write the rest
        return POPSavailable;
    }

    function _mint(address account, uint256 amount) internal override {
        require(ERC20.totalSupply() + amount <= max_supply, "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function mintTickets(address recipient, uint16 amount) public onlyOwner whenNotPaused ifMintingEnabled returns (bool){
        require(amount <= availablePOPS(), "Attempting to mint a number of tickets greater than the amount of redeemable POPS");
        _mint(recipient, amount);
        emit TicketsMinted(recipient, amount);
        return true;
    }
    */

    function burnTickets(address account, uint16 amount) external onlyPOPSsaleContract whenNotPaused returns (bool){
        _burn(account, amount);
        emit TicketsBurned(account, amount);
        return true;
    }

    function renounceMinting() public onlyOwner whenNotPaused ifMintingEnabled {
        mintingEnabled=false;
        emit TicketMintingRenounced();
    }

}