// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "chiru-labs/ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "base64-sol/base64.sol";
import "./utils/Strings.sol";
import "./utils/Roles.sol";

contract RandomWordsNFT is ERC721A {
    using Strings8 for uint8;
    using Strings16 for uint16;

    uint256 public MAX_SUPPLY = 6666;
    uint256 public MAX_TX = 2;

    bytes32 public merkleRoot = 0x9768aa6e0c67338e4ad28454c6843cfcd2ec70932069fd97f3da210ed16e46ad;
    address public owner;
    bool public saleActive;
    bool public presaleActive;

    mapping(address => bool) whitelistClaimed;
    mapping(uint256 => Words) words;

    /// @dev store only trait index
    struct Words {
        uint8 first;
        uint8 second;
        uint8 third;
        uint8 bgColor;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    string[] private firstWords = [
        "Illustrious",
        "Aberrant",
        "Abashed",
        "Elderly",
        "Grubby",
        "Messy",
        "Physical",
        "Mellow",
        "One",
        "Slippery"
    ];

    string[] private secondWords = [
        "Fierce",
        "Steep",
        "Harsh",
        "Macho",
        "Enthusiastic",
        "Quaint",
        "Determined",
        "Colossal",
        "Juicy",
        "Abnormal"
    ];

    string[] private thirdWords = [
        "Economist",
        "Player",
        "Customer",
        "Elephant",
        "Champion",
        "Psychedelic",
        "Woman",
        "Man",
        "Child",
        "Hedgehog"
    ];

    uint8[3][] private bgColors = [
        [40, 116, 166],
        [31, 97, 141],
        [108, 52, 131],
        [118, 68, 138],
        [176, 58, 46],
        [146, 43, 33],
        [185, 119, 14],
        [183, 149, 11],
        [35, 155, 86],
        [30, 132, 73],
        [17, 122, 101],
        [20, 143, 119],
        [40, 55, 71],
        [97, 106, 107],
        [113, 125, 126],
        [144, 148, 151],
        [179, 182, 183],
        [160, 64, 0],
        [33, 47, 61]
    ];

    constructor() ERC721A("Random Words", "RW") {
        owner = msg.sender;
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function mintPresale(uint256 _quantity, bytes32[] calldata _merkleProof)
        public
    {
        require(presaleActive, "Presale not active");
        require(!whitelistClaimed[msg.sender], "Already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );
        whitelistClaimed[msg.sender] = true;
        mint(_quantity);
    }

    function mintPublic(uint256 _quantity) public {
        require(saleActive, "Sale not active");
        mint(_quantity);
    }

    function mint(uint256 _quantity) private {
        require(_quantity <= MAX_TX, "Mint: quantity above MAX_TX");
        require(
            _currentIndex + _quantity + 1 <= MAX_SUPPLY,
            "Mint: quantity exceeds MAX_SUPPLY"
        );
        uint256 tokenId = _currentIndex;
        _safeMint(msg.sender, _quantity);

        /// @dev store data on-chain
        for (uint256 i = 0; i < _quantity; ++i) {
            uint8[4] memory tokenData = _createRandom(tokenId + i);

            words[tokenId + i] = Words(
                tokenData[0],
                tokenData[1],
                tokenData[2],
                tokenData[3]
            );
        }
    }

    function _createRandom(uint256 _tokenId)
        private
        view
        returns (uint8[4] memory)
    {
        uint256 pseudoRandom = uint256(
            keccak256(abi.encodePacked(_tokenId, msg.sender, block.timestamp))
        );

        uint8[4] memory randomIndices;
        randomIndices[0] = uint8((pseudoRandom >> 1) % firstWords.length);
        randomIndices[1] = uint8((pseudoRandom >> 2) % secondWords.length);
        randomIndices[2] = uint8((pseudoRandom >> 3) % thirdWords.length);
        randomIndices[3] = uint8((pseudoRandom >> 4) % bgColors.length);

        return randomIndices;
    }

    function _createSvg(Words memory _words)
        private
        view
        returns (string memory)
    {
        uint8[3] memory bgColor = bgColors[_words.bgColor];
        /// @dev split SVG generation into 2 to avoid 'stack too deep' error
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="rgba(',
                bgColor[0].toString(),
                ",",
                bgColor[1].toString(),
                ",",
                bgColor[2].toString(),
                ',1.0)"/>'
            )
        );

        svg = string(
            abi.encodePacked(
                svg,
                '<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">',
                firstWords[_words.first],
                " ",
                secondWords[_words.second],
                " ",
                thirdWords[_words.third],
                "</text></svg>"
            )
        );

        return svg;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));

        Words memory word = words[_tokenId];
        string memory svg = _createSvg(word);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Random Words #',
                                    Strings.toString(_tokenId),
                                    '", "image": "data:image/svg+xml;base64,',
                                    Base64.encode(bytes(svg)),
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }
}
