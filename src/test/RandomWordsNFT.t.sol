// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../utils/People.sol";
import {RandomWordsNFT} from "../RandomWordsNFT.sol";
import {Merkle} from "murky/Merkle.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RandomWordsNFTTest is Test, People {
    RandomWordsNFT nft;
    Merkle tree;
    address[] whitelisted = [
        0x92668e1E6Bbf1e7681A178FCcC144B99298bBA6a,
        0xCd64F8daDe506A89f617B7056e4539996e74983f,
        0x7E91f48Cb65642d55dc2e8cF2B21be3b50a7Ba9f,
        0x49B5AF99714EEdF8B6CA10e7d31Dc2c712f2d23d
    ];
    bytes32[] data;

    function setUp() public {
        // set alice to be contract deployer/owner
        vm.prank(alice);
        nft = new RandomWordsNFT();
        tree = new Merkle();
        data = new bytes32[](whitelisted.length);
        for (uint256 i = 0; i<data.length; ++i) {
            data[i] = keccak256(abi.encodePacked(whitelisted[i]));
        }
    }

    function testMerkleVerify() public {
        // Get Root, Proof, and Verify
        bytes32 root = tree.getRoot(data);
        // will get proof for second node
        bytes32[] memory proof = tree.getProof(data, 1);
        bytes32 leaf = data[1];
        bool verified = tree.verifyProof(root, proof, leaf);
        bool ozVerified = MerkleProof.verify(proof, root, leaf);
        assertTrue(verified);
        assertTrue(verified == ozVerified);
    }

    function testMintWhiteList() public {

        vm.prank(alice);
        nft.togglePresale();

        address user = whitelisted[0];
        bytes32[] memory proof = tree.getProof(data, 0);
        bytes32 root = tree.getRoot(data);
        emit log_string("Merkle root: ");
        emit log_bytes32(root);
        vm.prank(user);
        nft.mintPresale(1, proof);
    }

    function testFailNotWhitelist(address _user) public {
        vm.prank(alice);
        nft.togglePresale();
        // set to some arbitrary index, 0, when user is not in whitelist
        bytes32[] memory proof = tree.getProof(data, 0);
        vm.prank(_user);
        nft.mintPresale(1, proof);
    }
}
