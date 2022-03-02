// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Ownership {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() internal view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) internal onlyOwner {
        _owner = newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner(), "Ownership: caller != owner");
        _;
    }
}
