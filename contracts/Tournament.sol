// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CryptoMon.sol";
import "./Battle.sol";

/**
 * @title Cryptomon: A decentralized game where players can collect, trade, and battle unique digital monsters.
 * @dev This smart contract defines the core functionality of the Cryptomon game.
 *      It includes features such as monster ownership, battle system, rewards distribution, leveling, and tournaments.
 *      The code is open-source and transparent to ensure fairness and trust in the game mechanics.
 */
contract TournamentManager is Ownable {
    MonBattle private battleContract;
    uint256 private totalTournaments;

    enum TournamentStatus {
        PENDING,
        STARTED,
        ENDED
    }

    struct Player {
        bool isEliminated;
        bool isInBattle;
        bool isReady;
        uint16[] playerMonsters; /// @param playerMonsters uint array representing the player's cryptomons in this battle
    }

    struct Tournament {
        mapping(uint8 => Battle[]) battles;
        TournamentStatus tournamentStatus; /// @param tournamentStatus enum to indicate battle status
        address host; /// @param host address array representing players in this battle
        mapping(address => Player) players;
        mapping(address => address) opponents; /// @param opponents mapping to each round's opponent pairs
        address[] playerAddresses;
        address winner; /// @param winner winner address
        uint8 playerNum;
        uint8 maxPlayerNum;
        uint8 currentRound;
    }
    mapping(uint256 => Tournament) public tournaments;
    event TournamentCreated(uint256 indexed tournamentId, address host);
    event PlayerJoined(uint256 indexed tournamentId, address player);
    event TournamentRoundStarted(uint256 indexed tournamentId,uint8 round);
    event PlayerReady(uint256 indexed tournamentId, address player);
    event BattleEnded(uint256 indexed tournamentId, address winner);
    event TournamentEnded(uint256 indexed tournamentId, address winner);

    constructor(address _battleContract) Ownable(_battleContract) {
        // Initialize the Battles contract
        battleContract = MonBattle(_battleContract);
        totalTournaments = 0;
    }

    function createTournament(uint8 _maxPlayers) external {
        Tournament storage newTournament = tournaments[totalTournaments++];
        newTournament.tournamentStatus = TournamentStatus.PENDING;
        newTournament.host = msg.sender;
        newTournament.maxPlayerNum = _maxPlayers;
        newTournament.playerNum = 0;
        newTournament.currentRound = 0;

        emit TournamentCreated(totalTournaments - 1, msg.sender);
    }

    function joinTournament(uint256 tournamentId) external {
        Tournament storage tournament = tournaments[tournamentId];
        require(
            tournament.tournamentStatus == TournamentStatus.PENDING,
            "Tournament already started or ended"
        );
        require(
            tournament.playerNum <= tournament.maxPlayerNum,
            "Tournament is full"
        );

        tournament.players[msg.sender] = Player(
            false,
            false,
            false,
            new uint16[](0)
        );
        tournament.playerAddresses.push(msg.sender);
        tournament.playerNum++;

        emit PlayerJoined(tournamentId, msg.sender);
    }

    function setMonsters(
        uint256 tournamentId,
        uint16[] memory monsters
    ) external {
        Tournament storage tournament = tournaments[tournamentId];
        Player storage player = tournament.players[msg.sender];
        require(player.isReady == false, "Player is already marked as ready");
        require(
            tournament.tournamentStatus == TournamentStatus.PENDING,
            "Tournament already started or ended"
        );

        player.playerMonsters = monsters;
    }

    function markPlayerReady(uint256 tournamentId) external {
        Tournament storage tournament = tournaments[tournamentId];
        require(
            _isPlayerInTournament(tournamentId, msg.sender),
            "Player not in tournament"
        );

        Player storage player = tournament.players[msg.sender];
        require(
            player.playerMonsters.length > 0,
            "Player has not set monsters"
        );
        require(!player.isReady, "Player already marked as ready");

        player.isReady = true;

        emit PlayerReady(tournamentId, msg.sender);
    }

    function _isPlayerInTournament(
        uint256 tournamentId,
        address playerAddress
    ) internal view returns (bool) {
        Tournament storage tournament = tournaments[tournamentId];
        for (uint256 i = 0; i < tournament.playerAddresses.length; i++) {
            if (tournament.playerAddresses[i] == playerAddress) {
                return true;
            }
        }
        return false;
    }

    function startTournament(uint256 tournamentId) public {
        Tournament storage tournament = tournaments[tournamentId];
        require(
            msg.sender == tournament.host,
            "You're not authorized to start this tournament"
        );
        require(
            tournament.tournamentStatus == TournamentStatus.PENDING,
            "Tournament already started or ended"
        );

        tournament.tournamentStatus = TournamentStatus.STARTED;
        // Randomize player order
        for (uint256 i = 0; i < tournament.playerNum; i++) {
            uint256 n = i +
                (uint256(keccak256(abi.encodePacked(block.timestamp))) %
                    (tournament.playerNum - i));
            address temp = tournament.playerAddresses[n];
            tournament.playerAddresses[n] = tournament.playerAddresses[i];
            tournament.playerAddresses[i] = temp;
        }

        _createBracket(tournamentId);
    }

    function _createBracket(uint256 tournamentId) internal {
        Tournament storage tournament = tournaments[tournamentId];

        // Shuffle player addresses for randomness
        for (uint256 i = 0; i < tournament.playerAddresses.length; i++) {
            uint256 n = i +
                (uint256(keccak256(abi.encodePacked(block.timestamp))) %
                    (tournament.playerAddresses.length - i));
            address temp = tournament.playerAddresses[n];
            tournament.playerAddresses[n] = tournament.playerAddresses[i];
            tournament.playerAddresses[i] = temp;
        }

        // Create opponent pairs
        for (uint256 i = 0; i < tournament.playerNum; i += 2) {
            if (i + 1 < tournament.playerNum) {
                tournament.opponents[tournament.playerAddresses[i]] = tournament
                    .playerAddresses[i + 1];
                tournament.opponents[
                    tournament.playerAddresses[i + 1]
                ] = tournament.playerAddresses[i];
            }
        }

        emit TournamentRoundStarted(tournamentId,tournament.currentRound);
    }

    function onBattleEnded(uint256 battleId, address winner) external {
        //uint256 tournamentId = battleContract.getBattleTournament(battleId);
        uint256 tournamentId =0;
        Tournament storage tournament = tournaments[tournamentId];

        tournament.players[winner].isInBattle = false;

        // Check if the round is complete
        bool roundComplete = true;
        for (uint256 i = 0; i < tournament.playerAddresses.length; i++) {
            if (tournament.players[tournament.playerAddresses[i]].isInBattle) {
                roundComplete = false;
                break;
            }
        }

        if (roundComplete) {
            // Eliminate players
            for (uint256 i = 0; i < tournament.playerAddresses.length; i++) {
                if (
                    !tournament
                        .players[tournament.playerAddresses[i]]
                        .isInBattle
                ) {
                    tournament
                        .players[tournament.playerAddresses[i]]
                        .isEliminated = true;
                }
            }

            // Check if we have a winner
            address[] memory remainingPlayers = _getRemainingPlayers(
                tournamentId
            );
            if (remainingPlayers.length == 1) {
                tournament.tournamentStatus = TournamentStatus.ENDED;
                tournament.winner = remainingPlayers[0];

                emit TournamentEnded(tournamentId, remainingPlayers[0]);
            } else {
                _prepareNextRound(tournamentId);
            }
        }

        emit BattleEnded(tournamentId, winner);
    }

    function _prepareNextRound(uint256 tournamentId) internal {
        Tournament storage tournament = tournaments[tournamentId];
        address[] memory nextRoundPlayers;
        uint256 index = 0;

        // Collect winners for the next round
        for (uint256 i = 0; i < tournament.playerAddresses.length; i++) {
            if (
                !tournament.players[tournament.playerAddresses[i]].isEliminated
            ) {
                nextRoundPlayers[index] = tournament.playerAddresses[i];
                index++;
            }
        }

        // Update player addresses for the next round
        tournament.playerAddresses = nextRoundPlayers;
        tournament.playerNum = uint8(nextRoundPlayers.length);
        tournament.currentRound++;

        // Create new bracket for the next round
        _createBracket(tournamentId);
    }

    function _getRemainingPlayers(
        uint256 tournamentId
    ) internal view returns (address[] memory) {
        Tournament storage tournament = tournaments[tournamentId];
        address[] memory nextRoundPlayers;
        uint256 index = 0;

        // Collect winners for the next round
        for (uint256 i = 0; i < tournament.playerAddresses.length; i++) {
            if (
                !tournament.players[tournament.playerAddresses[i]].isEliminated
            ) {
                nextRoundPlayers[index] = tournament.playerAddresses[i];
                index++;
            }
        }

        return nextRoundPlayers;
    }
}
