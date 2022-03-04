// Generate merkle tree

const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

// Replace contents with address list
let whitelist = [
    "adress1",
    "adress2",
    "adress3",
    "..." 
];

const leafNodes = whitelist.map(addr => keccak256(addr));
const merkleTree = new MerkleTree( leafNodes, keccak256, {sortPairs: true});
const rootHash = merkleTree.getRoot();

console.log(leafNodes);
console.log(merkleTree);
console.log(rootHash);