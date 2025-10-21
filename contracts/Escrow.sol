// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Escrow {
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

    constructor() {
        owner = msg.sender;
    }

    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    function deposit(uint256 jobId, address freelancer) external payable onlyMarketplace {
        require(msg.value > 0, "Deposit must be greater than 0");
        escrows[jobId] = EscrowInfo(jobId, tx.origin, freelancer, msg.value, EscrowStatus.Pending, "", false);
        emit Deposited(jobId, tx.origin, msg.value);
    }

    function release(uint256 jobId) external onlyMarketplace {
        EscrowInfo storage escrow = escrows[jobId];
        require(escrow.status == EscrowStatus.Pending, "Escrow not pending");
        escrow.status = EscrowStatus.Released;
        payable(escrow.freelancer).transfer(escrow.amount);
        emit Released(jobId, escrow.freelancer);
    }

    function refund(uint256 jobId) external onlyMarketplace {
        EscrowInfo storage escrow = escrows[jobId];
        require(escrow.status == EscrowStatus.Pending, "Escrow not pending");
        escrow.status = EscrowStatus.Refunded;
        payable(escrow.client).transfer(escrow.amount);
        emit Refunded(jobId, escrow.client);
    }

    function dispute(uint256 jobId, string calldata reason) external onlyMarketplace {
        EscrowInfo storage escrow = escrows[jobId];
        require(escrow.status == EscrowStatus.Pending, "Escrow not pending");
        escrow.status = EscrowStatus.Disputed;
        escrow.disputeReason = reason;
        emit Disputed(jobId, reason);
    }

    // Manual dispute resolution by owner
    function resolveDispute(uint256 jobId, bool releaseToFreelancer) external onlyOwner {
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
