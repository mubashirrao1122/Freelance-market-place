// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Ratings is Ownable, Pausable {
    address public marketplace;

    modifier onlyMarketplace() {
        require(msg.sender == marketplace, "Only Marketplace contract can call");
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

    /**
     * @notice Initializes the Ratings contract and sets the owner
     */
    /**
     * @notice Initializes the Ratings contract
     */
    constructor() Ownable() {}

    /**
     * @notice Set the Marketplace contract address
     * @param _marketplace The address of the Marketplace contract
     */
    /**
     * @notice Set the Marketplace contract address
     * @param _marketplace The address of the Marketplace contract
     */
    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /**
     * @notice Add a rating and review for a user after job completion
     * @param user The address of the user being rated
     * @param score The rating score (1-5)
     * @param review The review text
     * @param jobId The job ID associated with the rating
     */
    /**
     * @notice Add a rating and review for a user after job completion
     * @param user The address of the user being rated
     * @param score The rating score (1-5)
     * @param review The review text
     * @param jobId The job ID associated with the rating
     */
    function rateUser(address user, uint8 score, string memory review, uint256 jobId) external onlyMarketplace whenNotPaused {
        require(score >= 1 && score <= 5, "Score must be 1-5");
        userRatings[user].push(Rating(score, review, tx.origin, jobId));
        emit Rated(user, score, review, tx.origin, jobId);
    }

    /**
     * @notice Get all ratings for a user
     * @param user The address of the user
     * @return Array of Rating structs
     */
    /**
     * @notice Get all ratings for a user
     * @param user The address of the user
     * @return Array of Rating structs
     */
    function getRatings(address user) external view returns (Rating[] memory) {
        return userRatings[user];
    }

    /**
     * @notice Calculate and return the average rating for a user
     * @param user The address of the user
     * @return The average rating (0 if no ratings)
     */
    /**
     * @notice Calculate and return the average rating for a user
     * @param user The address of the user
     * @return The average rating (0 if no ratings)
     */
    function getAverageRating(address user) external view returns (uint256) {
    /**
     * @notice Pause the contract in case of emergency
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
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
