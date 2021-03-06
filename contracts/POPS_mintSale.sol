// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Whitelist.sol";
import "./RandomizeMinting.sol";

interface POPS_nft{
    function mint(address to, uint256 tokenId) external;
    function totalSupply() view external returns(uint256);
}

interface GoldenTicket{
    function balanceOf(address account) external view returns(uint256);
    function burnTickets(address account, uint16 amount) external returns(bool);
    function totalSupply() view external returns(uint256);
}

contract POPSsale is Ownable, Pausable, ReentrancyGuard, Whitelist, RandomizeMinting{


    ///// CONTRACT VARIABLES /////

    uint8 public whitelist_validity = 4;                                                                  // In days
    uint8 public goldenTickets_validity = 2;                                                              // In days
    uint16 priceStep = 1800;                                                                              // Number of sales to increase the price
    uint256 public saleStart;                                                                             // Unix timestamp
    uint256 public saleEnd;                                                                               // Unix timestamp
    uint256[6] priceCurve = [0.08 ether, 0.083 ether, 0.09 ether, 0.103 ether, 0.121 ether, 0.144 ether]; // Prices have been pre-calculated algorithmically and hardcoded to reduce runtime gas cost
    address public immutable POPS_address;                                                                // POPS ERC721 contract
    address public POPS_goldenTicket;                                                                     // Golden Ticket ERC20 contract
    address payable POPS_teamWallet;                                                                      // Team wallet contract

    mapping(uint256 => bool) minted;
    uint256 requestId;


    ///// CONSTRUCTOR /////

    constructor(address _POPS, address payable _teamWallet) Ownable() {
        POPS_address = _POPS;
        POPS_teamWallet = _teamWallet;
    }


    ///// MODIFIERS /////

    // Only during sale
    modifier onlyDuringSale{
        require(block.timestamp > saleStart, "Sale hasn't started yet");
        require(block.timestamp < saleEnd, "Sale is over");
        _;
    }
    // Use whitelist (during validity)
    modifier useWhitelist (address account, uint8 amount, bytes32[] calldata merkleProof){
        if(block.timestamp < (saleStart + (1 days * whitelist_validity) )){
            require(amount < 1 + getWhitelistAllowance(account, merkleProof) + nonReserved(), "Request exceeds allowance (whitelist + non_reserved)");
            _useWhitelistAllowance(account, amount, merkleProof);
        }
        _;
    }


    ///// FUNCTIONS - BEFORE SALE /////

    // [Tx][Public][Owner] Initialize whitelist
    function whitelist_initialize(uint16 _whitelist_length, bytes32 _whitelist_merkleRoot) public onlyOwner returns(bool success){
        super._whitelistInitialize(_whitelist_length, _whitelist_merkleRoot);
        success = true;
    }

    // [Tx][Public][Owner] Start the sale
    function startSale(uint256 _duration_days, address _goldenTicketContract) public onlyOwner returns(bool success){
        require(saleStart != 0, "Sale has already started");
        saleStart = block.timestamp;
        saleEnd = saleStart + (_duration_days * 1 days);
        POPS_goldenTicket = _goldenTicketContract;
        success = true;
    }


    ///// FUNCTIONS - DURING SALE /////

    // [View][Public] Get current price
    function currentPrice() view public returns(uint256 price){
        price = priceCurve[ POPS_nft(POPS_address).totalSupply() / priceStep ];
    }

    // [View][Public] Get available POPS
    function availableToMint() view public returns(uint256 available){
        available= 10000 - POPS_nft(POPS_address).totalSupply();
    }

    // [View][Private] Get amount of non reserved POPS (WL + GT)
    function nonReserved() view private returns(uint256 amount){
        amount = availableToMint();
        if(duringGTvalidity()) {amount -= GoldenTicket(POPS_goldenTicket).totalSupply();}
        if(block.timestamp < (saleStart + (1 days * whitelist_validity))){ amount  -= getWhitelistTotalAllowance();}
    }

    // [View][Public] Check if during golden tickets validity
    function duringGTvalidity() view public returns(bool result){
        result = (block.timestamp < (saleStart + (1 days * goldenTickets_validity) ) );
    }

    // [Tx][Private] Redeem golden tickets
    function useGoldenTickets(address buyer, uint8 requested) private returns(uint8 credits){
        if ( duringGTvalidity() ){                                                                        // If during validity,
            uint8 available = uint8(GoldenTicket(POPS_goldenTicket).balanceOf(buyer));                    // check buyer's amount of tickets
            credits = (available < requested ? available : requested);                                    // If requested more than available, use all available
            if(credits>0) GoldenTicket(POPS_goldenTicket).burnTickets(buyer, credits);                    // Burn used tickets
        }
        else{credits = 0;}                                                                                // If GT are expired, do nothing and return zero credits
    }

    // [Tx][Public] Main buy/mint function
    function buy(uint8 _amount, bool _useGT, bytes32[] calldata _whitelist_merkleProof) payable public onlyDuringSale whenNotPaused nonReentrant useWhitelist(msg.sender, _amount, _whitelist_merkleProof){
        require(_amount > 0 && _amount < 11, "You can mint 1 to 10 POPS at once");
        require(_amount < 1+availableToMint(), "Mint would exceed max supply");
        // Calculate price (use GT if any available)
        uint8 credits;                                                                                    // Initialize variable holding the amount of spent golden tickets
        if (_useGT) credits = useGoldenTickets(msg.sender, _amount);                                      // Spend golden tickets (if during validity)
        uint256 salePrice = currentPrice()*(_amount - credits);                                           // Calculate sale price
        // Forward payment to the team wallet
        require(msg.value >= salePrice, "Please make sure to send enough eth");
        (bool paid, ) = POPS_teamWallet.call{value: address(this).balance}("");                           // Forward ether to the teamWallet address. Using contract balance instead of msg.value just in case some funds have gotten stuck in the contract due to unforseen circumstances
        // Actual mint
        require(paid);
        _shuffle();
        for(uint8 n=0; n<_amount; n++){
            POPS_nft(POPS_address).mint(msg.sender, _useIdForMint(n, 10000) );
        }
    }

    // [Tx][Public][Owner] Pause the contract
    function pauseContract() public onlyOwner {
        _pause();
    }

    // [Tx][Public][Owner] Unpause the contract
    function unpauseContract() public onlyOwner {
        _unpause();
    }
}