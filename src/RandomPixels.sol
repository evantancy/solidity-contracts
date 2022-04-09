// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "base64/base64.sol";
import "./utils/Strings.sol";

contract RandomPixels is ERC721 {
    using Strings8 for uint8;
    using Strings16 for uint16;

    uint16 public MAX_SUPPLY = 6666;
    uint8 public MAX_HOLD = 100;
    uint8 public MAX_TX = 50;
    uint16 private nextTokenId = 0;
    uint16 public currentSupply = 0;

    uint8[3][] private pixelColors = [
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

    constructor() ERC721("Random Pixels", "RP") {}

    function mint(uint16 _quantity) public {
        require(_quantity > 0, "Mint: quantity must be > 0");
        require(_quantity <= MAX_TX, "Mint: quantity above MAX_TX");
        require(
            nextTokenId + _quantity + 1 <= MAX_SUPPLY,
            "Mint: quantity exceeds MAX_SUPPLY"
        );
        require(
            uint8(balanceOf(msg.sender)) + _quantity <= MAX_HOLD,
            "Mint: Each holder can only hold 333"
        );
        for (uint16 i = 0; i < _quantity; ++i) {
            _safeMint(msg.sender, nextTokenId);
            nextTokenId++;
            currentSupply++;
        }
    }

    function _createRandomSvg(uint16 _tokenId)
        private
        view
        returns (string memory)
    {
        uint256 pseudoRandom = uint256(
            keccak256(abi.encodePacked(_tokenId, msg.sender, block.timestamp))
        );

        string memory svg;

        uint8[3] memory color;

        for (uint8 i = 0; i < 3; ++i) {
            for (uint8 j = 0; j < 3; ++j) {
                color = pixelColors[pseudoRandom % pixelColors.length];
                svg = string(
                    abi.encodePacked(
                        svg,
                        '<rect width="1" height="1" x="',
                        i.toString(),
                        '" y="',
                        j.toString(),
                        '" fill="rgba(',
                        color[0].toString(),
                        ",",
                        color[1].toString(),
                        ",",
                        color[2].toString(),
                        ',1.0)"/>'
                    )
                );
                pseudoRandom >>= 1;
            }
        }

        svg = string(
            abi.encodePacked(
                '<svg id="random-pixels" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 9 9">',
                svg,
                "<style>#random-pixels{shape-rendering:crispedges;}</style></svg>"
            )
        );

        return svg;
    }

    function _createFullMetadata(uint16 _tokenId)
        private
        view
        returns (string memory)
    {
        string memory svg = _createRandomSvg(_tokenId);
        string memory metadata;

        metadata = string(
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

        return metadata;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));

        return _createFullMetadata(uint16(_tokenId));
    }
}
