//
//  Game.swift
//  gciosBags
//
//  Created by Eduardo Arenas on 2/8/17.
//  Copyright © 2017 GameChanger. All rights reserved.
//

import Foundation

/// Represents a single game of cornhole.
class Game {
    var rounds: [Round]

    var currentRoundNumber: Int {
        return rounds.count
    }

    var currentRound: Round {
        return rounds.last!
    }

    init(startingTeam: Team = .red) {
        rounds = [Round(startingTeam: startingTeam)]
    }
}
