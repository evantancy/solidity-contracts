// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../utils/Ownership.sol";
import "../utils/Roles.sol";

interface RandomWordsInterface {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract WordDAO is Ownership, Roles {
    address tokenAddress;
    RandomWordsInterface rw;

    constructor() {}

    modifier onlyHolder(address _address) {
        require(rw.balanceOf(_address) > 0);
        _;
    }

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
        bytes32 indexed pollId,
        address indexed contributor,
        bytes32 contentId,
        bytes32 categoryId,
        bytes32 indexed parentId
    );

    event VoteCast(
        address indexed voter,
        bytes32 indexed pollId,
        bool sentiment
    );

    mapping(bytes32 => string) contentRegistry;
    mapping(bytes32 => Poll) pollRegistry;
    mapping(address => mapping(bytes32 => bool)) voterRegistry;
    mapping(bytes32 => string) categoryRegistry;

    function getVotingPower(address _address) public view returns (uint256) {
        return rw.balanceOf(_address);
    }

    function setTokenAddress(address _address) public onlyOwner onlyAdmin {
        tokenAddress = _address;
        rw = RandomWordsInterface(tokenAddress);
    }

    function createPoll(
        string calldata _contentUri,
        bytes32 _categoryId,
        bytes32 _parentId
    ) external {
        bytes32 contentId = keccak256(abi.encode(bytes(_contentUri)));
        bytes32 pollId = keccak256(
            abi.encodePacked(msg.sender, contentId, _parentId)
        );

        contentRegistry[contentId] = _contentUri;

        pollRegistry[pollId].contributor = msg.sender;
        pollRegistry[pollId].deadline = block.number + 10 days;
        pollRegistry[pollId].contentId = contentId;
        pollRegistry[pollId].categoryId = _categoryId;
        pollRegistry[pollId].parentId = _parentId;

        emit ContentAdded(contentId, _contentUri);
        emit PollStarted(pollId, msg.sender, contentId, _categoryId, _parentId);
    }

    function _vote(bytes32 _pollId, bool favor) internal onlyNonAdmin {
        address voter = msg.sender;
        // bytes32 category = pollRegistry[_pollId].categoryId;
        // address contributor = pollRegistry[_pollId].contributor;

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

        if (favor) {
            pollRegistry[_pollId].positive += 1;
        } else {
            pollRegistry[_pollId].negative += 1;
        }

        voterRegistry[voter][_pollId] = true;

        emit VoteCast(voter, _pollId, favor);
    }

    function voteUp(bytes32 _pollId) external {
        _vote(_pollId, true);
    }

    function voteDown(bytes32 _pollId) external {
        _vote(_pollId, false);
    }

    function addCategory(string calldata _category) external {
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

    function getPoll(bytes32 _pollId) public view returns (Poll memory) {
        return pollRegistry[_pollId];
    }
}
