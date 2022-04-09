// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "base64-sol/base64.sol";
import "./utils/Strings.sol";

contract RandomWordsERC721 is ERC721 {
    using Strings8 for uint8;
    using Strings16 for uint16;

    uint256 public MAX_SUPPLY = 6666;
    uint256 public MAX_HOLD = 333;
    uint256 public MAX_TX = 50;
    uint256 private _currentIndex = 0;

    mapping(uint256 => Words) words;

    /// @dev store only trait index
    struct Words {
        uint8 first;
        uint8 second;
        uint8 third;
        uint8 bgColor;
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

    constructor() ERC721("Random Words", "RW") {}

    function mint(uint256 _quantity) public {
        require(_quantity <= MAX_TX, "Mint: quantity above MAX_TX");
        require(
            _currentIndex + _quantity + 1 <= MAX_SUPPLY,
            "Mint: quantity exceeds MAX_SUPPLY"
        );
        require(
            (balanceOf(msg.sender)) + _quantity <= MAX_HOLD,
            "Mint: Each holder can only hold 333"
        );

        uint256 startTokenId = _currentIndex;

        /// @dev store data on-chain
        for (uint256 i = 0; i < _quantity; ++i) {
            uint256 tokenId = startTokenId + i;
            _safeMint(msg.sender, tokenId);
            uint8[4] memory tokenData = _createRandom(tokenId);

            words[tokenId] = Words(
                tokenData[0],
                tokenData[1],
                tokenData[2],
                tokenData[3]
            );
        }
        if (_quantity > 0) _currentIndex += _quantity;
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
