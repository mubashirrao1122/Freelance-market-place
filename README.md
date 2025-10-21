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
- Pausable and upgradeable contract recommendations.

## Usage

1. Deploy `Escrow.sol` and `Ratings.sol`.
2. Deploy `Marketplace.sol` with the addresses of the Escrow and Ratings contracts.
3. Set the Marketplace contract address in both Escrow and Ratings contracts.
4. Interact with the Marketplace contract for job posting, escrow deposits, work submission, completion, disputes, and ratings.

## Legal & Compliance Risks and Controls

| Legal Issue | Where it Appears | Risk | Control/Mitigation |
|-------------|------------------|------|-------------------|
| Offer & Acceptance | Job posting, proposal, assignment | Disputes over contract formation | On-chain records, clear events, explicit actions |
| Lost in Translation | Contract logic | Misinterpretation of terms | NatSpec comments, peer/legal review |
| Data Protection & Privacy | User/job data on-chain | Exposure of personal data | Minimal data storage, privacy notice |
| Noncompliance w/ Laws | Payments, disputes | Regulatory violations | Admin controls, documentation, legal review |
| Ambiguities of Human Contracts | Job descriptions, disputes | Vague terms | Structured inputs, guidelines, off-chain arbitration |
| Irrevocability of Code | All contracts | Bugs, vulnerabilities | Upgradeable proxy, pausable, audits |
| Jurisdictional Issues | Global users | Unclear applicable law | Jurisdiction notice, decentralized arbitration |
| Uniform Contracts Machines | Automated logic | Lack of flexibility | Manual dispute resolution, modularity |

## Privacy Notice

This platform stores only essential data (wallet addresses, job details, ratings) on-chain. Users should not include personal or sensitive information in job descriptions or reviews. All data is public and permanent.

## Jurisdiction & Compliance

These contracts are intended for global use. Users are responsible for compliance with local laws. The platform provides decentralized dispute resolution and admin controls for compliance.

## Upgradeability & Pausable Contracts

For future upgrades, use OpenZeppelin's proxy contracts and pausable patterns. Admins can pause contracts in case of emergencies or compliance issues.

---

**Author:** Mubashir Rao
