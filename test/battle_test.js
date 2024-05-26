const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Battle Contract", function () {
  let cryptoMon;
  let monsterTypeContract;
  let battleContract;
  let owner;
  let user1;
  let user2;
  async function BattleContractFixture() {
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
    //console.log("BattleContract deployed to:",await battleContract.getAddress());

    // Set the authorized contract in CryptoMon
    await cryptoMon.setBattleContract(await battleContract.getAddress());

    return {
      cryptoMon,
      monsterTypeContract,
      battleContract,
      owner,
      user1,
      user2,
    };
  }

  describe("Combat System", function () {
    it("should createand join to a random battle", async function () {
      let { cryptoMon, battleContract, user1 } = await loadFixture(
        BattleContractFixture
      );
      const user1Address = await user1.getAddress();
      const user2Address = await user2.getAddress();

      const addressZero = "0x0000000000000000000000000000000000000000";
      cryptoMon.connect(user1).mint();
      cryptoMon.connect(user2).mint();
      await expect(battleContract.connect(user1).startBattle([0]))
        .to.emit(battleContract, "BattleCreated")
        .withArgs(user1Address, addressZero, 0);
      await expect(battleContract.connect(user2).startBattle([1]))
        .to.emit(battleContract, "BattleCreated")
        .withArgs(user1Address, user2Address, 0);
    });

    it("should create and join to a private battle", async function () {
      let { cryptoMon, monsterTypeContract, battleContract, user1, user2 } =
        await loadFixture(BattleContractFixture);
      const user1Address = await user1.getAddress();
      const user2Address = await user2.getAddress();
      cryptoMon.connect(user1).mint();
      cryptoMon.connect(user2).mint();
      await expect(battleContract.connect(user1).joinBattle(user2Address, [0]))
        .to.emit(battleContract, "BattleCreated")
        .withArgs(user1Address, user2Address, 0);
      await expect(battleContract.connect(user2).joinBattle(user1Address, [1]))
        .to.emit(battleContract, "BattleCreated")
        .withArgs(user1Address, user2Address, 0);
    });

    it("should revert because wrong number of monsters", async function () {
      let { cryptoMon, monsterTypeContract, battleContract, user1, user2 } =
        await loadFixture(BattleContractFixture);
      await expect(
        battleContract.connect(user1).startBattle([])
      ).to.be.revertedWith(
        "You must have at least one monster to start a battle"
      );
      await expect(
        battleContract.connect(user1).startBattle([0, 1, 2, 3, 4, 5])
      ).to.be.revertedWith(
        "A maximum of 4 monsters can participate in a battle"
      );
    });
  });

  describe("useSkill", function () {
    it("should use a skill correctly and switch turn", async function () {
      let { cryptoMon, monsterTypeContract, battleContract, user1, user2 } =
        await loadFixture(BattleContractFixture);
      // Add monsters to players
      await monsterTypeContract.addMonsterType("Dragon", 10, 100, 5, 10);
      await monsterTypeContract.addSkill("Fire Breath", 100, 0, 0);
      await monsterTypeContract.addSkill("Ice Breath", 150, 1, 1);
      await monsterTypeContract.addSkill("Healing Breath", 50, 2, 2);
      await monsterTypeContract.addSkillToMonsterType(0, 0);
      await monsterTypeContract.addSkillToMonsterType(0, 1);
      await monsterTypeContract.addSkillToMonsterType(0, 2);

      await cryptoMon.connect(user1).mint();
      await cryptoMon.connect(user2).mint();
      // Create a battle
      await battleContract.connect(user1).startBattle([0]);
      await battleContract.connect(user2).startBattle([1]);

      // Use a skill
      await expect(battleContract.connect(user1).useSkill(0, 0, 1, 0)) // battleIndex, attackerId, targetId, skillId
        .to.emit(battleContract, "SkillUsed")
        .withArgs(await user1.getAddress(), 0, 1, 0, 10); //msg.sender,attackerId,targetId,skill.skillType,skillDamage

      // Check the skill usage results
      let attacker = await cryptoMon.getMonster(0);
      let target = await cryptoMon.getMonster(1);

      expect(attacker.health).to.be.equal(100);
      expect(target.health).to.be.equal(90);

      // Check that the same player cannot use a skill out of turn
      await expect(
        battleContract.connect(user1).useSkill(0, 0, 1, 0)
      ).to.be.revertedWith("It's not your turn");

      // Use a skill
      await expect(battleContract.connect(user2).useSkill(0, 1, 0, 0)) // battleIndex, attackerId, targetId, skillId
        .to.emit(battleContract, "SkillUsed")
        .withArgs(await user2.getAddress(), 1, 0, 0, 10); //msg.sender,attackerId,targetId,skill.skillType,skillDamage

      // Check the skill usage results
      attacker = await cryptoMon.getMonster(1);
      target = await cryptoMon.getMonster(0);
      expect(attacker.health).to.be.equal(90);
      expect(target.health).to.be.equal(90);
    });

    it("should end the battle and declare a winner when all opponents are defeated", async function () {
      let { cryptoMon, monsterTypeContract, battleContract, user1, user2 } =
        await loadFixture(BattleContractFixture);
      // Add monsters to players
      await monsterTypeContract.addMonsterType("Dragon", 10, 15, 5, 10); // name, baseAttack, baseHealth, attackGrowthPercent, healthGrowthPercent
      await monsterTypeContract.addSkill("Fire Breath", 100, 0, 0); // name, dmgmultiplier, skilltype, cooldown
      await monsterTypeContract.addSkill("Ice Breath", 150, 1, 0);
      await monsterTypeContract.addSkill("Healing Breath", 50, 2, 2);
      await monsterTypeContract.addSkillToMonsterType(0, 0);
      await monsterTypeContract.addSkillToMonsterType(0, 1);
      await monsterTypeContract.addSkillToMonsterType(0, 2);

      await cryptoMon.connect(user1).mint();
      await cryptoMon.connect(user2).mint();
      // Create a battle
      await battleContract.connect(user1).startBattle([0]);
      await battleContract.connect(user2).startBattle([1]);

      // Use a skill
      await expect(battleContract.connect(user1).useSkill(0, 0, 1, 0)) // battleIndex, attackerId, targetId, skillId
        .to.emit(battleContract, "SkillUsed")
        .withArgs(await user1.getAddress(), 0, 1, 0, 10); //msg.sender,attackerId,targetId,skill.skillType,skillDamage

      // Check the skill usage results
      let attacker = await cryptoMon.getMonster(0);
      let target = await cryptoMon.getMonster(1);

      expect(attacker.health).to.be.equal(15);
      expect(target.health).to.be.equal(5);

      // Use a skill
      await expect(battleContract.connect(user2).useSkill(0, 1, 0, 1)) // battleIndex, attackerId, targetId, skillId
        .to.emit(battleContract, "SkillUsed")
        .withArgs(await user2.getAddress(), 1, 0, 1, 15)//msg.sender,attackerId,targetId,skill.skillType,skillDamage
        .and.to.emit(battleContract, "BattleEnded")
        .withArgs(await user2.getAddress(),0); //winner, battleIndex

      // Check the skill usage results
      attacker = await cryptoMon.getMonster(1); // now the user2's monster is the attacker
      target = await cryptoMon.getMonster(0);
      expect(attacker.health).to.be.equal(5);
      expect(target.health).to.be.equal(0);
      expect(attacker.experience).to.be.above(0);
    });
  });
});
