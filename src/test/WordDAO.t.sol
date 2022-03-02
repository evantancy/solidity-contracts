// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "../RandomWords.sol";
import "../dao/WordDAO.sol";

interface VM {
    function prank(address) external;

    function prank(address, address) external;

    function startPrank(address) external;

    function stopPrank() external;

    function deal(address, uint256) external;
}

contract WordDAOTest is DSTest {
    VM constant vm =
        VM(address(bytes20(uint160(uint256(keccak256(("hevm cheat code")))))));
    WordDAO dao;
    RandomWords token;

    address public alice = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address public bob = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address public charlie = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address public david = 0x5C2C4de7C947dEE988A4471D0270ECbaee92a961;

    function setUp() public {
        token = new RandomWords();
        dao = new WordDAO();
    }

    function test_InitialSupply() public {
        assertEq(token.currentSupply(), 0);
    }

    function testFail_NoAddress() public {
        assertEq(dao.getVotingPower(alice), 0);
    }

    function test_VotingPower_AfterMint() public {
        dao.setTokenAddress(address(token));

        vm.prank(alice);
        token.mint(1);
        assertEq(dao.getVotingPower(alice), token.balanceOf(alice));
        assertEq(dao.getVotingPower(bob), 0);
    }

    function test_VotingPower_AfterTransfer() public {
        dao.setTokenAddress(address(token));

        vm.startPrank(alice);
        token.mint(1);
        assertEq(dao.getVotingPower(alice), 1);

        uint256 id = 0;
        token.approve(bob, id);
        token.safeTransferFrom(alice, bob, id);
        assertEq(token.balanceOf(bob), 1);
        assertEq(dao.getVotingPower(bob), token.balanceOf(bob));
    }
}
