const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { any } = require("hardhat/internal/core/params/argumentTypes");

describe("CryptoMon Contract", function () {
  let cryptoMon;
  let owner;
  let user1;
  let user2;
  async function cryptoMonFixture() {
    [owner, user1, user2] = await ethers.getSigners();
    cryptoMon = await hre.ethers.deployContract("CryptoMon", [
      await owner.getAddress(),
    ]);

    return { cryptoMon, owner, user1, user2 };
  }
  describe("Minting", function () {
    it("should mint a new monster", async function () {
      let {cryptoMon,user1} = await loadFixture(cryptoMonFixture);
      // Setup monster type first
      await cryptoMon.addMonsterType("Dragon", 100, 50, 1000, 5, 3, 10);
      const user1Address = await user1.getAddress();
      const addressZero = "0x0000000000000000000000000000000000000000";

      await expect(cryptoMon.connect(user1).mint())
        .to.emit(cryptoMon, "Transfer")
        .withArgs(addressZero, user1Address, 0);

      const monster = await cryptoMon.monsters(0);

      expect(monster.level).to.equal(1);
      expect(monster.monsterType.name).to.equal("Dragon");
    });

    it("should fail minting when MAX_MONSTERS is reached", async function () {
      let {cryptoMon, user1} = await loadFixture(cryptoMonFixture);
      // Assume MAX_MONSTERS is 10000 for the tests.
      // Add a single type to mint all monsters as the same type.
      await cryptoMon.addMonsterType("Dragon", 100, 50, 1000, 5, 3, 10);

      // Mint up to MAX_MONSTERS
      for (let i = 0; i < await cryptoMon.MAX_MONSTERS(); i++) {
        await cryptoMon.connect(user1).mint();
      }

      // Attempt to mint one more should fail
      await expect(cryptoMon.connect(user1).mint()).to.be.revertedWith(
        "Max limit of monsters reached."
      );
    });
  });

  describe("Monster Type Management", function () {
    it("should add a new monster type", async function () {
      let {cryptoMon} = await loadFixture(cryptoMonFixture);
      await cryptoMon.addMonsterType("Dragon", 100, 50, 1000, 5, 3, 10);
      const mType = await cryptoMon.monsterTypes(0);
      expect(mType.name).to.equal("Dragon");
    });

    it("should update an existing monster type", async function () {
      let {cryptoMon} = await loadFixture(cryptoMonFixture);
      await cryptoMon.addMonsterType("Dragon", 100, 50, 1000, 5, 3, 10);
      await cryptoMon.updateMonsterType(0, "DragonX", 150, 75, 1200, 6, 4, 15);
      const mType = await cryptoMon.monsterTypes(0);
      expect(mType.name).to.equal("DragonX");
    });
  });

  describe("Skill Management", function () {
    it("should add a new skill", async function () {
      let {cryptoMon} = await loadFixture(cryptoMonFixture);
      await cryptoMon.addSkill("Fire Breath", 200, 0, 5);
      const skill = await cryptoMon.skills(0);
      expect(skill.name).to.equal("Fire Breath");
    });

    it("should update an existing skill", async function () {
      let {cryptoMon} = await loadFixture(cryptoMonFixture);
      await cryptoMon.addSkill("Fire Breath", 200, 0, 5);
      await cryptoMon.updateSkill(0, "Ice Breath", 0, 250, 10);
      const skill = await cryptoMon.skills(0);
      expect(skill.name).to.equal("Ice Breath");
    });

    it("should list skills", async function () {
      let {cryptoMon} = await loadFixture(cryptoMonFixture);
      await cryptoMon.addSkill("Fire Breath", 200, 0, 5);
      const skills = await cryptoMon.listSkills();
      console.log("Skills: %s", typeof skills);
      expect(skills.length).to.be.equal(1);
    });

    it("should add a skill to a monster type", async function () {
      let {cryptoMon} = await loadFixture(cryptoMonFixture);
      await cryptoMon.addMonsterType("Dragon", 100, 50, 1000, 5, 3, 10);
      await cryptoMon.addSkill("Fire Breath", 200, 0, 5);
      await cryptoMon.addSkillToMonsterType(0, 0);
      const  monsters  = await cryptoMon.listMonsterTypes();
      console.log("Should add skill \n MonsterTypes: %d", monsters.length);
      const skillSet = monsters[0].skillSet
      console.log(skillSet);
      expect(skillSet.length).to.equal(1);
      expect(skillSet[0].name).to.equal("Fire Breath");
    });
  });

  describe("Leveling System", function () {
    it("should add experience to the monster but don't level up", async function () {
      let {cryptoMon, user1} = await loadFixture(cryptoMonFixture);
      await cryptoMon.addMonsterType("Dragon", 100, 50, 1000, 5, 3, 10);
      await cryptoMon.connect(user1).mint();
      await cryptoMon.connect(user1).rewardExperience(0,5);
      const monster = await cryptoMon.monsters(0);
      expect(monster.experience).to.equal(5);
      expect(monster.level).to.be.equal(1);
    });
    it("should level up a monster", async function () {
      let {cryptoMon, owner, user1} = await loadFixture(cryptoMonFixture);
      await cryptoMon.addMonsterType("Dragon", 100, 50, 1000, 5, 3, 10);
      await cryptoMon.connect(user1).mint();
      await cryptoMon.connect(user1).rewardExperience(0,10);
      const monster = await cryptoMon.monsters(0);
      expect(monster.level).to.equal(2);
    });
    it("should not level up a monster", async function () {
      let {cryptoMon, owner, user1} = await loadFixture(cryptoMonFixture);
      await cryptoMon.addMonsterType("Dragon", 100, 50, 1000, 5, 3, 10);
      await cryptoMon.connect(user1).mint();
      await expect(cryptoMon.connect(owner).rewardExperience(0,10)).to.be.revertedWith("You don't own this monster.");
      for(let i =1; i< await cryptoMon.MAX_LEVEL();i++){
        await cryptoMon.connect(user1).rewardExperience(0,i*10);
      }
      await expect(cryptoMon.connect(user1).rewardExperience(0,1)).to.be.revertedWith("Monster is already at max level.");
    });
  });

  describe("Combat System", function () {
    it.skip("should level up a monster", async function () {
    });
    it.skip("should not level up a monster", async function () {
    });
  });
});
