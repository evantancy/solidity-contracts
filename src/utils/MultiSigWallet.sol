// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Roles.sol";

contract MultiSigWallet {
    mapping(address => bool) owners;
    uint256 private nextRequestId;
    uint256 public confirmationsRequired;

    struct Request {
        address to;
        bool executed;
        uint16 numberOfConfirmations;
        uint256 value;
        bytes data;
    }

    mapping(uint256 => Request) requests;
    // Mapping from requestId -> address -> bool
    mapping(uint256 => mapping(address => bool)) public requestConfirmed;

    receive() external payable {}

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        require(owners[msg.sender] == true, "Only owner allowed");
        _;
    }

    modifier requestExists(uint256 _requestId) {
        require(_requestId <= nextRequestId - 1, "Request doesn't exist");
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

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/
    event RequestSubmitted(uint256 indexed requestId);
    event SignRequest(uint256 indexed requestId);
    event RevokeSignature(uint256 indexed requestId);

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    constructor(address[] memory _owners, uint256 _numConfirmations) {
        require(_owners.length > 0, "Must specify owners");
        require(
            _numConfirmations <= _owners.length,
            "Max confirmations exceeded"
        );
        confirmationsRequired = _numConfirmations;
        for (uint8 i = 0; i < _owners.length; ++i) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid address");
            // require(owners[owner] == false, "Duplicates not allowed");

            owners[owner] = true;
        }
    }

    function addRequest(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) public onlyOwner {
        requests[nextRequestId] = Request(_to, false, 0, _value, _data);
        emit RequestSubmitted(nextRequestId);
        nextRequestId++;
    }

    function _confirm(uint256 _id, bool _favor)
        private
        onlyOwner
        requestExists(_id)
        notExecuted(_id)
    {
        if (_favor) {
            requests[_id].numberOfConfirmations++;
            requestConfirmed[_id][msg.sender] = true;
        } else {
            require(requestConfirmed[_id][msg.sender], "Nothing to revoke");
            requests[_id].numberOfConfirmations--;
            requestConfirmed[_id][msg.sender] = false;
        }
    }

    function confirm(uint256 _id) public notConfirmed(_id) {
        _confirm(_id, true);
        emit SignRequest(_id);
    }

    function revokeConfirmation(uint256 _id) public {
        _confirm(_id, false);
        emit RevokeSignature(_id);
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
        require(req.executed == false, "Request already executed");
        req.executed = true;
        (bool success, ) = req.to.call{value: req.value}(req.data);
        require(success, "Request failed");
    }
}
