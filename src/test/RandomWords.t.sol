// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../RandomWords.sol";

interface CheatCodes {
    // Sets the *next* call's msg.sender to be the input address
    function prank(address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address, address) external;

    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;
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
        cheats.prank(USER);
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

    function testMintMAX_HOLD() public {
        uint16 MAX_TX = 50;
        cheats.startPrank(USER);
        rwContract.mint(MAX_TX);
        rwContract.mint(MAX_TX);
        rwContract.mint(MAX_TX);
        rwContract.mint(MAX_TX);
        rwContract.mint(MAX_TX);
        rwContract.mint(MAX_TX);
        rwContract.mint(33);
        cheats.stopPrank();
    }

    function testFailMintMAX_HOLD() public {
        uint16 MAX_TX = 50;
        cheats.startPrank(USER);
        rwContract.mint(MAX_TX);
        rwContract.mint(MAX_TX);
        rwContract.mint(MAX_TX);
        rwContract.mint(MAX_TX);
        rwContract.mint(MAX_TX);
        rwContract.mint(MAX_TX);
        rwContract.mint(MAX_TX);
        cheats.stopPrank();
    }
}
