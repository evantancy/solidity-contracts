// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "ds-test/test.sol";
import "../utils/MultiSigWallet.sol";

interface VM {
    function prank(address) external;

    function prank(address, address) external;

    function startPrank(address) external;

    function stopPrank() external;

    function deal(address, uint256) external;
}

contract MultiSigWalletTest is DSTest {
    MultiSigWallet msw;
    address[] addyArr;
    address public alice = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address public bob = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address public charlie = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address public david = 0x5C2C4de7C947dEE988A4471D0270ECbaee92a961;

    VM constant vm =
        VM(address(bytes20(uint160(uint256(keccak256(("hevm cheat code")))))));

    function setUp() public {
        addyArr.push(alice);
        addyArr.push(bob);
        addyArr.push(charlie);
        addyArr.push(david);
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
