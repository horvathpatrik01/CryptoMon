const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CryptoMon Contract", function () {
  let cryptoMon;
  let owner;
  let user1;
  let user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    const CryptoMon = await ethers.getContractFactory("CryptoMon", owner);
    cryptoMon = await CryptoMon.deploy(await owner.getAddress());
    cryptoMon.waitForDeployment();
  });

  describe("Minting", function () {
    it("should mint a new monster", async function () {
        // Setup monster type first
        await cryptoMon.addMonsterType("Dragon", 100, 50, 1000, 5, 3, 10);
        const user1Address = await user1.getAddress();
        
        await expect(cryptoMon.connect(user1).mint(0))
            .to.emit(cryptoMon, "Transfer")
            .withArgs(ethers.constants.AddressZero, user1Address, 0);

        const monster = await cryptoMon.monsters(0);

        expect(monster.level).to.equal(1);
        expect(monster.monsterType.id).to.equal(0);
    });

    it("should fail minting when MAX_MONSTERS is reached", async function () {
        // Assume MAX_MONSTERS is 10000 for the tests.
        // Add a single type to mint all monsters as the same type.
        await cryptoMon.addMonsterType("Dragon", 100, 50, 1000, 5, 3, 10);

        // Mint up to MAX_MONSTERS
        for (let i = 1; i <= 10000; i++) {
            await cryptoMon.connect(user1).mint(0); // always minting the same type for simplicity
        }

        // Attempt to mint one more should fail
        await expect(cryptoMon.connect(user1).mint(0))
            .to.be.revertedWith("Max limit of monsters reached.");
    });
});

  describe("Monster Type Management", function () {
    it("should add a new monster type", async function () {
      await cryptoMon.addMonsterType("Dragon", 100, 50, 1000, 5, 3, 10);
      const mType = await cryptoMon.monsterTypes(0);
      expect(mType.name).to.equal("Dragon");
    });

    it("should update an existing monster type", async function () {
      await cryptoMon.addMonsterType("Dragon", 100, 50, 1000, 5, 3, 10);
      await cryptoMon.updateMonsterType(0, "DragonX", 150, 75, 1200, 6, 4, 15);
      const mType = await cryptoMon.monsterTypes(0);
      expect(mType.name).to.equal("DragonX");
    });
  });

  describe("Skill Management", function () {
    beforeEach(async function () {
      await cryptoMon.addSkill("Fire Breath", 200, 0, 5);
    });

    it("should add a new skill", async function () {
      const skill = await cryptoMon.skills(0);
      expect(skill.name).to.equal("Fire Breath");
    });

    it("should update an existing skill", async function () {
      await cryptoMon.updateSkill(0, "Ice Breath", 0, 250, 10);
      const skill = await cryptoMon.skills(0);
      expect(skill.name).to.equal("Ice Breath");
    });

    it("should add a skill to a monster type", async function () {
      await cryptoMon.addMonsterType("Dragon", 100, 50, 1000, 5, 3, 10);
      await cryptoMon.addSkillToMonsterType(0, 0);
      const { skillSet } = await cryptoMon.monsterTypes(0);
      expect(skillSet.length).to.equal(1);
    });
  });

  describe("Leveling System", function () {
    it("should level up a monster", async function () {
      await cryptoMon.addMonsterType("Dragon", 100, 50, 1000, 5, 3, 10);
      await cryptoMon.connect(user1).mint(0);
      await cryptoMon.connect(owner).levelUp(0);
      const monster = await cryptoMon.monsters(0);
      expect(monster.level).to.equal(2);
    });
  });
});
