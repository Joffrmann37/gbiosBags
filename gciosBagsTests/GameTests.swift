//
//  GameTests.swift
//  gciosBags
//
//  Created by Eduardo Arenas on 3/14/17.
//  Copyright © 2017 GameChanger. All rights reserved.
//

@testable import gciosBags
import XCTest

class GameTests: XCTestCase {
    var sut: GameScorer! // System Under Test

    override func setUp() {
        super.setUp()
        sut = GameScorer()
    }

    func testNewGameHasCorrectState() {
        XCTAssertEqual(sut.game.currentRoundNumber, 1)
        XCTAssertEqual(sut.score(for: .blue), 0)
        XCTAssertEqual(sut.score(for: .red), 0)
        XCTAssertEqual(sut.scoreInRound(sut.game.currentRound, forTeam: .blue), 0)
        XCTAssertEqual(sut.scoreInRound(sut.game.currentRound, forTeam: .red), 0)
        XCTAssert(sut.game.currentRound.isNew)
        XCTAssertEqual(sut.gameState, .roundInProgress)
        XCTAssertEqual(sut.nextTeamToThrow(), .red)
    }

    func testAddThrowGeneratesCorrectRoundAndGameScore() {
        sut.addThrow(.board)

        XCTAssertEqual(sut.game.currentRoundNumber, 1)
        XCTAssertEqual(sut.score(for: .blue), 0)
        XCTAssertEqual(sut.score(for: .red), 0)
        XCTAssertEqual(sut.scoreInRound(sut.game.currentRound, forTeam: .blue), 0)
        XCTAssertEqual(sut.scoreInRound(sut.game.currentRound, forTeam: .red), 1)
        XCTAssertFalse(sut.game.currentRound.isNew)
        XCTAssertEqual(sut.gameState, .roundInProgress)
        XCTAssertEqual(sut.nextTeamToThrow(), .blue)

        sut.addThrow(.hole)

        XCTAssertEqual(sut.game.currentRoundNumber, 1)
        XCTAssertEqual(sut.score(for: .blue), 0)
        XCTAssertEqual(sut.score(for: .red), 0)
        XCTAssertEqual(sut.scoreInRound(sut.game.currentRound, forTeam: .blue), 3)
        XCTAssertEqual(sut.scoreInRound(sut.game.currentRound, forTeam: .red), 1)
        XCTAssertFalse(sut.game.currentRound.isNew)
        XCTAssertEqual(sut.gameState, .roundInProgress)
        XCTAssertEqual(sut.nextTeamToThrow(), .red)
    }

    func testRoundOverLogic() {
        // Eight throws make a round
        sut.addThrow(.board)
        sut.addThrow(.out)
        sut.addThrow(.board)
        sut.addThrow(.out)
        sut.addThrow(.board)
        sut.addThrow(.out)
        sut.addThrow(.board)
        sut.addThrow(.out)

        XCTAssertEqual(sut.game.currentRoundNumber, 1) // Shouldn't change after startNewRound() is called
        XCTAssertEqual(sut.score(for: .blue), 0)
        XCTAssertEqual(sut.score(for: .red), 4)
        XCTAssertEqual(sut.scoreInRound(sut.game.currentRound, forTeam: .blue), 0)
        XCTAssertEqual(sut.scoreInRound(sut.game.currentRound, forTeam: .red), 4)
        XCTAssertEqual(sut.gameState, .roundOver)
    }

    func testStartNewRound() {
        // Eight throws make a round
        (0 ..< 4).forEach { _ in
            self.sut.addThrow(.board)
            self.sut.addThrow(.out)
        }
        sut.startNewRound()

        XCTAssertEqual(sut.game.currentRoundNumber, 2)
        XCTAssertEqual(sut.score(for: .blue), 0)
        XCTAssertEqual(sut.score(for: .red), 4)
        XCTAssertEqual(sut.scoreInRound(sut.game.currentRound, forTeam: .blue), 0)
        XCTAssertEqual(sut.scoreInRound(sut.game.currentRound, forTeam: .red), 0)
        XCTAssertEqual(sut.gameState, .roundInProgress)
    }

    func testGameOverLogic() {
        // Red 21, Blue 0

        // After first round: 12 - 0
        (0 ..< 4).forEach { _ in
            self.sut.addThrow(.hole)
            self.sut.addThrow(.out)
        }
        sut.startNewRound()

        // After second round: 21 - 0
        (0 ..< 3).forEach { _ in
            self.sut.addThrow(.hole)
            self.sut.addThrow(.out)
        }
        sut.addThrow(.out)
        sut.addThrow(.out)

        XCTAssertEqual(sut.game.currentRoundNumber, 2)
        XCTAssertEqual(sut.score(for: .blue), 0)
        XCTAssertEqual(sut.score(for: .red), 21)
        XCTAssertEqual(sut.scoreInRound(sut.game.currentRound, forTeam: .blue), 0)
        XCTAssertEqual(sut.scoreInRound(sut.game.currentRound, forTeam: .red), 9)
        XCTAssertEqual(sut.gameState, .gameOver)
    }

    func testTwoPointDifferenceRule() {
        // Red 23, Blue 21

        // After first round: 12 - 0
        (0 ..< 4).forEach { _ in
            self.sut.addThrow(.hole)
            self.sut.addThrow(.out)
        }
        sut.startNewRound()

        // After second round: 12 - 12
        (0 ..< 4).forEach { _ in
            self.sut.addThrow(.out)
            self.sut.addThrow(.hole)
        }
        sut.startNewRound()

        // After third round: 20 - 12
        (0 ..< 4).forEach { _ in
            self.sut.addThrow(.hole)
            self.sut.addThrow(.board)
        }
        sut.startNewRound()

        // After fourth round: 20 - 20
        (0 ..< 4).forEach { _ in
            self.sut.addThrow(.board)
            self.sut.addThrow(.hole)
        }
        sut.startNewRound()

        // After fifth round: 21 - 20
        sut.addThrow(.board)
        sut.addThrow(.out)
        (0 ..< 3).forEach { _ in
            self.sut.addThrow(.out)
            self.sut.addThrow(.out)
        }
        sut.startNewRound()

        XCTAssertEqual(sut.score(for: .blue), 20)
        XCTAssertEqual(sut.score(for: .red), 21)
        XCTAssertEqual(sut.gameState, .roundInProgress)

        // After sixth round: 22 - 20
        sut.addThrow(.board)
        sut.addThrow(.out)
        (0 ..< 3).forEach { _ in
            self.sut.addThrow(.out)
            self.sut.addThrow(.out)
        }
        sut.startNewRound()
        sut.startNewRound()

        XCTAssertEqual(sut.score(for: .blue), 20)
        XCTAssertEqual(sut.score(for: .red), 22)
        XCTAssertEqual(sut.gameState, .gameOver)
    }
}
