// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../utils/Ownership.sol";
import "../utils/Roles.sol";
import "../utils/ReentrancyGuard.sol";

interface RandomWordsInterface {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract WordDAO is Ownership, Roles, ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////
                                STATE VARS
    ///////////////////////////////////////////////////////////////*/

    /// @dev deployed token address to query balances
    address tokenAddress;
    RandomWordsInterface rw;
    uint32 private nextPollId = 0;
    uint256 private votingPeriod = 10 days;

    constructor() {}

    event ContentAdded(bytes32 indexed contentId, string contentUri);
    event CategoryAdded(bytes32 indexed categoryId, string category);

    struct Poll {
        address contributor;
        uint32 positive;
        uint32 negative;
        uint256 deadline;
        bytes32 contentId;
        bytes32 categoryId;
        bytes32 parentId;
    }

    event PollStarted(
        uint32 indexed pollId,
        address indexed contributor,
        bytes32 contentId,
        bytes32 categoryId,
        bytes32 indexed parentId
    );

    event VoteCast(
        address indexed voter,
        uint32 indexed pollId,
        bool sentiment
    );

    mapping(bytes32 => string) contentRegistry;
    mapping(uint32 => Poll) pollRegistry;
    mapping(address => mapping(uint32 => bool)) voterRegistry;
    mapping(bytes32 => string) categoryRegistry;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    modifier onlyHolder() {
        require(rw.balanceOf(msg.sender) > 0);
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                LOGIC
    ///////////////////////////////////////////////////////////////*/

    /// @dev Query token hodlers
    function getVotingPower(address _address) private view returns (uint256) {
        return rw.balanceOf(_address) > 0 ? 1 : 0;
    }

    /// @dev Use method instead of constructor parameter
    function setTokenAddress(address _address) external onlyCTO {
        tokenAddress = _address;
        rw = RandomWordsInterface(tokenAddress);
    }

    function createPoll(
        string calldata _contentUri,
        bytes32 _categoryId,
        bytes32 _parentId
    ) external {
        bytes32 contentId = keccak256(abi.encode(bytes(_contentUri)));
        uint32 pollId = nextPollId;

        contentRegistry[contentId] = _contentUri;

        pollRegistry[pollId].contributor = msg.sender;
        pollRegistry[pollId].deadline = block.number + votingPeriod;
        pollRegistry[pollId].contentId = contentId;
        pollRegistry[pollId].categoryId = _categoryId;
        pollRegistry[pollId].parentId = _parentId;

        emit ContentAdded(contentId, _contentUri);
        emit PollStarted(pollId, msg.sender, contentId, _categoryId, _parentId);
        nextPollId++;
    }

    function _vote(uint32 _pollId, bool favor)
        internal
        onlyNonUpper
        onlyHolder
    {
        address voter = msg.sender;

        require(
            pollRegistry[_pollId].contributor != voter,
            "Vote: unable to vote on your own polls."
        );
        require(
            voterRegistry[voter][_pollId] == false,
            "Vote: already voted on this poll."
        );
        require(
            block.number <= pollRegistry[_pollId].deadline,
            "Vote: deadline has passed"
        );

        /// @dev 1 address == 1 vote
        uint32 votingPower = uint32(getVotingPower(voter));
        if (favor) {
            pollRegistry[_pollId].positive += votingPower;
        } else {
            pollRegistry[_pollId].negative += votingPower;
        }

        voterRegistry[voter][_pollId] = true;

        emit VoteCast(voter, _pollId, favor);
    }

    function voteUp(uint32 _pollId) external onlyHolder {
        _vote(_pollId, true);
    }

    function voteDown(uint32 _pollId) external onlyHolder {
        _vote(_pollId, false);
    }

    function addCategory(string calldata _category) external onlyAdmin {
        bytes32 _categoryId = keccak256(
            abi.encode(msg.sender, _category, block.timestamp)
        );
        categoryRegistry[_categoryId] = _category;

        emit CategoryAdded(_categoryId, _category);
    }

    function getContent(bytes32 _contentId)
        public
        view
        returns (string memory)
    {
        return contentRegistry[_contentId];
    }

    function getCategory(bytes32 _categoryId)
        public
        view
        returns (string memory)
    {
        return categoryRegistry[_categoryId];
    }

    function getPoll(uint32 _pollId) public view returns (Poll memory) {
        return pollRegistry[_pollId];
    }

    function withdraw(uint256 _amount) external onlyCFO noReentrant {
        require(address(this).balance > 0);
        (bool status, ) = msg.sender.call{value: _amount}("");
        require(status, "Failed to send Ether");
    }
}
