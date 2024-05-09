// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoMon is ERC721, ERC721URIStorage, Ownable {
    uint256 private _tokenId = 0;
    uint256 private _skillId = 0;
    uint256 private _typeId = 0;


    uint256 public constant MAX_MONSTERS = 10000;  // Max number of NFTs
    uint8 public constant MAX_LEVEL = 100;         // Max level of Monsters

    enum SkillType { Attack, Heal, Shield, Stun}

    // Definition of a Skill
    struct Skill {
    uint256 id;
    string name;
    SkillType skillType;
    uint256 value; 
    uint256  cooldown;
    }

    // Definition of a MonsterType
    struct MonsterType{
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
        uint256 id;
        MonsterType monsterType;
        uint8 level;
        string uri; // for picture for example
    }

    // Mapping from token ID to Monster attributes
    mapping(uint256 => Monster) public monsters;

    // Mapping from monsterType ID to MonsterType struct
    mapping(uint256 => MonsterType) public monsterTypes;

    // Mapping from monsterType ID to an array of Skills
    mapping(uint256 => Skill) public skills;

    // Constructor
    constructor(address initialOwner) ERC721("CryptoMon","CMON") Ownable(initialOwner) {}

    // Function to add a new type of monster
    function addMonsterType(
        string memory name,
        uint256 baseAttack,
        uint256 baseDefense,
        uint256 baseHealth,
        uint256 attackGrowthPercent,
        uint256 defenseGrowthPercent,
        uint256 healthGrowthPercent
        )
        public onlyOwner {
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
        string  memory name,
        uint256 baseAttack, 
        uint256 baseDefense, 
        uint256 baseHealth,
        uint256 attackGrowthPercent,
        uint256 defenseGrowthPercent,
        uint256 healthGrowthPercent
        ) 
        public onlyOwner {
            require(baseAttack > 0, "BaseAttack must be greater than zero!");
            require(baseDefense> 0, "BaseDefense must be greater than zero!");
            require(baseHealth> 0, "BaseHealth must be greater than zero!");
            require(attackGrowthPercent > 0, "AttackGrowthPercent must be greater than zero!");
            require(defenseGrowthPercent > 0, "DefenseGrowthPercent must be greater than zero!");
            require(healthGrowthPercent > 0, "HealthGrowthPercent must be greater than zero!");
            require(bytes(name).length > 0 , "Name cannot be empty.");
            require((bytes(monsterTypes[typeId].name).length) > 0, "This type of monster does not exist.");

            // Update the type of monster
            monsterTypes[typeId].name = name;
            monsterTypes[typeId].baseAttack = baseAttack;
            monsterTypes[typeId].baseDefense = baseDefense;
            monsterTypes[typeId].baseHealth = baseHealth;
            monsterTypes[typeId].attackGrowthPercent = attackGrowthPercent;
            monsterTypes[typeId].defenseGrowthPercent = defenseGrowthPercent;
            monsterTypes[typeId].healthGrowthPercent = healthGrowthPercent;
    }

    // Function to list all skills
    function listSkills() public view returns (uint256[] memory,string[] memory, SkillType[] memory,uint256[] memory, uint256[] memory) {
        uint256 totalSkills = _skillId;
        uint256[] memory ids = new uint256[](totalSkills);
        string[] memory names = new string[](totalSkills);
        SkillType[] memory skilltypes = new SkillType[](totalSkills);
        uint256[] memory values = new uint256[](totalSkills);
        uint256[] memory cooldowns = new uint256[](totalSkills);

        for (uint256 i = 1; i <= totalSkills; i++) {
            Skill storage skill = skills[i];
            ids[i - 1] = skill.id;
            names[i - 1] = skill.name;
            skilltypes[i - 1] = skill.skillType;
            values[i - 1] = skill.value;
            cooldowns[i - 1] = skill.cooldown;
        }
        return (ids, names, skilltypes, values, cooldowns);
    }

    // Function to add a new skill
    function addSkill(
        string memory name, 
        uint256 value, 
        SkillType skillType,
        uint256 cooldown
        ) 
        public onlyOwner {
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
        uint256 cooldown
        ) 
        public onlyOwner {
            require(value > 0, "Value must be greater than zero.");
            require(bytes(name).length > 0, "Name cannot be empty.");
            require(cooldown > 0, "Cooldown must be greater than zero.");
            require((bytes(skills[skillId].name).length) > 0, "This skill does not exist.");

            // Cast uint256 to SkillType enum
            SkillType skillType = SkillType(skillTypeId);

            skills[skillId].name = name;
            skills[skillId].value=value;
            skills[skillId].cooldown=cooldown;
            skills[skillId].skillType=skillType;
    }

    // Function to list all monster types and their associated skills
    function listMonsterTypes() public view returns (uint256[] memory,string[] memory, uint256[][] memory) {
        uint256 totalTypes = _typeId;
        string[] memory names = new string[](totalTypes);
        uint256[] memory ids = new uint256[](totalTypes);
        uint256[][] memory skillIds = new uint256[][](totalTypes);

        for (uint256 i = 1; i <= totalTypes; i++) {
            MonsterType storage mType = monsterTypes[i];
            names[i - 1] = mType.name;
            ids[i - 1] = mType.id;
            skillIds[i - 1] = new uint256[](mType.skillSet.length);
            for (uint256 j = 0; j < mType.skillSet.length; j++) {
                skillIds[i - 1][j] = mType.skillSet[j].id;
            }
        }
        return (ids, names, skillIds);
    }

    // Function to add a new skill to a MonsterType
    function addSkillToMonsterType(
        uint256 typeId, 
        uint256 skillId
        ) 
        public onlyOwner {
            require((bytes(monsterTypes[typeId].name).length) > 0, "This type of monster does not exist.");
            require((bytes(skills[skillId].name).length) > 0, "This skill does not exist.");
            
            // Add the new skill to the monsterType
            monsterTypes[typeId].skillSet.push(skills[skillId]);
    }

    // Function to remove a skill from a monsterType
    function removeSkillFromMonsterTypeByIndex(
        uint256 typeId, 
        uint256 skillId,
        uint256 index
        ) 
        public onlyOwner {
            require((bytes(monsterTypes[typeId].name).length) > 0, "This type of monster does not exist.");
            require((bytes(skills[skillId].name).length) > 0, "This skill does not exist.");
            
            // Swap the skill to be removed with the last skill in the array
            monsterTypes[typeId].skillSet[index] = monsterTypes[typeId].skillSet[monsterTypes[typeId].skillSet.length - 1];

            // Remove the last skill (which is now the skill that needed to be removed or is a duplicate of the last one if index pointed to the last one)
            monsterTypes[typeId].skillSet.pop();
    }

    // Minting
    function mint(
        uint256 monsterTypeId
    ) public {
        require(_tokenId < MAX_MONSTERS, "Max limit of monsters reached.");

        Monster storage monster = monsters[_tokenId];
        monsters[_tokenId].id=_tokenId;
        monsters[_tokenId].level=1;
        monsters[_tokenId].uri="default";
        monsters[_tokenId].monsterType = monsterTypes[monsterTypeId];

        _safeMint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, monster.uri);

        emit Transfer(address(0), msg.sender, _tokenId);

        _tokenId++;
    }

    // Function to remove a skill from a monsterType
    function levelUp(
        uint256 monsterId
        ) 
        public onlyOwner {
            require(monsters[monsterId].level <= MAX_LEVEL, "Monster is at max level.");
            monsters[monsterId].level++;
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
