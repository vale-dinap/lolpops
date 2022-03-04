// SPDX-License-Identifier: MIT

// Base contract for random draw functionalities

pragma solidity ^0.8.0;

////// TODO: delete/hide test functions, create a function to return the currently assigned ID and minting time for current address

contract RandomizeMinting{

    // VARIABLES
    uint8 private nextMinterId = 0;                                                                // Each of the last 3 minters is assigned an id from 0 to 2 (used cyclically)
    uint8 private rollId;                                                                          // Adds entropy by keeping track of the current dice roll
    uint16 private nextMintableId=10;                                                              // Value that will replace the just-minted ID in the mintableId array
    uint16[] private mintableIds = [0,1,2,3,4,5,6,7,8,9];                                          // Initialize the array containing the final metadata ids, this is randomized at each draw
    //mapping(uint256 => uint256) internal minterRequestBlock;                                     // Keeps track of when a minter has requested a draw // TODO: consider moving to derived contract
    mapping(uint8 => address) private minter;                                                      // The draw is randomized by using the last 3 minter addresses as source of entropy
    uint16[] private mintBuffer = [];
    mapping(uint16 => address) assignedMinter;


    // FUNCTIONS - Main logics

    // [Tx][Internal] Fetch a metadata ID from the array and replace it with next available
    function _useMintId(uint array_pos, uint16 max_supply) internal returns(uint16 usedId){
        usedId = mintableIds[array_pos];
        if(nextMintableId < max_supply){
            mintableIds[array_pos] = nextMintableId;
            nextMintableId++;
        }
        else{
            mintableIds[array_pos] = mintableIds[mintableIds.length-1];
            mintableIds.pop();
        }
    }

    // [Tx][Internal] Random function using the addresses of the last few minters as source of entropy
    function _shuffle() internal returns(bool success) {
        for (uint16 i = 0; i < mintableIds.length; i++) {
            uint256 n = i + uint256(keccak256(
                abi.encodePacked(   rollId,
                                    minter[0], minter[1], minter[2],                               // Additional entropy from addresses of the last 3 minters
                                    block.timestamp
                ))) % (mintableIds.length - i);
            uint16 temp = mintableIds[n];
            mintableIds[n] = mintableIds[i];
            mintableIds[i] = temp;
        }
        unchecked {rollId++;}                                                                      // Increase the roll ID to make sure that no draw gives the same result as the previous
        success=true;
    }

    //function assign()

    //function drawMint


    // FUNCTIONS - Getters and setters

    // [View][Internal] Get minter address by ID (among the last 3)
    function _minterById(uint8 id) view internal returns(address){
        return minter[id];
    }

    // [Tx][Internal] Set address of new minter ID
    function _setMinterById(uint8 id, address newAddress) internal{
        minter[id] = newAddress;
    }

    // [View][Internal] Get next minter ID (cyclical 0 to 2)
    function _nextMinterId() view internal returns(uint8){
        return nextMinterId;
    }

    // [Tx][Internal] Increase next minter ID by 1 (wrapped 0 to 2)
    function _setNextMinterId() internal{
        nextMinterId = (nextMinterId==2 ? 0 : nextMinterId+1);
    }

    function getMintableIds() view public returns(uint16[] memory){ /////////////////////////////////// TEST ONLY- DELETE IT ///////////////////////////////////////
        return(mintableIds);
    }

}