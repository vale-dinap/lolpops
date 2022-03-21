// SPDX-License-Identifier: MIT

// Base contract for random mint functionalities

pragma solidity ^0.8.0;

contract RandomizeMinting{

    // VARIABLES
    uint8 private rollId;                                                                          // Adds entropy by keeping track of the current dice roll
    uint16 private nextMintableId=10;                                                              // Value that will replace the just-minted ID in the mintableId array
    uint16[] private mintableIds = [0,1,2,3,4,5,6,7,8,9];                                          // Initialize the array containing the currently mintable ids, this is randomized and updated at each mint


    // FUNCTIONS

    // [Tx][Internal] Fetch a token ID from the "mintableIds" array and replace it with next available
    function _useIdForMint(uint array_pos, uint16 max_supply) internal returns(uint16 usedId){
        usedId = mintableIds[array_pos];
        if(nextMintableId < max_supply){
            mintableIds[array_pos] = nextMintableId;
            nextMintableId++;
        }
        else{                                                                                      // Once max supply ceiling is reached, remove the item instead of replacing it
            mintableIds[array_pos] = mintableIds[mintableIds.length-1];
            mintableIds.pop();
        }
    }

    // [Tx][Internal] Pseudo-random function - no risk of exploit thanks to delayed revealing, yet making it hard to guess
    function _shuffle() internal returns(bool success) {
        for (uint16 i = 0; i < mintableIds.length; i++) {
            uint256 n = i + uint256(keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit + 
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                    block.number
                ))) % (mintableIds.length - i);
            uint16 temp = mintableIds[n];
            mintableIds[n] = mintableIds[i];
            mintableIds[i] = temp;
        }
        unchecked {rollId++;}                                                                      // Increase the roll ID to make sure that no shuffle gives the same result as the previous
        success=true;
    }

}