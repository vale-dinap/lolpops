// SPDX-License-Identifier: MIT

// Base contract for random draw functionalities

pragma solidity ^0.8.0;

////// TODO: delete/hide test functions, consider increasing buffer of  addresses, create a function to return the currently assigned ID and minting time for current address

contract MintingRandomizer{

    // VARIABLES
    uint64 private rollId;                                                                         // Adds entropy by keeping track of the current dice roll
    mapping(uint8 => address) private minter;                                                      // The draw is randomized by using the last 3 minter addresses as source of entropy
    uint8 private nextMinterId = 0;                                                                // Each of the last 3 minters is assigned an id from 0 to 2 (used cyclically)
    uint256[10] private mintableIds = [0,1,2,3,4,5,6,7,8,9];                                       // Initialize the array containing the final metadata ids, this is randomized at each draw
    uint256 private nextMintableId=10;                                                             // Value that will replace the just-minted ID in the mintableId array
    mapping(uint256 => uint256) internal minterRequestBlock;                                       // Keeps track of when a minter has requested a draw // TODO: consider moving to derived contract


    // FUNCTIONS - Main logics

    // Fetch a metadata ID from the array and replace it with next available
    function _useMintId(uint array_pos, uint256 max_supply) internal returns(uint256 usedId){
        usedId = mintableIds[array_pos];
        mintableIds[array_pos] = nextMintableId;
        nextMintableId = (nextMintableId >= max_supply ? max_supply : nextMintableId+1);
    }

    // Random function using the addresses of trhe last few minters as source of entropy
    function _shuffle() internal returns(bool success) {
        for (uint256 i = 0; i < mintableIds.length; i++) {
            uint256 n = i + uint256(keccak256(
                abi.encodePacked(   rollId,
                                    minter[0], minter[1], minter[2],                               // Additional entropy from addresses of the last 3 minters
                                    blockhash(block.number)
                ))) % (mintableIds.length - i);
            uint256 temp = mintableIds[n];
            mintableIds[n] = mintableIds[i];
            mintableIds[i] = temp;
        }
        rollId+=1;                                                                                 // Increase the roll ID to make sure that no draw gives the same result as the previous
        success=true;
    }


    // FUNCTIONS - Getters and setters

    // Get minter address by ID (among the last 3)
    function _minterById(uint8 id) view internal returns(address){
        return minter[id];
    }

    // Set address of new minter ID
    function _setMinterById(uint8 id, address newAddress) internal{
        minter[id] = newAddress;
    }

    // Get next minter ID (cyclical 0 to 2)
    function _nextMinterId() view internal returns(uint8){
        return nextMinterId;
    }

    // Increase next minter ID by 1 (wrapped 0 to 2)
    function _setNextMinterId() internal{
        nextMinterId = (nextMinterId==2 ? 0 : nextMinterId+1);
    }



    function getMintableIds() view public returns(uint256[10] memory){ //// TESTING ONLY - DELETE THIS AFTERWARDS
        return(mintableIds);
    }

}