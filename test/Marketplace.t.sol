// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/Escrow.sol";
import "../contracts/Ratings.sol";
import "../contracts/Marketplace.sol";

contract MarketplaceTest is Test {
    Escrow public escrow;
    Ratings public ratings;
    Marketplace public marketplace;

    address public client = address(0x1);
    address public freelancer = address(0x2);
    address public attacker = address(0x3);

    function setUp() public {
        // deploy contracts (test contract will be owner)
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

    function test_Happy_FullFlowAndRating() public {
        vm.prank(client);
        marketplace.postJob("Build website", 1 ether);

        vm.prank(client);
        marketplace.acceptProposal(1, freelancer);

        vm.prank(client);
        marketplace.depositEscrow{value: 1 ether}(1);

        vm.prank(freelancer);
        marketplace.submitWork(1);

        vm.prank(client);
        marketplace.completeJob(1, 5, "Excellent");

        uint256 avg = ratings.getAverageRating(freelancer);
        assertEq(avg, 5);

        (, , , uint256 amount, Escrow.EscrowStatus status, , ) = escrow.escrows(1);
        assertEq(amount, 1 ether);
        assertEq(uint256(status), uint256(Escrow.EscrowStatus.Released));
    }

    function test_Happy_FreelancerRatesClient() public {
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

        vm.prank(freelancer);
        marketplace.rateClient(1, 4, "Good client");

        uint256 avgClient = ratings.getAverageRating(client);
        assertEq(avgClient, 4);
    }

    function test_Happy_CancelBeforeAssignment() public {
        vm.prank(client);
        marketplace.postJob("Small task", 0.5 ether);
        vm.prank(client);
        marketplace.cancelJob(1);

        vm.prank(client);
        vm.expectRevert(bytes("Job not open"));
        marketplace.acceptProposal(1, freelancer);
    }

    function test_Happy_DisputeAndResolveToFreelancer() public {
        vm.prank(client);
        marketplace.postJob("Audit", 1 ether);
        vm.prank(client);
        marketplace.acceptProposal(1, freelancer);
        vm.prank(client);
        marketplace.depositEscrow{value: 1 ether}(1);

        vm.prank(client);
        marketplace.disputeJob(1, "Client unhappy");

        // resolver is test contract (owner)
        escrow.resolveDispute(1, true);

        (, , , , Escrow.EscrowStatus status, , ) = escrow.escrows(1);
        assertEq(uint256(status), uint256(Escrow.EscrowStatus.Released));
    }

    function test_Happy_PauseUnpauseMarketplace() public {
        marketplace.pause();
        vm.prank(client);
        vm.expectRevert();
        marketplace.postJob("Paused job", 1 ether);
        marketplace.unpause();
        vm.prank(client);
        marketplace.postJob("After unpause", 0.1 ether);
    }

    // ---------------------- Revert tests ----------------------

    function test_Revert_UnauthorizedAccept() public {
        vm.prank(client);
        marketplace.postJob("Secret", 1 ether);
        vm.prank(attacker);
        vm.expectRevert(bytes("Only client can accept proposal"));
        marketplace.acceptProposal(1, attacker);
    }

    function test_Revert_DepositWrongAmount() public {
        vm.prank(client);
        marketplace.postJob("Price Mismatch", 1 ether);
        vm.prank(client);
        marketplace.acceptProposal(1, freelancer);
        vm.prank(client);
        vm.expectRevert(bytes("Incorrect deposit amount"));
        marketplace.depositEscrow{value: 0.5 ether}(1);
    }

    function test_Revert_SubmitByNonFreelancer() public {
        vm.prank(client);
        marketplace.postJob("Design", 1 ether);
        vm.prank(client);
        marketplace.acceptProposal(1, freelancer);
        vm.prank(attacker);
        vm.expectRevert(bytes("Only assigned freelancer can submit work"));
        marketplace.submitWork(1);
    }

    function test_Revert_CompleteWithoutSubmit() public {
        vm.prank(client);
        marketplace.postJob("Backlog", 1 ether);
        vm.prank(client);
        marketplace.acceptProposal(1, freelancer);
        vm.prank(client);
        marketplace.depositEscrow{value: 1 ether}(1);
        vm.prank(client);
        vm.expectRevert(bytes("Work not submitted"));
        marketplace.completeJob(1, 5, "Premature");
    }

    function test_Revert_RateBeforeCompletion() public {
        vm.prank(client);
        marketplace.postJob("Review test", 1 ether);
        vm.prank(client);
        marketplace.acceptProposal(1, freelancer);
        vm.prank(freelancer);
        vm.expectRevert(bytes("Job not completed"));
        marketplace.rateClient(1, 4, "Too early");
    }
}
