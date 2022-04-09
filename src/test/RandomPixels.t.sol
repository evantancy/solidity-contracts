// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../RandomPixels.sol";

interface VM {
    // Sets the *next* call's msg.sender to be the input address
    function prank(address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address) external;

    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;
}

contract RandomPixelsTest is DSTest {
    RandomPixels rp;
    VM cheats = VM(HEVM_ADDRESS);
    address public USER = 0x5C2C4de7C947dEE988A4471D0270ECbaee92a961;
    uint16 max_tx;

    function setUp() public {
        rp = new RandomPixels();
        max_tx = rp.MAX_TX();
    }

    function testInitialSupply() public {
        assertEq(rp.currentSupply(), 0);
    }

    function testFailMint0() public {
        cheats.prank(USER);
        rp.mint(0);
    }

    function testMint1() public {
        cheats.prank(USER);
        rp.mint(1);
        assertEq(rp.currentSupply(), 1);
        assertEq(rp.balanceOf(USER), 1);
        cheats.prank(USER);
        emit log_string(rp.tokenURI(0));
    }
}
