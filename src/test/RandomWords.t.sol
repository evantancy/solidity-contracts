// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../RandomWords.sol";

interface CheatCodes {
    function prank(address) external;
}

contract RandomWordsTest is DSTest {
    RandomWords rwContract;
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    address public USER = 0x5C2C4de7C947dEE988A4471D0270ECbaee92a961;

    function setUp() public {
        rwContract = new RandomWords();
    }

    function testInitialSupply() public {
        assertEq(rwContract.getCurrentSupply(), 0);
    }

    function testFailMint0() public {
        rwContract.mint(0);
    }

    function testMint1() public {
        cheats.prank(USER);
        rwContract.mint(1);
    }

    function testMintMAX_TX() public {
        cheats.prank(USER);
        rwContract.mint(50);
    }

    function testFailMintMAX_TX() public {
        cheats.prank(USER);
        rwContract.mint(51);
    }
}

