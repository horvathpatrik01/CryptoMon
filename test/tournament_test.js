const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("TournamentManager Contract", function () {
  let cryptoMon;
  let monsterTypeContract;
  let battleContract;
  let tournamentContract;
  let owner;
  let user1;
  let user2;
  let user3;
  async function TournamentContractFixture() {
    [owner, user1, user2, user3] = await ethers.getSigners();
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

    // Deploy the BattleContract and pass the CryptoMon address
    const TournamentFactory = await ethers.getContractFactory("TournamentManager");
    tournamentContract = await TournamentFactory.deploy(await battleContract.getAddress());
    await tournamentContract.waitForDeployment();
    //console.log("TournamentContract deployed to:",await tournamentContract.getAddress());

    return {
      cryptoMon,
      monsterTypeContract,
      battleContract,
      tournamentContract,
      owner,
      user1,
      user2,
      user3,
    };
  }

  it("Should create a tournament", async function () {
    let { owner, tournamentContract } = await loadFixture(
      TournamentContractFixture
    );
    const ownerAddress = await owner.getAddress();
    await expect(tournamentContract.createTournament(4))
      .to.emit(tournamentContract, "TournamentCreated")
      .withArgs(0, ownerAddress);

    const tournament = await tournamentContract.tournaments(0);
    expect(tournament.host).to.equal(ownerAddress);
    expect(tournament.maxPlayerNum).to.equal(4);
    expect(tournament.playerNum).to.equal(0);
    expect(tournament.currentRound).to.equal(0);
    expect(tournament.tournamentStatus).to.equal(0); // PENDING
  });

  it("Should allow players to join a tournament", async function () {
    let { owner, user1, tournamentContract } = await loadFixture(
      TournamentContractFixture
    );
    const user1Address = await user1.getAddress();
    await tournamentContract.connect(owner).createTournament(4);
    await expect(tournamentContract.connect(user1).joinTournament(0))
      .to.emit(tournamentContract, "PlayerJoined")
      .withArgs(0, user1Address);

    const tournament = await tournamentContract.tournaments(0);
    const player = await tournamentContract.getPlayer(0, user1Address);
    expect(player.isEliminated).to.equal(false);
    expect(player.isInBattle).to.equal(false);
    expect(player.isReady).to.equal(false);
    expect(player.playerMonsters.length).to.equal(0);
  });

  it("Should set monsters for a player", async function () {
    let { owner, user1, tournamentContract, monsterTypeContract, cryptoMon } =
      await loadFixture(TournamentContractFixture);
    const user1Address = await user1.getAddress();
    await tournamentContract.connect(owner).createTournament(4);
    await tournamentContract.connect(user1).joinTournament(0);
    await monsterTypeContract.addMonsterType("Dragon", 10, 100, 5, 10);
    await cryptoMon.connect(user1).mint();
    await cryptoMon.connect(user1).mint();
    await cryptoMon.connect(user1).mint();
    await tournamentContract.connect(user1).setMonsters(0, [0, 1, 2]);

    const player = await tournamentContract.getPlayer(0, user1Address);
    expect(player.playerMonsters).to.deep.equal([0, 1, 2]);
  });

  it("Should mark a player as ready", async function () {
    let { owner, user1, tournamentContract, monsterTypeContract, cryptoMon } =
      await loadFixture(TournamentContractFixture);
    const user1Address = await user1.getAddress();
    await tournamentContract.connect(owner).createTournament(4);
    await tournamentContract.connect(user1).joinTournament(0);
    await monsterTypeContract.addMonsterType("Dragon", 10, 100, 5, 10);
    await cryptoMon.connect(user1).mint();
    await cryptoMon.connect(user1).mint();
    await cryptoMon.connect(user1).mint();
    await tournamentContract.connect(user1).setMonsters(0, [1, 2, 3]);
    await expect(tournamentContract.connect(user1).markPlayerReady(0))
      .to.emit(tournamentContract, "PlayerReady")
      .withArgs(0, user1Address);

    const player = await tournamentContract.getPlayer(0, user1Address);
    expect(player.isReady).to.equal(true);
  });

  it("Should start the tournament", async function () {
    let {
      owner,
      user1,
      user2,
      user3,
      tournamentContract,
      monsterTypeContract,
      cryptoMon,
    } = await loadFixture(TournamentContractFixture);
    const users = [owner, user1, user2, user3];
    await monsterTypeContract.addMonsterType("Dragon", 10, 100, 5, 10);
    await tournamentContract.connect(owner).createTournament(4);
    for (let i = 0; i < users.length; i++) {
      await tournamentContract.connect(users[i]).joinTournament(0);
      await cryptoMon.connect(users[i]).mint();
      await tournamentContract.connect(users[i]).setMonsters(0, [0]);
      await tournamentContract.connect(users[i]).markPlayerReady(0);
    }

    await expect(tournamentContract.startTournament(0))
      .to.emit(tournamentContract, "TournamentRoundStarted")
      .withArgs(0, 0);

    const tournament = await tournamentContract.tournaments(0);
    expect(tournament.tournamentStatus).to.equal(1); // STARTED
  });

  it.skip("Should handle battle ended and eliminate players", async function () {
    let {
      owner,
      user1,
      user2,
      user3,
      tournamentContract,
      monsterTypeContract,
      cryptoMon,
    } = await loadFixture(TournamentContractFixture);
    const users = [owner, user1, user2, user3];
    await monsterTypeContract.addMonsterType("Dragon", 10, 100, 5, 10);
    await tournamentContract.connect(owner).createTournament(4);
    for (let i = 0; i < users.length; i++) {
      await tournamentContract.connect(users[i]).joinTournament(0);
      await cryptoMon.connect(users[i]).mint();
      await tournamentContract.connect(users[i]).setMonsters(0, [0]);
      await tournamentContract.connect(users[i]).markPlayerReady(0);
    }

    await tournamentContract.startTournament(0);

    // Simulate battle ended
    const user1Address = await user1.getAddress();
    const user2Address = await user2.getAddress();
    await expect(tournamentContract.onBattleEnded(user1Address))
      .to.emit(tournamentContract, "BattleEnded")
      .withArgs(0, user1Address);

    const player1 = await tournamentContract.getPlayer(0, user1Address);
    const player2 = await tournamentContract.getPlayer(0, user2Address);

    expect(player1.isEliminated).to.equal(false);
    expect(player2.isEliminated).to.equal(true);
  });
});
