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
    uint256 private _skillId = 0;
    uint256 private _typeId = 0;

    uint16 public constant MAX_MONSTERS = 10; // Max number of NFTs
    uint8 public constant MAX_LEVEL = 5; // Max level of Monsters

    enum SkillType {
        Attack,
        Heal,
        Shield
    }

    // Definition of a Skill
    struct Skill {
        uint256 id;
        string name;
        SkillType skillType;
        uint256 value;
        uint8 cooldown;
    }

    // Definition of a MonsterType
    struct MonsterType {
        string name;
        uint256 id;
        Skill[] skillSet;
        uint256 baseAttack;
        uint256 baseDefense;
        uint256 baseHealth;
        uint256 attackGrowthPercent; // Attack points added per level
        uint256 defenseGrowthPercent; // Defense points added per level
        uint256 healthGrowthPercent; // Health points added per level
    }

    // Definition of a Monster
    struct Monster {
        uint16 id;
        MonsterType monsterType;
        uint8 level;
        uint16 experience;
        string uri; // for picture for example
    }

    // Mapping from token ID to Monster attributes
    mapping(uint16 => Monster) public monsters;

    // Mapping from monsterType ID to MonsterType struct
    mapping(uint256 => MonsterType) public monsterTypes;

    // Mapping from monsterType ID to an array of Skills
    mapping(uint256 => Skill) public skills;

    // Constructor
    constructor(
        address initialOwner
    ) ERC721("CryptoMon", "CMON") Ownable(initialOwner) {}

    // Minting
    function mint() public {
        require(_tokenId < MAX_MONSTERS, "Max limit of monsters reached.");
        require(_typeId > 0, "There are no monster types");
        uint256 monsterTypeId = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.prevrandao, _tokenId)
            )
        ) % _typeId;
        Monster storage monster = monsters[_tokenId];
        monsters[_tokenId].id = _tokenId;
        monsters[_tokenId].level = 1;
        monsters[_tokenId].experience = 0;
        monsters[_tokenId].uri = "default";
        monsters[_tokenId].monsterType = monsterTypes[monsterTypeId];

        _safeMint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, monster.uri);

        _tokenId++;
    }

    // Function to list all monster types and their associated skills
    function listMonsterTypes() public view returns (MonsterType[] memory) {
        uint256 totalTypes = _typeId;
        MonsterType[] memory localmonsterTypes = new MonsterType[](totalTypes);
        for (uint256 i; i < totalTypes; i++) {
            localmonsterTypes[i] = monsterTypes[i];
        }

        return localmonsterTypes;
    }

    // modifier to check inputs
    modifier monsterTypeExists(uint256 typeId){
        require(
            (bytes(monsterTypes[typeId].name).length) > 0,
            "This type of monster does not exist."
        );
        _;
    }

    // Function to add a new type of monster
    function addMonsterType(
        string memory name,
        uint256 baseAttack,
        uint256 baseDefense,
        uint256 baseHealth,
        uint256 attackGrowthPercent,
        uint256 defenseGrowthPercent,
        uint256 healthGrowthPercent
    ) public onlyOwner{
        require(baseAttack > 0, "BaseAttack must be greater than zero!");
        require(baseDefense > 0, "BaseDefense must be greater than zero!");
        require(baseHealth > 0, "BaseHealth must be greater than zero!");
        require(
            attackGrowthPercent > 0,
            "AttackGrowthPercent must be greater than zero!"
        );
        require(
            defenseGrowthPercent > 0,
            "DefenseGrowthPercent must be greater than zero!"
        );
        require(
            healthGrowthPercent > 0,
            "HealthGrowthPercent must be greater than zero!"
        );
        require(bytes(name).length > 0, "Name cannot be empty.");
        // New monsterType
        monsterTypes[_typeId].id = _typeId;
        monsterTypes[_typeId].name = name;
        monsterTypes[_typeId].baseAttack = baseAttack;
        monsterTypes[_typeId].baseDefense = baseDefense;
        monsterTypes[_typeId].baseHealth = baseHealth;
        monsterTypes[_typeId].attackGrowthPercent = attackGrowthPercent;
        monsterTypes[_typeId].defenseGrowthPercent = defenseGrowthPercent;
        monsterTypes[_typeId].healthGrowthPercent = healthGrowthPercent;
        // Auto-increment the skill ID
        _typeId++;
    }

    // Function to update a type of monster
    function updateMonsterType(
        uint256 typeId,
        string memory name,
        uint256 baseAttack,
        uint256 baseDefense,
        uint256 baseHealth,
        uint256 attackGrowthPercent,
        uint256 defenseGrowthPercent,
        uint256 healthGrowthPercent
    ) public onlyOwner monsterTypeExists(typeId){
        require(baseAttack > 0, "BaseAttack must be greater than zero!");
        require(baseDefense > 0, "BaseDefense must be greater than zero!");
        require(baseHealth > 0, "BaseHealth must be greater than zero!");
        require(
            attackGrowthPercent > 0,
            "AttackGrowthPercent must be greater than zero!"
        );
        require(
            defenseGrowthPercent > 0,
            "DefenseGrowthPercent must be greater than zero!"
        );
        require(
            healthGrowthPercent > 0,
            "HealthGrowthPercent must be greater than zero!"
        );
        require(bytes(name).length > 0, "Name cannot be empty.");

        // Update the type of monster
        monsterTypes[typeId].name = name;
        monsterTypes[typeId].baseAttack = baseAttack;
        monsterTypes[typeId].baseDefense = baseDefense;
        monsterTypes[typeId].baseHealth = baseHealth;
        monsterTypes[typeId].attackGrowthPercent = attackGrowthPercent;
        monsterTypes[typeId].defenseGrowthPercent = defenseGrowthPercent;
        monsterTypes[typeId].healthGrowthPercent = healthGrowthPercent;
    }

    // Function to add a new skill to a MonsterType
    function addSkillToMonsterType(
        uint256 typeId,
        uint256 skillId
    ) public onlyOwner monsterTypeExists(typeId){
        require(
            (bytes(skills[skillId].name).length) > 0,
            "This skill does not exist."
        );

        // Add the new skill to the monsterType
        monsterTypes[typeId].skillSet.push(skills[skillId]);
    }

    // Function to remove a skill from a monsterType
    function removeSkillFromMonsterTypeByIndex(
        uint256 typeId,
        uint256 skillId,
        uint256 index
    ) public onlyOwner monsterTypeExists(typeId){
        require(
            (bytes(skills[skillId].name).length) > 0,
            "This skill does not exist."
        );

        // Swap the skill to be removed with the last skill in the array
        monsterTypes[typeId].skillSet[index] = monsterTypes[typeId].skillSet[
            monsterTypes[typeId].skillSet.length - 1
        ];

        // Remove the last skill (which is now the skill that needed to be removed or is a duplicate of the last one if index pointed to the last one)
        monsterTypes[typeId].skillSet.pop();
    }

    // // Function to list all skills
    function listSkills() public view returns (Skill[] memory) {
        uint256 totalSkills = _skillId;
        Skill[] memory localSkills = new Skill[](totalSkills);
        for (uint256 i; i < totalSkills; i++) {
            localSkills[i] = skills[i];
        }
        return localSkills;
    }

    // Function to add a new skill
    function addSkill(
        string memory name,
        uint256 value,
        SkillType skillType,
        uint8 cooldown
    ) public onlyOwner {
        require(value > 0, "Value must be greater than zero.");
        require(bytes(name).length > 0, "Name cannot be empty.");
        require(cooldown > 0, "Cooldown must be greater than zero.");

        // Add the new skill to the mapping
        skills[_skillId] = Skill({
            id: _skillId,
            name: name,
            skillType: skillType,
            value: value,
            cooldown: cooldown
        });
        // Auto-increment the skill ID
        _skillId++;
    }

    // Function to update an existing skill
    function updateSkill(
        uint256 skillId,
        string memory name,
        uint256 skillTypeId,
        uint256 value,
        uint8 cooldown
    ) public onlyOwner {
        require(value > 0, "Value must be greater than zero.");
        require(bytes(name).length > 0, "Name cannot be empty.");
        require(cooldown > 0, "Cooldown must be greater than zero.");
        require(
            (bytes(skills[skillId].name).length) > 0,
            "This skill does not exist."
        );

        // Cast uint256 to SkillType enum
        SkillType skillType = SkillType(skillTypeId);

        skills[skillId].name = name;
        skills[skillId].value = value;
        skills[skillId].cooldown = cooldown;
        skills[skillId].skillType = skillType;
    }

    // Function to reward the player with experience based on the difficulty level of the fight and check the required amount for leveling up
    function rewardExperience(uint16 monsterId, uint8 difficultyLevel) public {
        require(
            msg.sender == ownerOf(monsterId),
            "You don't own this monster."
        );
        require(
            monsters[monsterId].level < MAX_LEVEL,
            "Monster is already at max level."
        );
        //  require(
        //      difficultyLevel <= MAX_LEVEL,
        //      "Enemy level is not valid."
        //  );

        // Calculate the amount of experience to be rewarded based on the difficulty level
        uint16 experienceReward = calculateExperienceReward(difficultyLevel);

        // Update the monster's experience points
        monsters[monsterId].experience += experienceReward;

        // Check if the monster should level up after receiving the experience reward

        uint16 requiredExperience = experienceRequiredForLevel(
            monsters[monsterId].level
        );
        if (monsters[monsterId].experience >= requiredExperience) {
            monsters[monsterId].level++;
        }
    }

    // Function to calculate required experience points for a specific level
    function experienceRequiredForLevel(
        uint8 level
    ) private pure returns (uint16) {
        return level * 10;
    }

    // Function to calculate the amount of experience to be rewarded based on the difficulty level
    function calculateExperienceReward(
        uint8 difficultyLevel
    ) private pure returns (uint16) {
        return difficultyLevel; // Reward difficulty level amount of experience points
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
