// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Timers.sol";
import "./Whitelist.sol";
import "./MintingRandomizer.sol";

contract POPSsale is Ownable, Pausable, Whitelist, MintingRandomizer{

    mapping(uint256 => bool) minted;
    uint256 requestId;
    /*
    function drawMint() public{
        _setMinterById(_nextMinterId(), msg.sender);
        //minterRequestBlock[nextMinterId] = block.number;
        _shuffle();
        _setNextMinterId(); // Increase next minter ID by 1 (or go back to 0 is max has been reached)
        if(!minted[requestId-2]){
            //_mint(_minterById(_nextMinterId()), _useMintId(0, MAX_POPS) );
        }
        requestId+=1;
    }
    */


}