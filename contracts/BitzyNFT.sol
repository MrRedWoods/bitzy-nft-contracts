// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BitzyNFT is ERC721, Ownable {
    using Counters for Counters.Counter;

    // Generating the tokenId of new NFT minted
    Counters.Counter private _tokenIds;

    constructor() public 
        ERC721("Bitzy NFT", "BITZY") 
    {}

    function setURIPrefix(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    /**
     * @dev Function to mint tokens.
     */
    function mint(address to) external returns (uint256) {
        uint256 newId = _tokenIds.current();
        _tokenIds.increment();
        _mint(to, newId);
        uint256 newIdMod = newId % 4;
        _setTokenURI(newId, string(abi.encodePacked(uint2str(newIdMod), ".json")));
        return newId;
    }

    /**
     * @dev Burns a specific ERC721 token.
     * @param _tokenId uint256 id of the ERC721 token to be burned.
     */
    function burn(uint256 _tokenId) external  {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "caller is not owner nor approved"
        );
        _burn(_tokenId);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}