// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/Escrow.sol";
import "../contracts/Ratings.sol";
import "../contracts/Marketplace.sol";

contract MarketplaceTest is Test {
    Escrow escrow;
    Ratings ratings;
    Marketplace marketplace;

    address client = address(0x1);
    address freelancer = address(0x2);
    address attacker = address(0x3);

    function setUp() public {
        // deploy contracts
        escrow = new Escrow();
        ratings = new Ratings();
        marketplace = new Marketplace(address(escrow), address(ratings));

        // configure marketplace in escrow and ratings
        escrow.setMarketplace(address(marketplace));
        ratings.setMarketplace(address(marketplace));

        // fund test accounts
        vm.deal(client, 10 ether);
        vm.deal(freelancer, 1 ether);
        vm.deal(attacker, 1 ether);
    }

    // ---------------------- Happy path tests ----------------------

    function testHappy_FullFlowAndRating() public {
        // client posts job
        vm.prank(client);
        marketplace.postJob("Build website", 1 ether);

        // client accepts freelancer
        vm.prank(client);
        marketplace.acceptProposal(1, freelancer);

        // client deposits escrow
        vm.prank(client);
        marketplace.depositEscrow{value: 1 ether}(1);

        // freelancer submits work
        vm.prank(freelancer);
        marketplace.submitWork(1);

        // client completes job and rates freelancer
        vm.prank(client);
        marketplace.completeJob(1, 5, "Excellent");

        // check rating
        uint256 avg = ratings.getAverageRating(freelancer);
        assertEq(avg, 5);

        // escrow should have no locked funds
        (, , , uint256 amount, Escrow.EscrowStatus status, , bool resolved) = escrow.escrows(1);
        assertEq(amount, 1 ether); // amount stored
        assertEq(uint(status), uint(Escrow.EscrowStatus.Released));
        assertTrue(resolved);
    }

    function testHappy_FreelancerRatesClient() public {
        // setup and complete job
        vm.prank(client);
        marketplace.postJob("Task", 1 ether);
        vm.prank(client);
        marketplace.acceptProposal(1, freelancer);
        vm.prank(client);
        marketplace.depositEscrow{value: 1 ether}(1);
        vm.prank(freelancer);
        marketplace.submitWork(1);
        vm.prank(client);
        marketplace.completeJob(1, 5, "Good job");

        // freelancer rates client
        vm.prank(freelancer);
        marketplace.rateClient(1, 4, "Good client");

        uint256 avgClient = ratings.getAverageRating(client);
        assertEq(avgClient, 4);
    }

    function testHappy_CancelBeforeAssignment() public {
        vm.prank(client);
        marketplace.postJob("Small task", 0.5 ether);
        vm.prank(client);
        marketplace.cancelJob(1);
        // job status should be Cancelled (no direct accessor, but events emitted)
        // Ensure cannot accept after cancel
        vm.prank(client);
        vm.expectRevert(bytes("Job not open"));
        marketplace.acceptProposal(1, freelancer);
    }

    function testHappy_DisputeAndResolveToFreelancer() public {
        vm.prank(client);
        marketplace.postJob("Audit", 1 ether);
        vm.prank(client);
        marketplace.acceptProposal(1, freelancer);
        vm.prank(client);
        marketplace.depositEscrow{value: 1 ether}(1);

        // raise dispute
        vm.prank(client);
        marketplace.disputeJob(1, "Client unhappy");

        // owner resolves dispute in favor of freelancer
        escrow.resolveDispute(1, true);
        (, , , uint256 amount, Escrow.EscrowStatus status, , ) = escrow.escrows(1);
        assertEq(uint(status), uint(Escrow.EscrowStatus.Released));
    }

    function testHappy_PauseUnpauseMarketplace() public {
        // only owner can pause
        marketplace.pause();
        // paused: operations should revert
        vm.prank(client);
        vm.expectRevert();
        marketplace.postJob("Paused job", 1 ether);
        // unpause
        marketplace.unpause();
        vm.prank(client);
        marketplace.postJob("After unpause", 0.1 ether);
    }

    // ---------------------- Conflict (revert) tests ----------------------

    function testFail_UnauthorizedAccept() public {
        vm.prank(client);
        marketplace.postJob("Secret", 1 ether);
        // attacker tries to accept
        vm.prank(attacker);
        marketplace.acceptProposal(1, attacker);
    }

    function testFail_DepositWrongAmount() public {
        vm.prank(client);
        marketplace.postJob("Price Mismatch", 1 ether);
        vm.prank(client);
        marketplace.acceptProposal(1, freelancer);
        // deposit wrong amount
        vm.prank(client);
        marketplace.depositEscrow{value: 0.5 ether}(1);
    }

    function testFail_SubmitByNonFreelancer() public {
        vm.prank(client);
        marketplace.postJob("Design", 1 ether);
        vm.prank(client);
        marketplace.acceptProposal(1, freelancer);
        // attacker tries to submit work
        vm.prank(attacker);
        marketplace.submitWork(1);
    }

    function testFail_CompleteWithoutSubmit() public {
        vm.prank(client);
        marketplace.postJob("Backlog", 1 ether);
        vm.prank(client);
        marketplace.acceptProposal(1, freelancer);
        vm.prank(client);
        marketplace.depositEscrow{value: 1 ether}(1);
        // client tries to complete before freelancer submits
        vm.prank(client);
        marketplace.completeJob(1, 5, "Premature");
    }

    function testFail_RateBeforeCompletion() public {
        vm.prank(client);
        marketplace.postJob("Review test", 1 ether);
        vm.prank(client);
        marketplace.acceptProposal(1, freelancer);
        // freelancer tries to rate client before completion
        vm.prank(freelancer);
        marketplace.rateClient(1, 4, "Too early");
    }
}
