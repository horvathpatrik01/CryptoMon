// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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
        uint16 multiplier; // Percent
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
/**
 * @title Cryptomon: A decentralized game where players can collect, trade, and battle unique digital monsters.
 * @dev This smart contract defines the core functionality of the Cryptomon game.
 *      It includes features such as monster ownership, battle system, rewards distribution, leveling, and tournaments.
 *      The code is open-source and transparent to ensure fairness and trust in the game mechanics.
 */
contract MonsterTypes is Ownable{
    uint8 private _skillId;
    uint8 private _typeId;

    // Mapping from monsterType ID to MonsterType struct
    mapping(uint8 => MonsterType) public monsterTypes;

    // Mapping from monsterType ID to an array of Skills
    mapping(uint8 => Skill) public skills;

    // Constructor
    constructor(
        address initialOwner
    ) Ownable(initialOwner) {
        _skillId = 0;
        _typeId = 0;
    }
    function getMonsterTypeNumber() public view returns (uint8){
        return _typeId;
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
        require(
            (bytes(monsterTypes[typeId].name).length) > 0,
            "This type of monster does not exist."
        );
        _;
    }

    function getMonsterType(uint8 _monsterTypeId) public view  monsterTypeExists(_monsterTypeId) returns (MonsterType memory){
        require(_monsterTypeId < _typeId, "M1" );
        return monsterTypes[_monsterTypeId];
    }


    // Function to add a new type of monster
    function addMonsterType(
        string memory name,
        uint16 baseAttack,
        uint16 baseHealth,
        uint16 attackGrowthPercent,
        uint16 healthGrowthPercent
    ) public onlyOwner {
        require(baseAttack > 0, "BaseAttack must be greater than zero!");
        require(baseHealth > 0, "BaseHealth must be greater than zero!");
        require(
            attackGrowthPercent > 0,
            "AttackGrowthPercent must be greater than zero!"
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
        require(baseAttack > 0, "BaseAttack must be greater than zero!");
        require(baseHealth > 0, "BaseHealth must be greater than zero!");
        require(
            attackGrowthPercent > 0,
            "AttackGrowthPercent must be greater than zero!"
        );
        require(
            healthGrowthPercent > 0,
            "HealthGrowthPercent must be greater than zero!"
        );
        require(bytes(name).length > 0, "Name cannot be empty.");

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
        require(
            (bytes(skills[skillId].name).length) > 0,
            "This skill does not exist."
        );

        // Add the new skill to the monsterType
        monsterTypes[typeId].skillSet.push(skills[skillId]);
    }

    // TODO: test
    // Function to remove a skill from a monsterType
    function removeSkillFromMonsterTypeByIndex(
        uint8 typeId,
        uint8 skillId,
        uint256 index
    ) public onlyOwner monsterTypeExists(typeId) {
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
        require(multiplierValue > 0, "Value must be greater than zero.");
        require(bytes(name).length > 0, "Name cannot be empty.");
        require(cooldown > 0, "Cooldown must be greater than zero.");

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
        require(multiplierValue > 0, "Value must be greater than zero.");
        require(bytes(name).length > 0, "Name cannot be empty.");
        require(cooldown > 0, "Cooldown must be greater than zero.");
        require(
            (bytes(skills[skillId].name).length) > 0,
            "This skill does not exist."
        );

        // Cast uint8 to SkillType enum
        SkillType skillType = SkillType(skillTypeId);

        skills[skillId].name = name;
        skills[skillId].multiplier = multiplierValue;
        skills[skillId].cooldown = cooldown;
        skills[skillId].skillType = skillType;
    }
}
