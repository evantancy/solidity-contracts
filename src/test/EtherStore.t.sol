// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../utils/People.sol";
import "../security/EtherStore.sol";
import "../security/Attacker.sol";

interface VM {
    function prank(address) external;

    function prank(address, address) external;

    function startPrank(address) external;

    function stopPrank() external;

    function deal(address who, uint256 newBalance) external;
}

contract EtherStoreTest is DSTest, People {
    EtherStore es;
    Attacker att;

    VM constant vm = VM(HEVM_ADDRESS);

    function setUp() public {
        es = new EtherStore();
    }

    function testFailToReenter() public {
        address esAddr = address(es);
        vm.deal(alice, 50 ether);
        vm.prank(alice);
        es.deposit{value: 50 ether}();

        vm.deal(bob, 50 ether);
        vm.prank(bob);
        es.deposit{value: 50 ether}();

        att = new Attacker(esAddr);
        address attAddr = address(att);
        emit log_string("Before attack");
        emit log_named_uint("EtherStore: ", esAddr.balance);
        emit log_named_address("Address: ", esAddr);
        emit log_named_uint("Attacker: ", attAddr.balance);
        emit log_named_address("Address: ", attAddr);

        vm.deal(charlie, 1 ether);
        vm.prank(charlie);
        att.attack{value: 1 ether}();
        emit log_string("After attack");
        emit log_named_uint("EtherStore: ", esAddr.balance);
        emit log_named_address("Address: ", esAddr);
        emit log_named_uint("Attacker: ", attAddr.balance);
        emit log_named_address("Address: ", attAddr);
    }
}
