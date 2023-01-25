// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "../../CidSubprotocolNFT.sol";

contract SubprotocolNFT is CidSubprotocolNFT {
    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function isActive(uint256 _nftID) public override returns (bool active) {
        return true;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }
}
