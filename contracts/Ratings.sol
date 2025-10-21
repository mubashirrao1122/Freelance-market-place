// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ratings {
    address public marketplace;
    address public owner;

    modifier onlyMarketplace() {
        require(msg.sender == marketplace, "Only Marketplace contract can call");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }
    struct Rating {
        uint8 score;
        string review;
        address reviewer;
        uint256 jobId;
    }

    mapping(address => Rating[]) public userRatings;

    event Rated(address indexed user, uint8 score, string review, address indexed reviewer, uint256 jobId);

    constructor() {
        owner = msg.sender;
    }

    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    function rateUser(address user, uint8 score, string memory review, uint256 jobId) external onlyMarketplace {
        require(score >= 1 && score <= 5, "Score must be 1-5");
        userRatings[user].push(Rating(score, review, tx.origin, jobId));
        emit Rated(user, score, review, tx.origin, jobId);
    }

    function getRatings(address user) external view returns (Rating[] memory) {
        return userRatings[user];
    }

    function getAverageRating(address user) external view returns (uint256) {
        Rating[] memory ratings = userRatings[user];
        if (ratings.length == 0) return 0;
        uint256 sum = 0;
        for (uint256 i = 0; i < ratings.length; i++) {
            sum += ratings[i].score;
        }
        return sum / ratings.length;
    }

    function getRatings(address user) external view returns (Rating[] memory) {
        return userRatings[user];
    }
}
