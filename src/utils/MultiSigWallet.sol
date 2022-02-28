// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Roles.sol";

contract MultiSigWallet {
    // event SubmitRequest(address caller, bytes32 requestId);
    // event SignRequest(address caller);
    // event RevokeSignature();

    mapping(address => bool) owners;
    uint256 lastRequestId = 0;
    uint256 public confirmationsRequired;

    struct Request {
        address to;
        bool executed;
        uint256 numberOfConfirmations;
        uint256 value;
        bytes data;
    }
    mapping(uint256 => Request) requests;
    // mapping from requestId -> address -> bool
    mapping(uint256 => mapping(address => bool)) public requestConfirmed;

    receive() external payable {}

    modifier onlyOwner() {
        require(owners[msg.sender] == true, "Only owner allowed");
        _;
    }

    modifier requestExists(uint256 _requestId) {
        require(_requestId <= lastRequestId - 1, "Request doesn't exist");
        _;
    }

    modifier notExecuted(uint256 _requestId) {
        require(!requests[_requestId].executed, "Request already executed");
        _;
    }
    modifier notConfirmed(uint256 _requestId) {
        require(
            !requestConfirmed[_requestId][msg.sender],
            "Request already confirmed by msg.sender"
        );
        _;
    }

    constructor(address[] memory _owners, uint256 _numConfirmations) {
        require(_owners.length > 0, "Must specify owners");
        require(
            _numConfirmations <= _owners.length,
            "Max confirmations exceeded"
        );
        confirmationsRequired = _numConfirmations;
        for (uint256 i = 0; i < _owners.length; ++i) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid address");
            require(owners[owner] == false, "Duplicates not allowed");

            owners[owner] = true;
        }
    }

    function addRequest(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) public onlyOwner {
        requests[lastRequestId] = Request(_to, false, 0, _value, _data);
        lastRequestId++;
    }

    function confirm(uint256 _id)
        public
        onlyOwner
        requestExists(_id)
        notExecuted(_id)
        notConfirmed(_id)
    {
        Request memory req = requests[_id];
        req.numberOfConfirmations++;
        requestConfirmed[_id][msg.sender] = true;
    }

    function execute(uint256 _id)
        public
        onlyOwner
        requestExists(_id)
        notExecuted(_id)
    {
        Request memory req = requests[_id];
        require(
            req.numberOfConfirmations >= confirmationsRequired,
            "Cannot execute request"
        );
        req.executed = true;
        (bool success, ) = req.to.call{value: req.value}(req.data);
        require(success, "Request failed");
    }
}
