// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @title Roles for access control
/// @author nat_nave
/// @dev Access control mechanisms
/// @dev ceo should only have access to role appointments, no access to funds, no access to mint/drop/reveal functionality
/// @dev cfo no access to role appointments, only access to funds, no access to mint/drop/reveal functionality
/// @dev cfo no access to role appointments, no access to funds, only access to mint/drop/reveal functionality

contract Roles {
    /*///////////////////////////////////////////////////////////////
                                STATE VARS
    ///////////////////////////////////////////////////////////////*/

    address public ceo;
    address public cfo;
    address public cto;

    mapping(address => bool) internal admins;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    constructor() {
        ceo = msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    modifier onlyCEO() {
        require(msg.sender == ceo, "Caller is not CEO");
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfo, "Caller is not CFO");
        _;
    }

    modifier onlyCTO() {
        require(msg.sender == cto, "Caller is not CTO");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Caller is not admin");
        _;
    }
    modifier onlyNonAdmin() {
        require(!admins[msg.sender], "Caller is admin ");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                LOGIC
    ///////////////////////////////////////////////////////////////*/

    function setCTO(address _address) external onlyCEO {
        require(ceo != _address, "CEO cannot be CTO");
        require(cfo != _address, "CFO cannot be CTO");
        cto = _address;
    }

    function setCFO(address _address) external onlyCEO {
        require(ceo != _address, "CEO cannot be CFO");
        require(cto != _address, "CTO cannot be CFO");
        cfo = _address;
    }

    function setCEO(address _address) external onlyCEO {
        require(cfo != _address, "CFO cannot be CEO");
        require(cto != _address, "CTO cannot be CEO");
        ceo = _address;
    }

    function addAdmin(address _address) external onlyCEO {
        admins[_address] = true;
    }

    function removeAdmin(address _address) external onlyCEO {
        admins[_address] = false;
    }
}
