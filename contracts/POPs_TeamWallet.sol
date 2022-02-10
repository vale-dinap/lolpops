// SPDX-License-Identifier: MIT

// Each team member will receive an amount of tokens representing his/her shares
// On each NFT sale, earnings will be paid proportionally to the amount of share tokens held
// 100 shares (actually 10000 - with 2 decimal digits) equal to 100% of the revenues, 1 share equal to 1% and so on

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

interface POPSsharesI {
        function listShareholders() view external returns(address[] memory);
        function countShareholders() view external returns(uint256);
        function balanceOf(address _address) view external returns(uint256);
        function decimals() view external returns(uint8);
}

contract POPSwallet is Ownable, Pausable, ReentrancyGuard {

    event Received(address, uint);
    event Claimed(address indexed, uint);

    using SafeMath for uint256;

    address public immutable sharesTokenContract; // Address of the shares token contract
    mapping (address => uint256) dividends; // This stores the unclaimed dividends for each shareholder
    
    constructor(address _sharesToken) Ownable() Pausable() ReentrancyGuard() {
        sharesTokenContract = _sharesToken;
    }

    // Get the total unclaimed dividends (aka contract's balance)
    function totalUnclaimedDividends() view public returns(uint256){
        return address(this).balance;
    }

    // Get the unclaimed dividends of the given shareholder
    function unclaimedDividends(address shareholder) view public returns(uint256){
        return dividends[shareholder];
    }

    // Get current amount of shareholders
    function countShareholders() view internal returns(uint){
        return POPSsharesI(sharesTokenContract).countShareholders();
    }

    // Get full list of shareholders (addresses)
    function listShareholders() view public returns(address[] memory){
        return POPSsharesI(sharesTokenContract).listShareholders();
    }

    // Get amount of shares of the given shareholder
    function getShares(address _shareholder) view public returns(uint256){
        return POPSsharesI(sharesTokenContract).balanceOf(_shareholder);
    }

    // Calculate dividend proportional to shares
    function calculateDividend(address shareholder, uint256 value) view internal returns(uint256 dividend){
        dividend = value.mul(getShares(shareholder)).div(100 * 10 ** POPSsharesI(sharesTokenContract).decimals());
    }

    // Distribute dividends amongst the shareholders
    function distributeDividends(uint256 value) internal returns(bool){
        if(value>0){
            uint256 distributed;
            for(uint256 i=0; i<countShareholders(); i++){
                address shareholder = listShareholders()[i];
                uint256 dividend = calculateDividend(shareholder, value);
                dividends[shareholder] += dividend;
                distributed += dividend;
            }
            assert(distributed <= value);
            return true;
        }
        else{return false;}
    }

    // Process incoming payments
    function processPayment(uint256 value) internal nonReentrant returns(bool){
        require(value>0, "Attempting to pay zero eth");
        distributeDividends(value);
        return true;
    }

    // Fallback for incoming payments
    receive() external payable {
        processPayment(msg.value);
        emit Received(msg.sender, msg.value);
    }

    // Claim the accrued dividends
    function claimDividends() public whenNotPaused nonReentrant returns(bool){
        require(dividends[msg.sender]>0, "This address has no dividends to claim");
        uint256 value = dividends[msg.sender];
        dividends[msg.sender]=0;
        (bool sent, ) = msg.sender.call{value: value}("");
        emit Claimed(msg.sender, value);
        return sent;
    }

    // Pause the contract
    function pauseContract() public onlyOwner {
        _pause();
    }

    // Unpause the contract
    function unpauseContract() public onlyOwner {
        _unpause();
    }

}