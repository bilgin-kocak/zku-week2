//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {PoseidonT3} from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root
    uint256[] public hashedLeafs;
    uint256 public n = 3;

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        addInitialLeafs();
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        hashedLeafs[index] = hashedLeaf;
        root = updateMerkleTree();
        index = index + 1;
    }

    function updateMerkleTree() internal returns (uint256) {
        uint256 numHashs = 2**n - 1;

        if (index % 2 == 0) {
            hashes[index / 2] = PoseidonT3.poseidon(
                [hashedLeafs[2 * index], hashedLeafs[2 * index + 1]]
            );
        } else {
            hashes[index / 2] = PoseidonT3.poseidon(
                [hashedLeafs[2 * index - 2], hashedLeafs[2 * index - 1]]
            );
        }

        uint256 prev_layer = 0;
        uint256 prev_prev_layer = 0;
        for (uint256 i = 1; i < n; i++) {
            index = index / 2;
            prev_layer = prev_layer + numHashs - (numHashs >> 1);
            numHashs = numHashs >> 1;
            if (index % 2 == 0) {
                hashes[prev_layer + index / 2] = PoseidonT3.poseidon(
                    [
                        hashes[prev_prev_layer + 2 * index],
                        hashes[prev_prev_layer + 2 * index + 1]
                    ]
                );
            } else {
                hashes[prev_layer + index / 2] = PoseidonT3.poseidon(
                    [
                        hashes[prev_prev_layer + 2 * index - 2],
                        hashes[prev_prev_layer + 2 * index - 1]
                    ]
                );
            }
            prev_prev_layer = prev_layer;
        }

        return hashes[hashes.length - 1];
    }

    function addInitialLeafs() internal {
        for (uint256 i = index; i < 2**n; i++) {
            hashedLeafs.push(0);
        }

        uint256 numLeafHashers = 2**(n - 1);
        uint256 numIntermediateHashers = numLeafHashers - 1;
        for (uint256 i = index; i < numLeafHashers; i++) {
            hashes.push(
                PoseidonT3.poseidon(
                    [hashedLeafs[2 * i], hashedLeafs[2 * i + 1]]
                )
            );
        }

        uint256 k = 0;
        for (
            uint256 i = numLeafHashers;
            i < numLeafHashers + numIntermediateHashers;
            i++
        ) {
            hashes.push(
                PoseidonT3.poseidon([hashes[2 * k], hashes[2 * k + 1]])
            );
            k++;
        }
    }

    function verify(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool) {
        // [assignment] verify an inclusion proof and check that the proof root matches current root

        return super.verifyProof(a, b, c, input);
    }
}
