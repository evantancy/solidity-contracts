// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "ds-test/test.sol";
import "../utils/People.sol";
import "../utils/MultiSigWallet.sol";

interface VM {
    function prank(address) external;

    function prank(address, address) external;

    function startPrank(address) external;

    function stopPrank() external;

    function deal(address, uint256) external;
}

contract MultiSigWalletTest is DSTest, People {
    MultiSigWallet msw;
    address[] addyArr;
    VM constant vm = VM(HEVM_ADDRESS);

    function setUp() public {
        addyArr = [alice, bob, charlie, david];
        msw = new MultiSigWallet(addyArr, 2);

        vm.deal(address(msw), 10 ether);
    }

    function testFailWithdraw() public {
        vm.startPrank(alice);
        msw.addRequest(alice, 10 ether, "");
        uint256 requestId = 0;
        msw.confirm(requestId);
        msw.execute(requestId);
    }

    function testWithdraw() public {
        vm.startPrank(alice);
        msw.addRequest(alice, 10 ether, "");
        uint256 requestId = 0;
        msw.confirm(requestId);
        vm.stopPrank();

        vm.prank(bob);
        msw.confirm(requestId);

        vm.prank(alice);
        msw.execute(requestId);
    }
}
