# Freelance Marketplace Smart Contracts

This repository contains modular smart contracts for a decentralized freelance marketplace with escrow and ratings functionality.

## Contracts Overview

- **Marketplace.sol**  
  Handles job creation, proposals, assignments, job status, escrow deposits, and ratings.  
  Integrates with Escrow and Ratings contracts for secure payments and reputation management.

- **Escrow.sol**  
  Manages payment holding, release, refunds, and dispute resolution.  
  Only the Marketplace contract can trigger payment actions.  
  Supports manual dispute resolution by the contract owner.

- **Ratings.sol**  
  Stores and manages user ratings and reviews, linked to job IDs for traceability.  
  Only the Marketplace contract can add ratings.  
  Provides average rating calculation for users.

## Features

- Modular architecture for scalability and maintainability.
- Access control to ensure only authorized contract interactions.
- Dispute resolution logic for secure and fair transactions.
- NatSpec documentation for all public/external functions.

## Usage

1. Deploy `Escrow.sol` and `Ratings.sol`.
2. Deploy `Marketplace.sol` with the addresses of the Escrow and Ratings contracts.
3. Set the Marketplace contract address in both Escrow and Ratings contracts.
4. Interact with the Marketplace contract for job posting, escrow deposits, work submission, completion, disputes, and ratings.

## Upgradeability

For future upgrades, consider using OpenZeppelin's proxy contracts.

---

**Author:** mubashirrao1122
