// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Escrow is Ownable, Pausable {
    address public marketplace;

    modifier onlyMarketplace() {
        require(msg.sender == marketplace, "Only Marketplace contract can call");
        _;
    }
    enum EscrowStatus { Pending, Released, Refunded, Disputed }

    struct EscrowInfo {
        uint256 jobId;
        address client;
        address freelancer;
        uint256 amount;
        EscrowStatus status;
        string disputeReason;
        bool resolved;
    }

    mapping(uint256 => EscrowInfo) public escrows;

    event Deposited(uint256 indexed jobId, address indexed client, uint256 amount);
    event Released(uint256 indexed jobId, address indexed freelancer);
    event Refunded(uint256 indexed jobId, address indexed client);
    event Disputed(uint256 indexed jobId, string reason);
    event DisputeResolved(uint256 indexed jobId, bool releasedToFreelancer);

    /**
     * @notice Initializes the Escrow contract and sets the owner
     */
    /**
     * @notice Initializes the Escrow contract
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
     * @notice Deposit payment into escrow for a job
     * @param jobId The job ID
     * @param freelancer The freelancer's address
     */
    /**
     * @notice Deposit payment into escrow for a job
     * @param jobId The job ID
     * @param freelancer The freelancer's address
     */
    function deposit(uint256 jobId, address freelancer) external payable onlyMarketplace whenNotPaused {
        require(msg.value > 0, "Deposit must be greater than 0");
        escrows[jobId] = EscrowInfo(jobId, tx.origin, freelancer, msg.value, EscrowStatus.Pending, "", false);
        emit Deposited(jobId, tx.origin, msg.value);
    }

    /**
     * @notice Release escrow payment to freelancer after job completion
     * @param jobId The job ID
     */
    /**
     * @notice Release escrow payment to freelancer after job completion
     * @param jobId The job ID
     */
    function release(uint256 jobId) external onlyMarketplace whenNotPaused {
        EscrowInfo storage escrow = escrows[jobId];
        require(escrow.status == EscrowStatus.Pending, "Escrow not pending");
        escrow.status = EscrowStatus.Released;
        payable(escrow.freelancer).transfer(escrow.amount);
        emit Released(jobId, escrow.freelancer);
    }

    /**
     * @notice Refund escrow payment to client if job is cancelled
     * @param jobId The job ID
     */
    /**
     * @notice Refund escrow payment to client if job is cancelled
     * @param jobId The job ID
     */
    function refund(uint256 jobId) external onlyMarketplace whenNotPaused {
        EscrowInfo storage escrow = escrows[jobId];
        require(escrow.status == EscrowStatus.Pending, "Escrow not pending");
        escrow.status = EscrowStatus.Refunded;
        payable(escrow.client).transfer(escrow.amount);
        emit Refunded(jobId, escrow.client);
    }

    /**
     * @notice Raise a dispute for a job in escrow
     * @param jobId The job ID
     * @param reason The reason for the dispute
     */
    /**
     * @notice Raise a dispute for a job in escrow
     * @param jobId The job ID
     * @param reason The reason for the dispute
     */
    function dispute(uint256 jobId, string calldata reason) external onlyMarketplace whenNotPaused {
        EscrowInfo storage escrow = escrows[jobId];
        require(escrow.status == EscrowStatus.Pending, "Escrow not pending");
        escrow.status = EscrowStatus.Disputed;
        escrow.disputeReason = reason;
        emit Disputed(jobId, reason);
    }

    // Manual dispute resolution by owner
    /**
     * @notice Manually resolve a dispute by owner
     * @param jobId The job ID
     * @param releaseToFreelancer If true, release payment to freelancer; otherwise refund client
     */
    /**
     * @notice Manually resolve a dispute by owner
     * @param jobId The job ID
     * @param releaseToFreelancer If true, release payment to freelancer; otherwise refund client
     */
    function resolveDispute(uint256 jobId, bool releaseToFreelancer) external onlyOwner whenNotPaused {
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
        EscrowInfo storage escrow = escrows[jobId];
        require(escrow.status == EscrowStatus.Disputed, "No dispute");
        require(!escrow.resolved, "Already resolved");
        escrow.resolved = true;
        if (releaseToFreelancer) {
            escrow.status = EscrowStatus.Released;
            payable(escrow.freelancer).transfer(escrow.amount);
        } else {
            escrow.status = EscrowStatus.Refunded;
            payable(escrow.client).transfer(escrow.amount);
        }
        emit DisputeResolved(jobId, releaseToFreelancer);
    }
}
