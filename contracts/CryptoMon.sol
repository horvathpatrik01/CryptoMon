// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MonsterTypes.sol";
import "hardhat/console.sol";

// Definition of a Monster
struct Monster {
    uint16 monsterId;
    MonsterType monsterType;
    uint8 level;
    uint16 experience;
    bool evolved;
    uint16 health;
    uint16 maxHp;
    uint16 attack;
    uint8[] cooldowns;
}

/**
 * @title Cryptomon: A decentralized game where players can collect, trade, and battle unique digital monsters.
 * @dev This smart contract defines the core functionality of the Cryptomon game.
 *      It includes features such as monster ownership, battle system, rewards distribution, leveling, and tournaments.
 *      The code is open-source and transparent to ensure fairness and trust in the game mechanics.
 */
contract CryptoMon is ERC721, ERC721URIStorage, Ownable {
    uint16 private _tokenId = 0;
    MonsterTypes private monsterTypeContract;
    bool private contractSet = false;
    address battleContract;

    /**
     * @dev _baseTokenURI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    string _baseTokenURI;

    uint16 public constant MAX_MONSTERS = 10; // Max number of NFTs
    uint8 public constant MAX_LEVEL = 5; // Max level of Monsters

    // Mapping from token ID to Monster attributes
    mapping(uint16 => Monster) public monsters;

    // Constructor
    constructor(
        address initialOwner
    ) ERC721("CryptoMon", "CMON") Ownable(initialOwner) {
        _baseTokenURI = "ipfs://QmWTnckbjATDxnc3ZrbA3HH1MTKeyjjZ3yccgaZeNnD3HV/";
    }

    modifier onlyAuthorized() {
        require(msg.sender == battleContract, "Not authorized");
        _;
    }

    function setContract(address _monsterTypesContract) public onlyOwner {
        monsterTypeContract = MonsterTypes(_monsterTypesContract);
        contractSet = true;
    }

    function setBattleContract(address _battleContract) public onlyOwner {
        battleContract = _battleContract;
    }

    // Minting
    function mint() public {
        require(_tokenId < MAX_MONSTERS, "M1");
        require(contractSet == true, "MonsterType Contract is not yet set.");
        uint256 allTypes = monsterTypeContract.getMonsterTypeNumber();
        require(allTypes > 0, "MT2");
        uint8 monsterTypeId = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        _tokenId
                    )
                )
            ) % allTypes
        );

        MonsterType memory monsterType = monsterTypeContract.getMonsterType(
            monsterTypeId
        );
        monsters[_tokenId].monsterId = _tokenId;
        monsters[_tokenId].level = 1;
        monsters[_tokenId].experience = 0;
        // Copy the MonsterType to the new Monster
        monsters[_tokenId].monsterType.name = monsterType.name;
        monsters[_tokenId].monsterType.id = monsterType.id;
        monsters[_tokenId].monsterType.baseAttack = monsterType.baseAttack;
        monsters[_tokenId].monsterType.baseHealth = monsterType.baseHealth;
        monsters[_tokenId].monsterType.attackGrowthPercent = monsterType
            .attackGrowthPercent;
        monsters[_tokenId].monsterType.healthGrowthPercent = monsterType
            .healthGrowthPercent;

        // Copy the skillSet array manually
        delete monsters[_tokenId].monsterType.skillSet; // Clear the existing skillSet array
        for (uint256 i = 0; i < monsterType.skillSet.length; i++) {
            monsters[_tokenId].monsterType.skillSet.push(
                monsterType.skillSet[i]
            );
        }

        if (monsterType.skillSet.length > 0) {
            for (uint8 i = 0; i < uint8(monsterType.skillSet.length - 1); i++) {
                monsters[_tokenId].cooldowns.push(
                    monsterType.skillSet[i].cooldown
                );
            }
        }
        monsters[_tokenId].health = monsterType.baseHealth;
        monsters[_tokenId].maxHp = monsterType.baseHealth;
        monsters[_tokenId].attack = monsterType.baseAttack;
        string memory uri = string.concat(monsterType.name, ".l1.png");

        _safeMint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, uri);

        _tokenId++;
    }

    function getMonster(
        uint16 _monsterId
    ) external view returns (Monster memory) {
        require(_monsterId < MAX_MONSTERS, "M1");
        return monsters[_monsterId];
    }

    function setMonsterHealth(
        uint16 _monsterId,
        uint16 _newHealth
    ) external onlyAuthorized {
        require(_monsterId < MAX_MONSTERS, "M1");
        monsters[_monsterId].health = _newHealth;
    }

    function setMonsterCooldowns(
        uint16 _monsterId,
        uint8[] memory _cooldowns
    ) external onlyAuthorized {
        // Copy the skillSet array manually
         require(_monsterId < MAX_MONSTERS, "M1");
        require(_cooldowns.length == monsters[_monsterId].cooldowns.length,"Inconsistent cooldown array size!");
        for (uint256 i = 0; i < _cooldowns.length; i++) {
            monsters[_monsterId].cooldowns[i] = _cooldowns[i];
        }
    }

    // Function to reward the player with experience based on the difficulty level of the fight and check the required amount for leveling up
    function rewardExperience(
        uint16 monsterId,
        uint8 difficultyLevel
    ) external onlyAuthorized {
        require(monsters[monsterId].level < MAX_LEVEL, "MT3");
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
