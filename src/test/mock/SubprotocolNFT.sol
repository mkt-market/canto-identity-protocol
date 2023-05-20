// SPDX-License-Identifier: GPL-3.0-only
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

pragma solidity >=0.8.0;

contract SubprotocolNFT is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}

    mapping(uint256 => string) mockTokenURI;

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return mockTokenURI[id];
    }

    function setMockTokenURI(uint256 id, string memory uri) public {
        mockTokenURI[id] = uri;
    }
}
