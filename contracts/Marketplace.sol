// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IEscrow {
    function deposit(uint256 jobId, address freelancer) external payable;
    function release(uint256 jobId) external;
    function refund(uint256 jobId) external;
    function dispute(uint256 jobId) external;
}

interface IRatings {
    function rateUser(address user, uint8 score, string calldata review, uint256 jobId) external;
}

contract Marketplace is Ownable, Pausable {
    enum JobStatus { Open, Assigned, Submitted, Completed, Cancelled }

    struct Job {
        uint256 id;
        address client;
        address freelancer;
        string description;
        uint256 price;
        JobStatus status;
    }

    uint256 public jobCount;
    mapping(uint256 => Job) public jobs;

    IEscrow public escrowContract;
    IRatings public ratingsContract;

    event JobPosted(uint256 indexed jobId, address indexed client, string description, uint256 price);
    event ProposalAccepted(uint256 indexed jobId, address indexed freelancer);
    event JobSubmitted(uint256 indexed jobId);
    event JobCompleted(uint256 indexed jobId);
    event JobCancelled(uint256 indexed jobId);
    event EscrowDeposited(uint256 indexed jobId, address indexed client, uint256 amount);
    event EscrowReleased(uint256 indexed jobId, address indexed freelancer);
    event EscrowRefunded(uint256 indexed jobId, address indexed client);
    event EscrowDisputed(uint256 indexed jobId);

    /**
     * @notice Initializes the Marketplace contract with Escrow and Ratings contract addresses
     * @param escrowAddress The address of the Escrow contract
     * @param ratingsAddress The address of the Ratings contract
     */
    constructor(address escrowAddress, address ratingsAddress) {
        escrowContract = IEscrow(escrowAddress);
        ratingsContract = IRatings(ratingsAddress);
    }

    /**
     * @notice Post a new job to the marketplace
     * @param description The job description
     * @param price The price offered for the job
     */
    function postJob(string memory description, uint256 price) external whenNotPaused {
        jobCount++;
        jobs[jobCount] = Job(jobCount, msg.sender, address(0), description, price, JobStatus.Open);
        emit JobPosted(jobCount, msg.sender, description, price);
    }

    /**
     * @notice Accept a freelancer's proposal for a job
     * @param jobId The job ID
     * @param freelancer The freelancer's address
     */
    function acceptProposal(uint256 jobId, address freelancer) external whenNotPaused {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client, "Only client can accept proposal");
        require(job.status == JobStatus.Open, "Job not open");
        job.freelancer = freelancer;
        job.status = JobStatus.Assigned;
        emit ProposalAccepted(jobId, freelancer);
    }

    /**
     * @notice Deposit payment into escrow for a job
     * @param jobId The job ID
     */
    function depositEscrow(uint256 jobId) external payable whenNotPaused {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client, "Only client can deposit escrow");
        require(job.status == JobStatus.Assigned, "Job must be assigned");
        require(msg.value == job.price, "Incorrect deposit amount");
        escrowContract.deposit{value: msg.value}(jobId, job.freelancer);
        emit EscrowDeposited(jobId, msg.sender, msg.value);
    }

    /**
     * @notice Submit completed work for a job
     * @param jobId The job ID
     */
    function submitWork(uint256 jobId) external whenNotPaused {
        Job storage job = jobs[jobId];
        require(msg.sender == job.freelancer, "Only assigned freelancer can submit work");
        require(job.status == JobStatus.Assigned, "Job not assigned");
        job.status = JobStatus.Submitted;
        emit JobSubmitted(jobId);
    }

    /**
     * @notice Complete a job, release escrow, and rate the freelancer
     * @param jobId The job ID
     * @param freelancerRating The rating for the freelancer (1-5)
     * @param review The review for the freelancer
     */
    function completeJob(uint256 jobId, uint8 freelancerRating, string calldata review) external whenNotPaused {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client, "Only client can complete job");
        require(job.status == JobStatus.Submitted, "Work not submitted");
        job.status = JobStatus.Completed;
        escrowContract.release(jobId);
    ratingsContract.rateUser(job.freelancer, freelancerRating, review, jobId);
        emit JobCompleted(jobId);
        emit EscrowReleased(jobId, job.freelancer);
    }

    /**
     * @notice Cancel a job and refund escrow
     * @param jobId The job ID
     */
    function cancelJob(uint256 jobId) external whenNotPaused {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client, "Only client can cancel job");
        require(job.status == JobStatus.Open || job.status == JobStatus.Assigned, "Cannot cancel now");
        job.status = JobStatus.Cancelled;
        escrowContract.refund(jobId);
        emit JobCancelled(jobId);
        emit EscrowRefunded(jobId, job.client);
    }

    /**
     * @notice Raise a dispute for a job in escrow
     * @param jobId The job ID
     * @param reason The reason for the dispute
     */
    function disputeJob(uint256 jobId, string calldata reason) external whenNotPaused {
        Job storage job = jobs[jobId];
        require(msg.sender == job.client || msg.sender == job.freelancer, "Only client or freelancer can dispute");
        require(job.status == JobStatus.Assigned || job.status == JobStatus.Submitted, "Job not disputable");
        escrowContract.dispute(jobId, reason);
        emit EscrowDisputed(jobId);
    }

    /**
     * @notice Rate the client after job completion
     * @param jobId The job ID
     * @param clientRating The rating for the client (1-5)
     * @param review The review for the client
     */
    function rateClient(uint256 jobId, uint8 clientRating, string calldata review) external whenNotPaused {
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
        Job storage job = jobs[jobId];
        require(msg.sender == job.freelancer, "Only freelancer can rate client");
        require(job.status == JobStatus.Completed, "Job not completed");
        ratingsContract.rateUser(job.client, clientRating, review, jobId);
    }
}
