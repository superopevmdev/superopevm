// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VRFConsumerBase as VRFConsumerBase} from "@superopevm/contracts/vrf/VRFConsumerBase.sol";
import {IERC721 as IERC721} from "@superopevm/contracts/token/ERC721/IERC721.sol";
import {Strings as Strings} from "@superopevm/contracts/utils/Strings.sol";

/**
 * @title VRFNFTMint
 * @dev NFT minting with random attributes using VRF
 */
contract VRFNFTMint is VRFConsumerBase {
    using Strings for uint256;
    
    // NFT contract
    IERC721 public nftContract;
    
    // Mint requests
    struct MintRequest {
        address requester;
        uint256 tokenId;
        bool fulfilled;
    }
    
    mapping(uint256 => MintRequest) public mintRequests;
    
    // Events
    event MintRequested(uint256 indexed requestId, address indexed requester);
    event MintFulfilled(uint256 indexed requestId, uint256 indexed tokenId);
    
    constructor(
        address coordinator,
        bytes32 keyHash,
        uint64 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        address nftAddress
    ) VRFConsumerBase(
        coordinator,
        keyHash,
        subId,
        requestConfirmations,
        callbackGasLimit,
        1 // Single random word
    ) {
        nftContract = IERC721(nftAddress);
    }
    
    /**
     * @dev Request mint with random attributes
     */
    function requestMint() external returns (uint256) {
        uint256 requestId = super.requestRandomWords();
        mintRequests[requestId] = MintRequest({
            requester: msg.sender,
            tokenId: 0,
            fulfilled: false
        });
        
        emit MintRequested(requestId, msg.sender);
        return requestId;
    }
    
    /**
     * @dev Handle random words fulfillment
     */
    function _fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        require(randomWords.length == 1, "VRFNFTMint: invalid word count");
        
        MintRequest storage request = mintRequests[requestId];
        require(!request.fulfilled, "VRFNFTMint: already fulfilled");
        
        // Generate token ID based on random number
        uint256 tokenId = uint256(keccak256(abi.encodePacked(randomWords[0], requestId)));
        
        // Mint NFT
        nftContract.mint(request.requester, tokenId);
        
        // Update request
        request.tokenId = tokenId;
        request.fulfilled = true;
        
        emit MintFulfilled(requestId, tokenId);
    }
    
    /**
     * @dev Get mint request details
     */
    function getMintRequest(uint256 requestId)
        external
        view
        returns (address requester, uint256 tokenId, bool fulfilled)
    {
        MintRequest storage request = mintRequests[requestId];
        return (request.requester, request.tokenId, request.fulfilled);
    }
    
    /**
     * @dev Generate token URI with random attributes
     */
    function generateTokenURI(uint256 randomNumber) public pure returns (string memory) {
        // Example: Generate random attributes
        string memory rarity = _getRarity(randomNumber % 100);
        string memory color = _getColor((randomNumber >> 8) % 10);
        string memory power = ((randomNumber >> 16) % 1000).toString();
        
        return string(
            abi.encodePacked(
                '{"name": "Random NFT #',
                randomNumber.toString(),
                '", "description": "A randomly generated NFT", "attributes": [{"trait_type": "Rarity", "value": "',
                rarity,
                '"}, {"trait_type": "Color", "value": "',
                color,
                '"}, {"trait_type": "Power", "value": ',
                power,
                '}]}'
            )
        );
    }
    
    /**
     * @dev Get rarity based on random number
     */
    function _getRarity(uint256 randomNumber) internal pure returns (string memory) {
        if (randomNumber < 5) return "Legendary";
        if (randomNumber < 20) return "Epic";
        if (randomNumber < 50) return "Rare";
        return "Common";
    }
    
    /**
     * @dev Get color based on random number
     */
    function _getColor(uint256 randomNumber) internal pure returns (string memory) {
        string[10] memory colors = [
            "Red", "Blue", "Green", "Yellow", "Purple",
            "Orange", "Pink", "Black", "White", "Gray"
        ];
        return colors[randomNumber];
    }
}
