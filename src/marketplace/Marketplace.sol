// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../utils/Roles.sol";
import "../utils/ReentrancyGuard.sol";
import "../utils/Ownership.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract Marketplace is Ownership, ReentrancyGuard {
    /// @dev interface ID for ERC721 and ERC1155 contracts
    bytes4 private constant ERC721_INTERFACEID = 0x80ac58cd;
    bytes4 private constant ERC1155_INTERFACEID = 0xd9b67a26;

    /// @dev marketplace fee calculation, 250 / 10000 = 2.5%
    /// @dev additional sig fig allows 4 decimal places
    uint256 public marketplaceFee = 250;
    uint256 public constant FEE_DENOMINATOR = 10000;
    address public feeReceiver;

    enum TokenApprovalStatus {
        NOT_APPROVED,
        ERC721_APPROVED,
        ERC1155_APPROVED
    }

    struct Listing {
        uint128 pricePerToken;
        uint64 quantity;
        uint64 deadline;
    }

    event ListingCreated(
        address indexed seller,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint128 pricePerToken,
        uint64 quantity,
        uint64 time
    );

    /// @dev whether specific tokens are approved for trading on marketplace
    mapping(address => TokenApprovalStatus) public tokenApprovals;
    /// @dev address -> tokenId -> seller -> Listing
    mapping(address => mapping(uint256 => mapping(address => Listing)))
        public listings;

    constructor(address receiver_) {
        feeReceiver = receiver_;
    }

    /// @dev Approve a certain token for trading on the marketplace
    /// @param _tokenAddress contract address of token
    /// @param _status token approval status, 0 == NOT APPROVED, 1 = ERC721 APPROVED, 2 == ERC1155 APPROVED
    function setTokenApproval(
        address _tokenAddress,
        TokenApprovalStatus _status
    ) public {
        if (_status == TokenApprovalStatus.ERC721_APPROVED) {
            require(
                IERC721(_tokenAddress).supportsInterface(ERC721_INTERFACEID),
                "Contract is not ERC721"
            );
        } else if (_status == TokenApprovalStatus.ERC1155_APPROVED) {
            require(
                IERC1155(_tokenAddress).supportsInterface(ERC1155_INTERFACEID),
                "Contract is not ERC1155"
            );
        }
        tokenApprovals[_tokenAddress] = _status;
    }

    function createListing(
        address _tokenAddress,
        uint256 _tokenId,
        uint128 _pricePerToken,
        uint64 _quantity,
        uint64 _time
    ) public noReentrant {
        TokenApprovalStatus status = tokenApprovals[_tokenAddress];
        require(
            status != TokenApprovalStatus.NOT_APPROVED,
            "Token not approved for trading"
        );
        require(_pricePerToken > 0, "Price must be positive");
        require(_time >= 1 days, "Time must at least 1 day");

        /* ###################### ERC721 LOGIC ############################## */
        if (status == TokenApprovalStatus.ERC721_APPROVED) {
            IERC721 token = IERC721(_tokenAddress);
            require(
                token.ownerOf(_tokenId) == msg.sender,
                "Only token owner can list"
            );
            require(_quantity == 1, "Quantity must be 1");
            require(token.isApprovedForAll(msg.sender, address(this)));
        }
        /* ###################### ERC1155 LOGIC ############################# */
        else if (status == TokenApprovalStatus.ERC1155_APPROVED) {
            IERC1155 token = IERC1155(_tokenAddress);
            require(_quantity > 0, "Nothing to list");
            require(
                _quantity <= token.balanceOf(msg.sender, _tokenId),
                "Not enough tokens to list"
            );
            require(token.isApprovedForAll(msg.sender, address(this)));
        }

        // create listing
        listings[_tokenAddress][_tokenId][msg.sender] = Listing(
            _pricePerToken,
            _quantity,
            _time
        );
    }

    function buyListing(
        address _tokenAddress,
        uint256 _tokenId,
        address _seller,
        uint64 _quantity
    ) public payable noReentrant {
        Listing memory item = listings[_tokenAddress][_tokenId][_seller];
        require(msg.sender != _seller, "Cannot buy your own listing");
        require(_quantity > 0, "Insufficient quantity");
        require(block.timestamp <= item.deadline, "Listing expired");
        require(item.quantity > 0, "No listings available");
        require(_quantity <= item.quantity, "Exceeded maximum quantity");
        require(item.pricePerToken > 0, "Price must be positive");

        TokenApprovalStatus status = tokenApprovals[_tokenAddress];
        require(
            status != TokenApprovalStatus.NOT_APPROVED,
            "Token not approved for trading"
        );

        // handle token transfer
        /* ###################### ERC721 LOGIC ############################## */
        if (status == TokenApprovalStatus.ERC721_APPROVED) {
            IERC721 token = IERC721(_tokenAddress);
            require(_quantity == 1, "Quantity must be 1");
            token.safeTransferFrom(_seller, msg.sender, _tokenId);
        }
        /* ###################### ERC1155 LOGIC ############################# */
        else if (status == TokenApprovalStatus.ERC1155_APPROVED) {
            IERC1155 token = IERC1155(_tokenAddress);
            token.safeTransferFrom(
                _seller,
                msg.sender,
                _tokenId,
                uint256(_quantity),
                ""
            );
        }

        // handle payments
        uint256 value = item.pricePerToken * _quantity;
        uint256 marketplaceCut = (value * marketplaceFee) / FEE_DENOMINATOR;
        uint256 sellerCut = value - marketplaceCut;
        payable(_seller).transfer(sellerCut);
        payable(feeReceiver).transfer(marketplaceCut);

        // handle listing
        if (_quantity == item.quantity) {
            delete listings[_tokenAddress][_tokenId][_seller];
        } else {
            listings[_tokenAddress][_tokenId][_seller].quantity -= _quantity;
        }
    }

    function getListing(
        address _tokenAddress,
        uint256 _tokenId,
        address _seller
    ) public view returns (Listing memory) {
        return listings[_tokenAddress][_tokenId][_seller];
    }
}
