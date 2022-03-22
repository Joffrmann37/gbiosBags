//
//  GameState.swift
//  gciosBags
//
//  Created by Eduardo Arenas on 8/8/17.
//  Copyright © 2017 GameChanger. All rights reserved.
//

import Foundation

/// Possible states of a game
///
/// - roundInProgress: The game's `currentRound` is in progress
/// - roundOver: The game's `currentRound` is over (each team has four throws)
/// - gameOver: One of the teams has scored more than 21 points and leads by more than 2 points
enum GameState {
    case roundInProgress
    case roundOver
    case gameOver
}

/// Possible states of a round
///
/// - inProgress: round is currently in progress
/// - over: round is over, the winning team and point difference are passed as associated values. If round is tied winner is nil, point difference is 0
enum RoundResult {
    case inProgress
    case over(winner: Team?, pointDiff: Int)
}

/// Contains the logic to score a game and access score information of existing games. A new instance of `GameScorer` should be created for each game.
class GameScorer {
    // -- Properties

    let game: Game

    var gameState: GameState {
        return currentGameState()
    }

    var winner: Team? {
        return gameWinner()
    }

    // -- Initializers

    init(game: Game = Game()) {
        self.game = game
    }

    // -- Accessors

    /// Current score for a given team
    func score(for team: Team) -> Int {
        var gameScore = 0

        for round in game.rounds {
            switch result(forRound: round) {
            case let .over(winner, roundScore) where winner == team:
                gameScore += roundScore
            default: continue
            }
        }

        return gameScore
    }

    /// Next team to throw in the game. Returns `nil` if game is over.
    func nextTeamToThrow() -> Team? {
        guard !isRoundOver(game.currentRound) else {
            return nil
        }

        let secondTeam = game.currentRound.startingTeam == .red ? Team.blue : .red

        if game.currentRound.redThrows.count == game.currentRound.blueThrows.count {
            return game.currentRound.startingTeam
        } else {
            return secondTeam
        }
    }

    /// Round score for the passed in team
    func scoreInRound(_ round: Round, forTeam team: Team) -> Int {
        return throwsInRound(round, forTeam: team).reduce(0) { $0 + $1.points }
    }

    /// Number of throws in round for the given team
    func numberOfThrowsInRound(_ round: Round, forTeam team: Team) -> Int {
        return throwsInRound(round, forTeam: team).count
    }

    /// Return the result of a given round
    func result(forRound round: Round) -> RoundResult {
        guard isRoundOver(round) else { return .inProgress }

        let redTeamPoints = scoreInRound(round, forTeam: .red)
        let blueTeamPoints = scoreInRound(round, forTeam: .blue)

        if redTeamPoints == blueTeamPoints {
            return .over(winner: nil, pointDiff: 0)
        } else if redTeamPoints > blueTeamPoints {
            return .over(winner: .red, pointDiff: redTeamPoints - blueTeamPoints)
        } else {
            return .over(winner: .blue, pointDiff: blueTeamPoints - redTeamPoints)
        }
    }

    // -- Scoring

    /// Adds a throw to the current round of a game
    func addThrow(_ newThrow: Throw) {
        guard let nextTeamToThrow = nextTeamToThrow() else { return }
        switch nextTeamToThrow {
        case .red:
            game.currentRound.redThrows.append(newThrow)
        case .blue:
            game.currentRound.blueThrows.append(newThrow)
        }
    }

    /// Clears all the throws of the current round
    func clearCurrentRound() {
        game.currentRound.redThrows.removeAll()
        game.currentRound.blueThrows.removeAll()
    }

    /// Starts a new round if the current round is over. Otherwise it does nothing.
    func startNewRound() {
        guard currentGameState() == .roundOver else {
            return
        }

        let lastRound = game.currentRound
        if case let .over(winner, _) = result(forRound: lastRound) {
            let nextRoundStarter = winner ?? lastRound.startingTeam
            self.game.rounds.append(Round(startingTeam: nextRoundStarter))
        }
    }

    // -- Private methods

    private func isGameOver() -> Bool {
        let redScore = score(for: .red)
        let blueScore = score(for: .blue)

        let reachedWinningScore = redScore >= 21 || blueScore >= 21
        let hasDifferenceOfTwo = abs(redScore - blueScore) >= 2

        return reachedWinningScore && hasDifferenceOfTwo
    }

    private func gameWinner() -> Team? {
        guard currentGameState() == .gameOver else {
            return nil
        }
        return score(for: .red) > score(for: .blue) ? Team.red : .blue
    }

    private func currentGameState() -> GameState {
        if isGameOver() {
            return .gameOver
        } else if isRoundOver(game.currentRound) {
            return .roundOver
        } else {
            return .roundInProgress
        }
    }

    private func isRoundOver(_ round: Round) -> Bool {
        return round.redThrows.count == 4 && round.blueThrows.count == 4
    }

    private func throwsInRound(_ round: Round, forTeam team: Team) -> [Throw] {
        switch team {
        case .red: return round.redThrows
        case .blue: return round.blueThrows
        }
    }
}
