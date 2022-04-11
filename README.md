# solidity-contracts

## Randomwords ERC721 NFT Gas Comparison
For this comparison I wanted to why some ( [tweet 1](https://twitter.com/tom_hirst/status/1489320924134326275?s=20&t=N06F-yrCI8fubm_Ubkipyg), [tweet 2](https://twitter.com/shegenerates/status/1437773472285999105?s=20&t=N06F-yrCI8fubm_Ubkipyg) ) have been overriding ERC721's `tokenURI` function to view a token's metadata instead of using `setTokenUri` (from OpenZeppelin's ERC721UriStorage.sol) which I had been instructed to use in a tutorial. Turns out `setTokenUri` stores the whole Base64 encoded string for a token's metadata through a `mapping(uint256 => string)` which is an **extremely expensive** operation as seen below. It's much cheaper in gas fees to store integers representing indices in property arrays, store probably a bunch of uint8 or uint16 numbers in storage and override the `tokenURI` view function to view token metadata without costing gas.

<details>

  ![Screenshot from 2022-04-11 03-27-51](https://user-images.githubusercontent.com/36868915/162636353-9d60d3f7-54a2-490b-8466-299a4ad42d3b.png)
</details>
