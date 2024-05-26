const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("CryptoMon Contract", function () {
  let cryptoMon;
  let monsterTypeContract;
  let battleContract;
  let owner;
  let user1;
  let user2;
  async function cryptoMonFixture() {
    [owner, user1, user2] = await ethers.getSigners();
    // Deploy the MonsterTypeContract
    const MonsterTypeContractFactory = await ethers.getContractFactory("MonsterTypes");
    monsterTypeContract = await MonsterTypeContractFactory.deploy(await owner.getAddress());
    await monsterTypeContract.waitForDeployment();
    //console.log("MonsterTypeContract deployed to:",await monsterTypeContract.getAddress());

    // Deploy the CryptoMon contract
    const CryptoMonFactory = await ethers.getContractFactory("CryptoMon");
    cryptoMon = await CryptoMonFactory.deploy(await owner.getAddress());
    await cryptoMon.waitForDeployment();
    //console.log("CryptoMon deployed to:", await cryptoMon.getAddress());

    // Set the MonsterTypeContract address in the CryptoMon contract
    await cryptoMon.setContract(await monsterTypeContract.getAddress());
    //console.log("MonsterTypeContract address set in CryptoMon");

    // Deploy the BattleContract and pass the CryptoMon address
    const BattleFactory = await ethers.getContractFactory("MonBattle");
    battleContract = await BattleFactory.deploy(await cryptoMon.getAddress());
    await battleContract.waitForDeployment();
    //console.log("BattleContract deployed to:", await battleContract.getAddress());
    // Set the authorized contract in CryptoMon
    await cryptoMon.setBattleContract(await user1.getAddress());
    return {
      cryptoMon,
      monsterTypeContract,
      battleContract,
      owner,
      user1,
      user2,
    };
  }
  describe("Minting", function () {
    it("should mint a new monster", async function () {
      let { cryptoMon, monsterTypeContract, user1 } = await loadFixture(
        cryptoMonFixture
      );
      // Setup monster type first
      await monsterTypeContract.addMonsterType("Dragon", 100, 1000, 5, 10);
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
      let { cryptoMon, monsterTypeContract, user1 } = await loadFixture(
        cryptoMonFixture
      );
      // Assume MAX_MONSTERS is 10000 for the tests.
      // Add a single type to mint all monsters as the same type.
      await monsterTypeContract.addMonsterType("Dragon", 100, 1000, 5, 10);

      // Mint up to MAX_MONSTERS
      for (let i = 0; i < (await cryptoMon.MAX_MONSTERS()); i++) {
        await cryptoMon.connect(user1).mint();
      }

      // Attempt to mint one more should fail
      await expect(cryptoMon.connect(user1).mint()).to.be.revertedWith("M1");
    });
  });

  describe("Monster Type Management", function () {
    it("should add a new monster type", async function () {
      let { monsterTypeContract } = await loadFixture(cryptoMonFixture);
      await monsterTypeContract.addMonsterType("Dragon", 100, 1000, 5, 10);
      const mType = await monsterTypeContract.getMonsterType(0);
      expect(mType.name).to.equal("Dragon");
    });

    it("should update an existing monster type", async function () {
      let { monsterTypeContract } = await loadFixture(cryptoMonFixture);
      await monsterTypeContract.addMonsterType("Dragon", 100, 1000, 5, 10);
      await monsterTypeContract.updateMonsterType(
        0,
        "DragonX",
        150,
        1200,
        6,
        15
      );
      const mType = await monsterTypeContract.getMonsterType(0);
      expect(mType.name).to.equal("DragonX");
    });
  });

  describe("Skill Management", function () {
    it("should add a new skill", async function () {
      let { monsterTypeContract } = await loadFixture(cryptoMonFixture);
      await monsterTypeContract.addSkill("Fire Breath", 200, 0, 5);
      const skill = await monsterTypeContract.skills(0);
      expect(skill.name).to.equal("Fire Breath");
    });

    it("should update an existing skill", async function () {
      let { monsterTypeContract } = await loadFixture(cryptoMonFixture);
      await monsterTypeContract.addSkill("Fire Breath", 200, 0, 5);
      await monsterTypeContract.updateSkill(0, "Ice Breath", 0, 250, 10);
      const skill = await monsterTypeContract.skills(0);
      expect(skill.name).to.equal("Ice Breath");
    });

    it("should list skills", async function () {
      let { monsterTypeContract } = await loadFixture(cryptoMonFixture);
      await monsterTypeContract.addSkill("Fire Breath", 200, 0, 5);
      const skills = await monsterTypeContract.listSkills();
      expect(skills.length).to.be.equal(1);
    });

    it("should add a skill to a monster type", async function () {
      let { monsterTypeContract } = await loadFixture(cryptoMonFixture);
      await monsterTypeContract.addMonsterType("Dragon", 100, 1000, 5, 10);
      await monsterTypeContract.addSkill("Fire Breath", 200, 0, 5);
      await monsterTypeContract.addSkillToMonsterType(0, 0);
      const monsters = await monsterTypeContract.listMonsterTypes();
      const skillSet = monsters[0].skillSet;
      expect(skillSet.length).to.equal(1);
      expect(skillSet[0].name).to.equal("Fire Breath");
    });

    it("should remove skill from monster type", async function () {
      let { monsterTypeContract } = await loadFixture(cryptoMonFixture);
      await monsterTypeContract.addMonsterType("Dragon", 100, 1000, 5, 10);
      await monsterTypeContract.addSkill("Fire Breath", 200, 0, 5);
      await monsterTypeContract.addSkillToMonsterType(0, 0);
      await monsterTypeContract.removeSkillFromMonsterTypeByIndex(0,0,0);
      const monsters = await monsterTypeContract.listMonsterTypes();
      const skillSet = monsters[0].skillSet;
      expect(skillSet.length).to.be.equal(0);
    });
  });

  describe("Leveling System", function () {
    it("should add experience to the monster but don't level up", async function () {
      let { cryptoMon, monsterTypeContract, user1 } = await loadFixture(
        cryptoMonFixture
      );
      await monsterTypeContract.addMonsterType("Dragon", 100, 1000, 5, 10);
      await cryptoMon.connect(user1).mint();
      await cryptoMon.connect(user1).rewardExperience(0, 5);
      const monster = await cryptoMon.getMonster(0);
      expect(monster.experience).to.equal(5);
      expect(monster.level).to.be.equal(1);
    });
    it("should level up a monster", async function () {
      let { cryptoMon, monsterTypeContract, user1 } = await loadFixture(
        cryptoMonFixture
      );
      await monsterTypeContract.addMonsterType("Dragon", 100, 1000, 5, 10);
      await cryptoMon.connect(user1).mint();
      await cryptoMon.connect(user1).rewardExperience(0, 10);
      const monster = await cryptoMon.monsters(0);
      expect(monster.level).to.equal(2);
    });
    it("should not level up a monster", async function () {
      let { cryptoMon, monsterTypeContract, owner, user1 } = await loadFixture(
        cryptoMonFixture
      );
      await monsterTypeContract.addMonsterType("Dragon", 100, 1000, 5, 10);
      await cryptoMon.connect(user1).mint();
      await expect(
        cryptoMon.connect(owner).rewardExperience(0, 10)
      ).to.be.revertedWith("Not authorized");
      for (let i = 1; i < (await cryptoMon.MAX_LEVEL()); i++) {
        await cryptoMon.connect(user1).rewardExperience(0, i * 10);
      }
      await expect(
        cryptoMon.connect(user1).rewardExperience(0, 1)
      ).to.be.revertedWith("MT3");
    });
  });
  describe("Setters", function () {
    it("should set the monsters health", async function () {
      let { cryptoMon, monsterTypeContract, user1 } = await loadFixture(
        cryptoMonFixture
      );
      await monsterTypeContract.addMonsterType("Dragon", 100, 1000, 5, 10);
      await cryptoMon.connect(user1).mint();
      await cryptoMon.connect(user1).setMonsterHealth(0,950);
      const monster = await cryptoMon.getMonster(0);
      expect(monster.health).to.equal(950);
    });
    it("should not set the monster's health", async function () {
      let { cryptoMon, monsterTypeContract, user1 } = await loadFixture(
        cryptoMonFixture
      );
      await monsterTypeContract.addMonsterType("Dragon", 100, 1000, 5, 10);
      await cryptoMon.connect(user1).mint();
      await expect(cryptoMon.connect(user2).setMonsterHealth(0,950)).to.be.revertedWith(("Not authorized"));
      const monster = await cryptoMon.getMonster(0);
      expect(monster.health).to.equal(1000);
    });
    it("should set the monster's cooldowns", async function () {
      let { cryptoMon, monsterTypeContract, user1 } = await loadFixture(
        cryptoMonFixture
      );
      await monsterTypeContract.addMonsterType("Dragon", 100, 1000, 5, 10);
      await monsterTypeContract.addSkill("Fire Breath", 100, 0, 5);
      await monsterTypeContract.addSkill("Ice Breath", 150, 1, 5);
      await monsterTypeContract.addSkill("Healing Breath", 50, 2, 5);
      await monsterTypeContract.addSkillToMonsterType(0, 0);
      await monsterTypeContract.addSkillToMonsterType(0, 1);
      await monsterTypeContract.addSkillToMonsterType(0, 2);
      await cryptoMon.connect(user1).mint();
      await cryptoMon.connect(user1).setMonsterCooldowns(0,[1,3]);
      const monster = await cryptoMon.getMonster(0);
      expect(monster.cooldowns[0]).to.equal(1);
      expect(monster.cooldowns[1]).to.equal(3);
    });
    it("should not set the monster's cooldowns", async function () {
      let { cryptoMon, monsterTypeContract, user1 } = await loadFixture(
        cryptoMonFixture
      );
      await monsterTypeContract.addMonsterType("Dragon", 100, 1000, 5, 10);
      await cryptoMon.connect(user1).mint();
      await expect(cryptoMon.connect(user2).setMonsterCooldowns(0,[0])).to.be.revertedWith(("Not authorized"));
    });
  });
});
