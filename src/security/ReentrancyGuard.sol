// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract ReentrancyGuard {
    bool internal locked = false;

    constructor() {}

    modifier noReentrant() {
        require(!locked, "ReentrancyGuard: no re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}
