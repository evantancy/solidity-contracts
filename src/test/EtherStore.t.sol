// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../security/EtherStore.sol";
import "../security/Attacker.sol";

interface CheatCodes {
    // Sets the *next* call's msg.sender to be the input address
    function prank(address) external;

    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address, address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address) external;

    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;

    // Sets an address' balance
    function deal(address who, uint256 newBalance) external;
}

contract EtherStoreTest is DSTest {
    EtherStore es;
    Attacker att;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    address public USER = 0x5C2C4de7C947dEE988A4471D0270ECbaee92a961;
    address public alice = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address public bob = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address public charlie = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;

    function setUp() public {
        es = new EtherStore();
    }

    function testFail_TryReentrancy() public {
        address esAddr = address(es);
        cheats.deal(alice, 50 ether);
        cheats.prank(alice);
        es.deposit{value: 50 ether}();

        cheats.deal(bob, 50 ether);
        cheats.prank(bob);
        es.deposit{value: 50 ether}();

        att = new Attacker(esAddr);
        address attAddr = address(att);
        emit log_string("Before attack");
        emit log_named_uint("EtherStore: ", esAddr.balance);
        emit log_named_address("Address: ", esAddr);
        emit log_named_uint("Attacker: ", attAddr.balance);
        emit log_named_address("Address: ", attAddr);

        cheats.deal(charlie, 1 ether);
        cheats.prank(charlie);
        att.attack{value: 1 ether}();
        emit log_string("After attack");
        emit log_named_uint("EtherStore: ", esAddr.balance);
        emit log_named_address("Address: ", esAddr);
        emit log_named_uint("Attacker: ", attAddr.balance);
        emit log_named_address("Address: ", attAddr);
    }
}
