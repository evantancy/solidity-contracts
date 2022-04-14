// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../utils/People.sol";
import "../RandomWordsERC721.sol";

interface VM {
    function prank(address) external;

    function startPrank(address) external;

    function stopPrank() external;
}

contract RandomWordsERC721Test is DSTest {
    RandomWordsERC721 rwContract;
    VM constant vm = VM(HEVM_ADDRESS);
    address who = 0x5C2C4de7C947dEE988A4471D0270ECbaee92a961;
    uint256 max_tx;

    function setUp() public {
        rwContract = new RandomWordsERC721();
        vm.startPrank(who);
    }

    function testMint1() public {
        rwContract.mint(1);
    }

    function testMint5() public {
        rwContract.mint(5);
    }

    function testFailMintMaxTx() public {
        max_tx = rwContract.MAX_TX();
        rwContract.mint(max_tx + 1);
    }
}
