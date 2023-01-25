// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "solmate/tokens/ERC721.sol";

contract NotComplaintNFT is ERC721 {
    constructor() ERC721("MockNFTNoComplaint", "MNFT") {}

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }
}
