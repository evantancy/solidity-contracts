// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../RandomWordsV2.sol";

interface CheatCodes {
    // Sets the *next* call's msg.sender to be the input address
    function prank(address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address) external;

    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;
}

contract RandomWordsV2Test is DSTest {
    RandomWordsV2 rwContract;
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    address public USER = 0x5C2C4de7C947dEE988A4471D0270ECbaee92a961;
    uint16 max_tx;

    function setUp() public {
        rwContract = new RandomWordsV2();
        max_tx = rwContract.MAX_TX();
    }

    function testInitialSupply() public {
        assertEq(rwContract.currentSupply(), 0);
    }

    function testFailMint0() public {
        cheats.prank(USER);
        rwContract.mint(0);
    }

    function testMint1() public {
        cheats.prank(USER);
        rwContract.mint(1);
        assertEq(rwContract.currentSupply(), 1);
        assertEq(rwContract.balanceOf(USER), 1);
    }

    function testMintMAX_TX() public {
        cheats.prank(USER);
        rwContract.mint(max_tx);
        assertEq(rwContract.currentSupply(), max_tx);
    }

    function testFailMintMAX_TX() public {
        cheats.prank(USER);
        rwContract.mint(max_tx + 1);
    }

    function testMintMAX_HOLD() public {
        uint16 quantity = rwContract.MAX_HOLD();
        cheats.startPrank(USER);
        while (quantity > 0) {
            if (quantity >= max_tx) {
                rwContract.mint(max_tx);
                quantity -= max_tx;
            } else {
                rwContract.mint(quantity);
                quantity -= quantity;
            }
        }
        cheats.stopPrank();
        assertEq(rwContract.currentSupply(), rwContract.MAX_HOLD());
    }

    function testFailMintMAX_HOLD() public {
        cheats.startPrank(USER);
        for (uint8 i = 0; i < 8; ++i) {
            rwContract.mint(max_tx);
        }
        cheats.stopPrank();
    }
}
