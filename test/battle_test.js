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
    const MonsterTypeContractFactory = await ethers.getContractFactory(
      "MonsterTypes"
    );
    monsterTypeContract = await MonsterTypeContractFactory.deploy(
      await owner.getAddress()
    );
    await monsterTypeContract.waitForDeployment();
    console.log(
      "MonsterTypeContract deployed to:",
      await monsterTypeContract.getAddress()
    );

    // Deploy the CryptoMon contract
    const CryptoMonFactory = await ethers.getContractFactory("CryptoMon");
    cryptoMon = await CryptoMonFactory.deploy(await owner.getAddress());
    await cryptoMon.waitForDeployment();
    console.log("CryptoMon deployed to:", await cryptoMon.getAddress());

    // Set the MonsterTypeContract address in the CryptoMon contract
    await cryptoMon.setContract(await monsterTypeContract.getAddress());
    console.log("MonsterTypeContract address set in CryptoMon");

    // Deploy the BattleContract and pass the CryptoMon address
    const BattleFactory = await ethers.getContractFactory("MonBattle");
    battleContract = await BattleFactory.deploy(await cryptoMon.getAddress());
    await battleContract.waitForDeployment();
    console.log(
      "BattleContract deployed to:",
      await battleContract.getAddress()
    );

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
        battleContract.connect(user1).startBattle([0,1,2,3,4,5])
      ).to.be.revertedWith(
        "A maximum of 4 monsters can participate in a battle"
      );
    });
  });
});
