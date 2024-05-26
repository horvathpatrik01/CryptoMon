// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CryptoMon.sol";
enum BattleStatus {
        PENDING,
        PRIVATE,
        STARTED,
        ENDED
    }
struct Battle {
        bool firstPlayersTurn;
        BattleStatus battleStatus; /// @param battleStatus enum to indicate battle status
        address[2] players; /// @param players address array representing players in this battle
        uint16[] player1Monsters; /// @param player1Monsters uint array representing the player 1's cryptomons in this battle
        uint16[] player2Monsters; /// @param player2Monsters uint array representing the player 2's cryptomons in this battle
        address winner; /// @param winner winner address
    }

/**
 * @title Cryptomon: A decentralized game where players can collect, trade, and battle unique digital monsters.
 * @dev This smart contract defines the core functionality of the Cryptomon game.
 *      It includes features such as monster ownership, battle system, rewards distribution, leveling, and tournaments.
 *      The code is open-source and transparent to ensure fairness and trust in the game mechanics.
 */
contract MonBattle is Ownable {
    CryptoMon private cryptoMon;
    uint256 private _totalBattles = 0;

    Battle[] private battles;

    constructor(address _monstersContract) Ownable(_monstersContract) {
        // Initialize the Battles contract
        cryptoMon = CryptoMon(_monstersContract);
        _totalBattles = 0;
    }

    event BattleCreated(address player1, address player2, uint256 battleIndex);
    event SkillUsed(
        address player,
        uint16 attackerIndex,
        uint16 targetIndex,
        SkillType skillType,
        uint16 skillDamage
    );
    event BattleEnded(address winner, uint256 battleIndex);

    modifier EligibleMonsters(uint16[] memory playerMonsters) {
        require(
            playerMonsters.length > 0,
            "You must have at least one monster to start a battle"
        );
        require(
            playerMonsters.length < 5,
            "A maximum of 4 monsters can participate in a battle"
        );
        _;
    }

    // Function to start a battle with random players
    function startBattle(
        uint16[] memory playerMonsters
    ) external EligibleMonsters(playerMonsters) {
        for (uint256 i = 0; i < _totalBattles; i++) {
            if (
                battles[i].battleStatus == BattleStatus.PENDING &&
                battles[i].players[0] != msg.sender
            ) {
                battles[i].players[1] = msg.sender;
                battles[i].battleStatus = BattleStatus.STARTED;
                battles[i].player2Monsters = playerMonsters;
                emit BattleCreated(
                    battles[i].players[0],
                    battles[i].players[1],
                    i
                );
                return;
            }
        }

        battles.push(
            Battle({
                players: [msg.sender, address(0)],
                battleStatus: BattleStatus.PENDING,
                firstPlayersTurn: true,
                player1Monsters: playerMonsters,
                player2Monsters: new uint16[](0),
                winner: address(0)
            })
        );
        emit BattleCreated(msg.sender, address(0), _totalBattles);
        _totalBattles++;
    }

    // Function to join a battle with an other player by address
    function joinBattle(
        address otherPlayer,
        uint16[] memory playerMonsters
    ) external EligibleMonsters(playerMonsters) {
        require(otherPlayer != msg.sender, "You can't join to yourself!");
        require(otherPlayer != address(0), "Invalid player address");

        for (uint256 i = 0; i < _totalBattles; i++) {
            if (
                battles[i].battleStatus == BattleStatus.PRIVATE &&
                battles[i].players[0] == otherPlayer &&
                battles[i].players[1] == msg.sender
            ) {
                battles[i].battleStatus = BattleStatus.STARTED;
                battles[i].player2Monsters = playerMonsters;
                emit BattleCreated(
                    battles[i].players[0],
                    battles[i].players[1],
                    i
                );
                return;
            }
        }

        battles.push(
            Battle({
                players: [msg.sender, otherPlayer],
                battleStatus: BattleStatus.PRIVATE,
                firstPlayersTurn: true,
                player1Monsters: playerMonsters,
                player2Monsters: new uint16[](0),
                winner: address(0)
            })
        );
        emit BattleCreated(msg.sender, otherPlayer, _totalBattles);
        _totalBattles++;
    }

    function useSkill(
        uint256 battleIndex,
        uint16 attackerId,
        uint16 targetId,
        uint256 skillId
    ) external {
        require(battleIndex < _totalBattles, "Invalid battle index");
        require(
            msg.sender == cryptoMon.ownerOf(attackerId),
            "You don't own this monster."
        );
        Battle memory battle = battles[battleIndex];
        require(
            battle.battleStatus == BattleStatus.STARTED,
            "Battle has not started"
        );
        require(
            battle.players[0] == msg.sender || battle.players[1] == msg.sender,
            "You are not part of this battle"
        );

        bool firstPlayersTurn = msg.sender == battle.players[0];

        require(
            firstPlayersTurn == battle.firstPlayersTurn,
            "It's not your turn"
        );

        uint16[] memory allyMonsters = firstPlayersTurn
            ? battle.player1Monsters
            : battle.player2Monsters;

        // Check if attackerId is an element of the attackerMonsters array
        bool isValidAttacker = false;
        for (uint256 i = 0; i < allyMonsters.length; i++) {
            if (allyMonsters[i] == attackerId) {
                isValidAttacker = true;
                break;
            }
        }
        require(isValidAttacker, "Invalid attacker ID");

        // CryptoMon.Monster memory attacker = cryptoMon.getMonster(attackerId);
        // Retrieve the attacker monster from storage
        Monster memory attacker = cryptoMon.getMonster(attackerId);
        // Check if the attacker is defeated
        require(attacker.health > 0, "Attacker is already defeated.");

        Skill memory skill = attacker.monsterType.skillSet[skillId];
        // Check if skill cooldown is expired
        require(attacker.cooldowns[skillId] == 0, "Skill is on cooldown");

        uint16[] memory enemyMonsters = firstPlayersTurn
            ? battle.player2Monsters
            : battle.player1Monsters;

        if (skill.skillType == SkillType.Heal) {
            // Check if targetId is an element of the attackerMonsters array
            bool isValidAlly = false;
            for (uint256 i = 0; i < allyMonsters.length; i++) {
                if (allyMonsters[i] == targetId) {
                    isValidAlly = true;
                    break;
                }
            }
            require(isValidAlly, "Invalid ally ID");
        } else {
            // Check if targetId is an element of the targetMonsters array
            bool isValidTarget = false;
            for (uint256 i = 0; i < enemyMonsters.length; i++) {
                if (enemyMonsters[i] == targetId) {
                    isValidTarget = true;
                    break;
                }
            }
            require(isValidTarget, "Invalid target ID");
        }

        Monster memory target = cryptoMon.getMonster(targetId);
        require(target.health > 0, "Target is already defeated.");

        // Calculate damage based on skill type and value
        uint16 skillDamage = (attacker.attack * skill.multiplier) / 100;

        emit SkillUsed(
            msg.sender,
            attackerId,
            targetId,
            skill.skillType,
            skillDamage
        );

        for (uint8 i = 0; i < attacker.cooldowns.length; i++) {
            if (attacker.cooldowns[i] > 0) {
                attacker.cooldowns[i]--;
            }
        }
        // Reset cooldown for skill
        attacker.cooldowns[skillId] = skill.cooldown;

        if (skill.skillType == SkillType.Heal) {
            // Healing skill, increase target's health
            target.health = target.health + skillDamage > target.maxHp
                ? target.maxHp
                : target.health + skillDamage;

            // Switch turn to the other player
            battle.firstPlayersTurn = !battle.firstPlayersTurn;
            // Update the attacker cooldown and target monster hp
            cryptoMon.setMonsterHealth(targetId, target.health);
            cryptoMon.setMonsterCooldowns(attackerId, attacker.cooldowns);
            return; // Exit early, no need to proceed further
        }

        // Apply damage to target monster's health
        target.health = target.health > skillDamage
            ? target.health - skillDamage
            : 0;

        // Update cooldown for the used skill
        attacker.cooldowns[skillId] = uint8(block.timestamp) + skill.cooldown;

        // Update the attacker cooldown and target monster hp
        cryptoMon.setMonsterHealth(targetId, target.health);
        cryptoMon.setMonsterCooldowns(attackerId, attacker.cooldowns);
        // Check if any monsters in the opposing team are defeated
        bool allDefeated = true;
        for (uint8 i = 0; i < enemyMonsters.length; i++) {
            if (cryptoMon.getMonster(enemyMonsters[i]).health > 0) {
                allDefeated = false;
                break;
            }
        }
        // If all monsters in the opposing team are defeated, end the battle
        if (allDefeated) {
            battle.battleStatus = BattleStatus.ENDED;
            battle.winner = msg.sender;
            emit BattleEnded(msg.sender, battleIndex);

            // Calculate experience rewards for the winning player's monsters based on the opponent's monsters' average level
            uint8 totalLevels = 0;
            for (uint8 i = 0; i < enemyMonsters.length; i++) {
                totalLevels += cryptoMon.getMonster(enemyMonsters[i]).level;
            }
            uint8 avgLevel = (totalLevels + uint8(enemyMonsters.length) / 2) /
                uint8(enemyMonsters.length); // Rounded average level
            for (uint8 i = 0; i < allyMonsters.length; i++) {
                if (
                    cryptoMon.getMonster(allyMonsters[i]).level ==
                    cryptoMon.MAX_LEVEL()
                ) continue;
                cryptoMon.rewardExperience(
                    cryptoMon.getMonster(allyMonsters[i]).monsterId,
                    avgLevel
                );
            }
        }
        // Switch turn to the other player
        battle.firstPlayersTurn = !battle.firstPlayersTurn;
    }
}
