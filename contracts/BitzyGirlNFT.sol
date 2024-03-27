// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

contract BitzyGirlNFT is Initializable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIds;
    mapping(bytes32 => string) private _collectionURIPrefixes;
    string private _defaultURIPrefix;

    // Define struct for Collection
    struct Collection {
        uint256 weight;
        bool exists;
    }

    // Store collections and their weights
    mapping(bytes32 => Collection) public collections;
    bytes32[] public collectionNames;
    uint64 public MAX_MINT;
    uint256 public constant totalWeight = 10000;


    function initialize() initializer public {
        __ERC721_init("Bitzy Girls", "BGF");
        __Ownable_init();
    }

    function setURIPrefix(string memory baseURI) public onlyOwner {
        _defaultURIPrefix = baseURI;
    }

    function setCollections(bytes32[] memory collectionName, uint256[] memory weight, string memory baseURI, uint64 maxMint) external onlyOwner {
        require(collectionName.length == weight.length, "Mismatch length");
        collectionNames = new bytes32[](collectionName.length);
        collectionNames = collectionName;
        uint256 totalW = 0;
        for (uint i = 0; i < collectionName.length; i++) {
            collections[collectionName[i]] = Collection(weight[i], true);
            _collectionURIPrefixes[collectionName[i]] = baseURI;
            totalW = totalW + weight[i];
        }
        require(totalW == totalWeight, "Total weight must be 10000");
        MAX_MINT = maxMint;
    }

    function updateCollectionWeight(bytes32 name, uint256 newWeight) external onlyOwner {
        require(collections[name].exists, "Collection does not exist");
        collections[name].weight = newWeight;
    }

    function updateMaxMint(uint64 maxMint) external onlyOwner {
        require(maxMint > 0, "Maximum limit must > 0");
        MAX_MINT = maxMint;
    }

    function batchMint(address to, uint8 times) external {
        for (uint i = 0; i < times; i++) {
            mint(to);
        }
    }

    function mint(address to) public returns (uint256) {
        require(collectionNames.length > 0, "No collections available");
        require(MAX_MINT > 0, "Exceed mint limit");

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenIds.current())));

        uint256 randomValue = randomNumber % totalWeight;
        bytes32 chosenCollectionName;
        uint256 cumulativeWeight = 0;

        for (uint256 i = 0; i < collectionNames.length; i++) {
            cumulativeWeight = cumulativeWeight.add(collections[collectionNames[i]].weight);

            if (randomValue < cumulativeWeight) {
                chosenCollectionName = collectionNames[i];
                break;
            }
        }

        uint256 newId = _tokenIds.current();
        _tokenIds.increment();
        _mint(to, newId);
        MAX_MINT = MAX_MINT - 1;

        string memory collectionURIPrefix = _collectionURIPrefixes[chosenCollectionName];
        string memory prefix = bytes(collectionURIPrefix).length != 0 ? collectionURIPrefix : _defaultURIPrefix;
        _setTokenURI(newId, string(abi.encodePacked(prefix, "/", bytes32ToString(chosenCollectionName), ".json")));
        
        return newId;
    }

    function burn(uint256 _tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "caller is not owner nor approved");
        _burn(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function bytes32ToString(bytes32 data) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            bytesString[i] = data[i];
        }
        return string(bytesString);
    }
}
