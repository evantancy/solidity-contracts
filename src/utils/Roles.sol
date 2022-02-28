// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Roles {
    mapping(address => bool) admins;

    constructor() {
        admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Roles: only admins can call");
        _;
    }
    modifier onlyNonAdmin() {
        require(admins[msg.sender] == false, "Roles: only non-admins can call");
        _;
    }

    function addAdmin(address _address) external onlyAdmin {
        admins[_address] = true;
    }

    function removeAdmin(address _address) external onlyAdmin {
        admins[_address] = false;
    }
}
