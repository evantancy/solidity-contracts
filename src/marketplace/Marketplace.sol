// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../utils/Roles.sol";
import "../utils/ReentrancyGuard.sol";
import "../utils/Ownership.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract Marketplace is Ownership, ReentrancyGuard {
    using Counters for Counters.Counter;

    uint256 collectionIndex = 0;

    struct Listing {
        // more than enough
        address contractAddress;
        uint128 tokenId;
        uint128 price;
        uint256 deadline;
        address seller;
    }

    struct Stats {
        uint256 numListings;
        uint128 floor;
        uint128 volume;
        uint256 itemId;
    }

    /// @dev collection hash -> contract address -> items/stats
    mapping(bytes32 => Stats) collectionStats;
    mapping(bytes32 => mapping(uint256 => Listing)) private collectionListings;

    constructor() {}

    function _createHash(address _tokenContract)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_tokenContract));
    }

    function createListing(
        address _tokenContract,
        uint128 _tokenId,
        uint128 _price,
        uint256 time
    ) public noReentrant {
        require(_price > 0, "Price must be positive integer");
        require(
            IERC721(_tokenContract).ownerOf(_tokenId) == msg.sender,
            "Not token owner"
        );
        require(time >= 1 days, "Listing must be at least 1 day");

        /// @dev allow controller to match order
        // IERC721(_tokenContract).setApprovalForAll(address(this), true);
        IERC721(_tokenContract).approve(address(this), _tokenId);

        // create unique id for listing
        bytes32 id = _createHash(_tokenContract);

        Stats memory cStats = collectionStats[id];
        collectionListings[id][cStats.itemId] = Listing(
            _tokenContract,
            _tokenId,
            _price,
            block.timestamp + time,
            msg.sender
        );

        // update collection stats
        cStats.numListings++;
        if (cStats.floor == 0) {
            cStats.floor = _price;
        } else {
            if (_price < cStats.floor) cStats.floor = _price;
        }

        cStats.itemId++;
    }

    function buyListing(address _tokenContract, uint128 _itemId)
        public
        payable
        noReentrant
    {
        // create unique id for listing
        bytes32 id = _createHash(_tokenContract);
        Stats memory cStats = collectionStats[id];
        Listing memory item = collectionListings[id][_itemId];
        require(cStats.numListings > 0, "No listings available");
        require(block.timestamp <= item.deadline, "Listing inactive");
        require(msg.value == item.price, "Price not met");
        require(msg.sender != item.seller, "Wash trade with different address");

        // send $$ to seller
        payable(item.seller).transfer(msg.value);
        // transfer ownership
        IERC721(_tokenContract).safeTransferFrom(
            item.seller,
            msg.sender,
            uint256(item.tokenId)
        );

        // update stats
        cStats.numListings--;
        cStats.volume += item.price;

        // delete listing
        delete collectionListings[id][_itemId];
    }

    function fetchItems(address _tokenContract)
        public
        view
        returns (Listing[] memory)
    {
        bytes32 id = _createHash(_tokenContract);
        Stats memory cStats = collectionStats[id];
        require(cStats.numListings > 0, "No listings available");
        // assign maximum possible listings
        Listing[] memory activeListings = new Listing[](cStats.numListings);
        uint256 index = cStats.numListings;
        uint256 count = 0;
        while (index >= 0) {
            Listing memory listing = collectionListings[id][index];
            if (listing.price == 0) continue;
            activeListings[count] = listing;
            count++;
            index--;
        }
        return activeListings;
    }
}
