// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../RandomWords.sol";

interface VM {
    function prank(address) external;

    function startPrank(address) external;

    function stopPrank() external;
}

contract RandomWordsTest is DSTest {
    RandomWords rwContract;
    VM constant vm =
        VM(address(bytes20(uint160(uint256(keccak256(("hevm cheat code")))))));
    address who = 0x5C2C4de7C947dEE988A4471D0270ECbaee92a961;
    uint256 max_tx;

    function setUp() public {
        rwContract = new RandomWords();
        max_tx = rwContract.MAX_TX();
        vm.startPrank(who);
    }

    function testInitialSupply() public {
        assertEq(rwContract.totalSupply(), 0);
    }

    function testFailMint0() public {
        rwContract.mint(0);
    }

    function testMint1() public {
        rwContract.mint(1);
        assertEq(rwContract.totalSupply(), 1);
        assertEq(rwContract.balanceOf(who), 1);
    }

    function testMintMAX_TX() public {
        rwContract.mint(max_tx);
        assertEq(rwContract.totalSupply(), max_tx);
    }

    function testFailMintMAX_TX() public {
        rwContract.mint(max_tx + 1);
    }

    function testMintMAX_HOLD() public {
        uint256 quantity = rwContract.MAX_HOLD();
        while (quantity > 0) {
            if (quantity >= max_tx) {
                rwContract.mint(max_tx);
                quantity -= max_tx;
            } else {
                rwContract.mint(quantity);
                quantity -= quantity;
            }
        }
        assertEq(rwContract.totalSupply(), rwContract.MAX_HOLD());
    }

    function testFailMintMAX_HOLD() public {
        for (uint256 i = 0; i < 8; ++i) {
            rwContract.mint(max_tx);
        }
    }
}
