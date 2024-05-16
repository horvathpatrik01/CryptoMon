// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Cryptomon: A decentralized game where players can collect, trade, and battle unique digital monsters.
 * @dev This smart contract defines the core functionality of the Cryptomon game.
 *      It includes features such as monster ownership, battle system, rewards distribution, leveling, and tournaments.
 *      The code is open-source and transparent to ensure fairness and trust in the game mechanics.
 */
contract CryptoMon is ERC721, ERC721URIStorage, Ownable {
    uint16 private _tokenId = 0;
    uint8 private _skillId = 0;
    uint8 private _typeId = 0;

    /**
     * @dev _baseTokenURI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    string _baseTokenURI;

    uint16 public constant MAX_MONSTERS = 10; // Max number of NFTs
    uint8 public constant MAX_LEVEL = 5; // Max level of Monsters

    enum SkillType {
        NormalAttack,
        SpecialAttack,
        Heal
    }

    // Definition of a Skill
    struct Skill {
        uint8 id;
        string name;
        SkillType skillType;
        uint16 multiplier;
        uint8 cooldown;
    }

    // Definition of a MonsterType
    struct MonsterType {
        string name;
        uint8 id;
        Skill[] skillSet;
        uint16 baseAttack;
        uint16 baseHealth;
        uint16 attackGrowthPercent; // Attack points added per level
        uint16 healthGrowthPercent; // Health points added per level
    }

    // Definition of a Monster
    struct Monster {
        uint16 id;
        MonsterType monsterType;
        uint8 level;
        uint16 experience;
        bool evolved;
        uint16 health;
        uint16 maxHp;
        uint16 attack;
        uint8[] cooldowns;
    }

    // Mapping from token ID to Monster attributes
    mapping(uint16 => Monster) public monsters;

    // Mapping from monsterType ID to MonsterType struct
    mapping(uint8 => MonsterType) public monsterTypes;

    // Mapping from monsterType ID to an array of Skills
    mapping(uint8 => Skill) public skills;

    // Constructor
    constructor(
        address initialOwner
    ) ERC721("CryptoMon", "CMON") Ownable(initialOwner) {
        _baseTokenURI = "ipfs://QmWTnckbjATDxnc3ZrbA3HH1MTKeyjjZ3yccgaZeNnD3HV/";
    }

    // Minting
    function mint() public {
        require(_tokenId < MAX_MONSTERS, "M1");
        require(_typeId > 0, "MT2");
        uint8 monsterTypeId = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        _tokenId
                    )
                )
            ) % _typeId
        );
        //Monster storage monster = monsters[_tokenId];
        MonsterType memory monstertype = monsterTypes[monsterTypeId];
        monsters[_tokenId].id = _tokenId;
        monsters[_tokenId].level = 1;
        monsters[_tokenId].experience = 0;
        monsters[_tokenId].monsterType = monsterTypes[monsterTypeId];
        if (monstertype.skillSet.length > 0) {
            for (uint8 i = 0; i < uint8(monstertype.skillSet.length - 1); i++) {
                monsters[_tokenId].cooldowns.push(
                    monstertype.skillSet[i].cooldown
                );
            }
        }
        monsters[_tokenId].health = monstertype.baseHealth;
        monsters[_tokenId].maxHp = monstertype.baseHealth;
        monsters[_tokenId].attack = monstertype.baseAttack;
        string memory uri = string.concat(monstertype.name, ".l1.png");

        _safeMint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, uri);

        _tokenId++;
    }

    // Function to list all monster types and their associated skills
    function listMonsterTypes() public view returns (MonsterType[] memory) {
        uint8 totalTypes = _typeId;
        MonsterType[] memory localmonsterTypes = new MonsterType[](totalTypes);
        for (uint8 i; i < totalTypes; i++) {
            localmonsterTypes[i] = monsterTypes[i];
        }

        return localmonsterTypes;
    }

    // modifier to check inputs
    modifier monsterTypeExists(uint8 typeId) {
        require((bytes(monsterTypes[typeId].name).length) > 0, "MT2");
        _;
    }

    // Function to add a new type of monster
    function addMonsterType(
        string memory name,
        uint16 baseAttack,
        uint16 baseHealth,
        uint16 attackGrowthPercent,
        uint16 healthGrowthPercent
    ) public onlyOwner {
        require(baseAttack > 0, "IN1");
        require(baseHealth > 0, "IN1");
        require(attackGrowthPercent > 0, "IN1");
        require(healthGrowthPercent > 0, "IN1");
        require(bytes(name).length > 0, "IN2");
        // New monsterType
        monsterTypes[_typeId].id = _typeId;
        monsterTypes[_typeId].name = name;
        monsterTypes[_typeId].baseAttack = baseAttack;
        monsterTypes[_typeId].baseHealth = baseHealth;
        monsterTypes[_typeId].attackGrowthPercent = attackGrowthPercent;
        monsterTypes[_typeId].healthGrowthPercent = healthGrowthPercent;
        // Auto-increment the skill ID
        _typeId++;
    }

    // Function to update a type of monster
    function updateMonsterType(
        uint8 typeId,
        string memory name,
        uint16 baseAttack,
        uint16 baseHealth,
        uint16 attackGrowthPercent,
        uint16 healthGrowthPercent
    ) public onlyOwner monsterTypeExists(typeId) {
        require(baseAttack > 0, "IN1");
        require(baseHealth > 0, "IN1");
        require(attackGrowthPercent > 0, "IN1");
        require(healthGrowthPercent > 0, "IN1");
        require(bytes(name).length > 0, "IN2");

        // Update the type of monster
        monsterTypes[typeId].name = name;
        monsterTypes[typeId].baseAttack = baseAttack;
        monsterTypes[typeId].baseHealth = baseHealth;
        monsterTypes[typeId].attackGrowthPercent = attackGrowthPercent;
        monsterTypes[typeId].healthGrowthPercent = healthGrowthPercent;
    }

    // Function to add a new skill to a MonsterType
    function addSkillToMonsterType(
        uint8 typeId,
        uint8 skillId
    ) public onlyOwner monsterTypeExists(typeId) {
        require((bytes(skills[skillId].name).length) > 0, "SK1");

        // Add the new skill to the monsterType
        monsterTypes[typeId].skillSet.push(skills[skillId]);
    }

    // Function to remove a skill from a monsterType
    function removeSkillFromMonsterTypeByIndex(
        uint8 typeId,
        uint8 skillId,
        uint256 index
    ) public onlyOwner monsterTypeExists(typeId) {
        require((bytes(skills[skillId].name).length) > 0, "SK1");

        // Swap the skill to be removed with the last skill in the array
        monsterTypes[typeId].skillSet[index] = monsterTypes[typeId].skillSet[
            monsterTypes[typeId].skillSet.length - 1
        ];

        // Remove the last skill (which is now the skill that needed to be removed or is a duplicate of the last one if index pointed to the last one)
        monsterTypes[typeId].skillSet.pop();
    }

    // // Function to list all skills
    function listSkills() public view returns (Skill[] memory) {
        uint8 totalSkills = _skillId;
        Skill[] memory localSkills = new Skill[](totalSkills);
        for (uint8 i; i < totalSkills; i++) {
            localSkills[i] = skills[i];
        }
        return localSkills;
    }

    // Function to add a new skill
    function addSkill(
        string memory name,
        uint16 multiplierValue,
        SkillType skillType,
        uint8 cooldown
    ) public onlyOwner {
        require(multiplierValue > 0, "IN1");
        require(bytes(name).length > 0, "IN2");
        require(cooldown > 0, "IN1");

        // Add the new skill to the mapping
        skills[_skillId] = Skill({
            id: _skillId,
            name: name,
            skillType: skillType,
            multiplier: multiplierValue,
            cooldown: cooldown
        });
        // Auto-increment the skill ID
        _skillId++;
    }

    // Function to update an existing skill
    function updateSkill(
        uint8 skillId,
        string memory name,
        uint8 skillTypeId,
        uint16 multiplierValue,
        uint8 cooldown
    ) public onlyOwner {
        require(multiplierValue > 0, "IN1");
        require(bytes(name).length > 0, "IN2");
        require(cooldown > 0, "IN1");
        require((bytes(skills[skillId].name).length) > 0, "SK1");

        // Cast uint8 to SkillType enum
        SkillType skillType = SkillType(skillTypeId);

        skills[skillId].name = name;
        skills[skillId].multiplier = multiplierValue;
        skills[skillId].cooldown = cooldown;
        skills[skillId].skillType = skillType;
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
    uint256 private _totalBattles = 0;
    Battle[] battles;

    modifier EligibleMonsters(uint16[] memory playerMonsters) {
        require(playerMonsters.length > 0, "PL2");
        require(playerMonsters.length < 5, "PL3");
        _;
    }

    function startBattle(
        uint16[] memory playerMonsters
    ) public EligibleMonsters(playerMonsters) {
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
        emit BattleCreated(msg.sender, address(0), _totalBattles - 1);
        _totalBattles++;
    }

    function joinBattle(
        address otherPlayer,
        uint16[] memory playerMonsters
    ) public EligibleMonsters(playerMonsters) {
        require(otherPlayer != address(0), "PL4");

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
        emit BattleCreated(msg.sender, otherPlayer, _totalBattles - 1);
        _totalBattles++;
    }

    function useSkill(
        uint256 battleIndex,
        uint16 attackerId,
        uint16 targetId,
        uint8 skillId
    ) public {
        require(battleIndex < _totalBattles, "BL1");
        require(msg.sender == ownerOf(attackerId), "PL1");
        Battle storage battle = battles[battleIndex];
        require(battle.battleStatus == BattleStatus.STARTED, "BL2");
        require(
            battle.players[0] == msg.sender || battle.players[1] == msg.sender,
            "BL3"
        );

        bool currentPlayerTurn = msg.sender == battle.players[0] ? true : false;

        require(currentPlayerTurn == battle.firstPlayersTurn, "BL4");

        uint16[] memory allyMonsters = currentPlayerTurn
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
        require(isValidAttacker, "BL5");

        Monster memory attacker = monsters[attackerId];
        // Check if the attacker is defeated
        require(attacker.health > 0, "BL6");
        require(skillId < attacker.cooldowns.length, "BL10");

        Skill memory skill = attacker.monsterType.skillSet[skillId];
        // Check if skill cooldown is expired
        require(block.timestamp >= attacker.cooldowns[skillId], "BL7");

        uint16[] memory enemyMonsters = currentPlayerTurn
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
            require(isValidAlly, "BL8");
        } else {
            // Check if targetId is an element of the targetMonsters array
            bool isValidTarget = false;
            for (uint256 i = 0; i < enemyMonsters.length; i++) {
                if (enemyMonsters[i] == targetId) {
                    isValidTarget = true;
                    break;
                }
            }
            require(isValidTarget, "BL8");
        }

        Monster memory target = monsters[targetId];
        require(target.health > 0, "BL9");

        // Calculate damage based on skill type and value
        uint16 skillDamage = (attacker.attack * skill.multiplier) / 100;

        if (skill.skillType == SkillType.Heal) {
            // Healing skill, increase target's health
            target.health = target.health + skillDamage > target.maxHp
                ? target.maxHp
                : target.health + skillDamage;
            // Reset cooldown for heal skill
            monsters[attackerId].cooldowns[skillId] =
                uint8(block.timestamp) +
                skill.cooldown;
            emit SkillUsed(
                msg.sender,
                attackerId,
                targetId,
                SkillType.Heal,
                skillDamage
            );
            // Switch turn to the other player
            battle.firstPlayersTurn = !battle.firstPlayersTurn;
            return; // Exit early, no need to proceed further
        }

        // Apply damage to target monster's health
        target.health = target.health > skillDamage
            ? target.health - skillDamage
            : 0;

        // Update cooldown for the used skill
        monsters[attackerId].cooldowns[skillId] =
            uint8(block.timestamp) +
            skill.cooldown;

        // Check if any monsters in the opposing team are defeated
        bool allDefeated = true;
        for (uint8 i = 0; i < enemyMonsters.length; i++) {
            if (monsters[enemyMonsters[i]].health > 0) {
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
                totalLevels += monsters[enemyMonsters[i]].level;
            }
            for (uint8 i = 0; i < allyMonsters.length; i++) {
                if (monsters[allyMonsters[i]].level == MAX_LEVEL) continue;
                rewardExperience(
                    monsters[allyMonsters[i]].id,
                    (totalLevels + uint8(enemyMonsters.length) / 2) /
                        uint8(enemyMonsters.length)
                ); // Pass each ally monsters and the rounded average level of the enemies
            }
            return;
        }
        // Switch turn to the other player
        battle.firstPlayersTurn = !battle.firstPlayersTurn;
    }

    // Function to reward the player with experience based on the difficulty level of the fight and check the required amount for leveling up
    function rewardExperience(uint16 monsterId, uint8 difficultyLevel) public {
        require(
            msg.sender == ownerOf(monsterId),
            "PL1"
        );
        require(
            monsters[monsterId].level < MAX_LEVEL,
            "MT3"
        );
        //  require(
        //      difficultyLevel <= MAX_LEVEL,
        //      "Enemy level is not valid."
        //  );

        // Update the monster's experience points
        monsters[monsterId].experience += difficultyLevel;

        if (monsters[monsterId].experience >= monsters[monsterId].level * 10) {
            monsters[monsterId].level++;
            if (
                !monsters[monsterId].evolved &&
                monsters[monsterId].level >= MAX_LEVEL / 2
            ) {
                monsters[monsterId].evolved = true;
                // Get the index of the last skill in the skill set
                if (monsters[monsterId].monsterType.skillSet.length > 0) {
                    uint256 lastSkillIndex = monsters[monsterId]
                        .monsterType
                        .skillSet
                        .length - 1;
                    monsters[monsterId].cooldowns.push(
                        monsters[monsterId]
                            .monsterType
                            .skillSet[lastSkillIndex]
                            .cooldown
                    );
                }
            }
        }
    }

    /**
     * @dev _baseURI overides the Openzeppelin's ERC721 implementation which by default
     * returned an empty string for the baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
