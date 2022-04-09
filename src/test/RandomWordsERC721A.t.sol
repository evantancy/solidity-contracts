// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../RandomWordsERC721A.sol";

interface VM {
    function prank(address) external;

    function startPrank(address) external;

    function stopPrank() external;
}

contract RandomWordsERC721ATest is DSTest {
    RandomWordsERC721A rwContract;
    VM constant vm =
        VM(address(bytes20(uint160(uint256(keccak256(("hevm cheat code")))))));
    address who = 0x5C2C4de7C947dEE988A4471D0270ECbaee92a961;
    uint256 max_tx;

    function setUp() public {
        rwContract = new RandomWordsERC721A();
        max_tx = rwContract.MAX_TX();
        vm.startPrank(who);
    }

    function test_Mint_1() public {
        rwContract.mint(1);
        assertEq(rwContract.balanceOf(who), 1);
    }

    function test_Mint_5() public {
        rwContract.mint(5);
        assertEq(rwContract.balanceOf(who), 5);
    }

    function testFail_Mint_MaxTx() public {
        rwContract.mint(max_tx + 1);
    }
}
