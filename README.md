### Blockchain Technologies and Application Assignment:
# Cryptomon

Cryptómon is a **decentralized game** built on the blockchain where players can collect, trade, and battle unique digital monsters (cryptómons). Each monster has a set of attributes, abilities, and rarity levels. Players can engage in simple battles or challenges with their monsters and earn experience points (XP) and special rewards.

## Requirements

### 1. Monster Ownership

Each monster is a unique, non-fungible token (NFT) representing the ownership, attributes, and abilities of the digital creature. Players can obtain monsters through various means, such as participating in the completion of in-game challenges.

### 2. Simple Battle System

Implement a basic battle system that allows players to engage in combat using their monsters. The specifics of the battle mechanics are left open to design and implementation, encouraging creativity and problem-solving.

-   **a.** Each monster has a set of moves (e.g., attack, defend, heal) with varying effects on the opponent’s health points (HP).
-   **b.** The battle ends when one of the monsters reaches zero HP.
-   **c.** The system could be turn-based, where players take turns choosing moves for their monsters.
-   **d.** You may also consider implementing a battle system where players can utilize a team of multiple cryptómons (e.g., 6) and strategically switch them out during the battle. However, this feature is optional and not a strict requirement.

### 3. Rewards and Incentives

Players can earn rewards, such as in-game currency or rare items, by participating in battles, tournaments, or special events. The smart contract should manage the distribution of rewards based on player performance and participation.

### 4. Leveling, Progression, and Evolutions

Monsters gain experience points (XP) through battles, allowing them to level up and improve their attributes and abilities. Additionally, some monsters can evolve into more powerful forms when they reach certain levels or fulfill specific criteria. The smart contract should track the monsters’ XP, level, attribute growth, and evolution progress.

-   **a.** Upon evolution, a monster’s attributes (e.g., attack, defense, health points) are increased, and it may gain new abilities or moves.
-   **b.** This can be achieved by updating the attributes or minting a new monster for the new evolution and invalidating the old one.

### 5. Tournaments

Implement a simple single-elimination tournament system where players can enter their monsters to compete against others. A single-elimination tournament consists of multiple rounds, with each round’s winners proceeding to the next until only one monster remains undefeated. The tournament’s creator can set rules such as the maximum number of participants and level restrictions.

---

<details> 
  <summary><h2>Requirements</h2></summary>

## Common Requirements
You are expected to use git as a version control system (VCS) and GitHub. You should create a public GitHub repository before applying for the available assignments and submit its URL in the application form.

You are also expected to submit (on Teams, in the Assignments tab) the following artifacts in a **single zip** file:

-   A **PDF** document detailing…
    -   the design decisions you took,
   -   the data model (structs/classes) your contract stores and manipulates,
    -   the API of the smart contract,
    -   the essential implementation details (if any),
    -   the definition and implementation of test cases,
    -   instructions for bootstrapping the project, running the test cases, and deploying the contracts.
-   The root directory of your smart contract project (Hardhat project or VS Code workspace):
    -   the smart contract in a compilable and deployable form,
    -   test cases,
    -   **without** generated artifacts or installed dependencies!

## Solidity Specifics

For Solidity-based projects, we require students to use the [Hardhat](https://hardhat.org/) framework to develop and test their smart contracts. The Hardhat-based project should include the contract(s) and the corresponding test cases, making it easy to execute and evaluate. To get started and ensure you follow the recommended practices, please refer to the [Solidity guide](https://ftsrg-bta.github.io/lab-ethereum/guide.html) provided for the course.
</details>
