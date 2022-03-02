// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Roles {
    /// @dev ceo only has access to role appointments, no access to funds, no access to mint/drop/reveal functionality
    address private ceo;
    /// @dev cfo no access to role appointments, only access to funds, no access to mint/drop/reveal functionality
    address private cfo;
    /// @dev cfo no access to role appointments, no access to funds, only access to mint/drop/reveal functionality
    address private cto;

    mapping(address => bool) admins;

    constructor() {
        ceo = msg.sender;
    }

    modifier onlyCEO() {
        require(msg.sender == ceo);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfo);
        _;
    }

    modifier onlyCTO() {
        require(msg.sender == cto);
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Roles: only admins can call");
        _;
    }
    modifier onlyNonAdmin() {
        require(admins[msg.sender] == false, "Roles: only non-admins can call");
        _;
    }

    function setCTO(address _address) external onlyCEO {
        cto = _address;
    }

    function setCFO(address _address) external onlyCEO {
        cfo = _address;
    }

    function addAdmin(address _address) external onlyCEO {
        admins[_address] = true;
    }

    function removeAdmin(address _address) external onlyCEO {
        admins[_address] = false;
    }
}
