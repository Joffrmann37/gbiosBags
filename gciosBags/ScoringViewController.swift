//
//  ViewController.swift
//  gciosBags
//
//  Created by Eduardo Arenas on 2/8/17.
//  Copyright © 2017 GameChanger. All rights reserved.
//

import UIKit

class ScoringViewController: UIViewController {
    private static let redColor = UIColor(red: 0.75, green: 0.16, blue: 0.16, alpha: 1.00)
    private static let blueColor = UIColor(red: 0.20, green: 0.50, blue: 0.81, alpha: 1.00)

    private var gameScorer = GameScorer()
    private var bagViews = [BagView]()
    private var canThrow = true
    private var holePath = UIBezierPath()
    private var boardPath = UIBezierPath()

    @IBOutlet var boardImageView: UIImageView!
    @IBOutlet var roundLabel: UILabel!
    @IBOutlet var playView: UIView!

    @IBOutlet var redGameScoreLabel: UILabel!
    @IBOutlet var blueGameScoreLabel: UILabel!
    @IBOutlet var redRoundScoreLabel: UILabel!
    @IBOutlet var blueRoundScoreLabel: UILabel!
    @IBOutlet var redThrowIndicatorView: UIImageView!
    @IBOutlet var blueThrowIndicatorView: UIImageView!
    @IBOutlet var redBagCountContainerStackView: UIStackView!
    @IBOutlet var blueBagCountContainerStackView: UIStackView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NotificationCenter.default.addObserver(self, selector: #selector(regenerateAllThrowsInRound), name: .bagViewMoved, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshViews()
        redBagCountContainerStackView.arrangedSubviews.forEach { self.configureBagCountIndicator($0, color: ScoringViewController.redColor) }
        blueBagCountContainerStackView.arrangedSubviews.forEach { self.configureBagCountIndicator($0, color: ScoringViewController.blueColor) }
        boardImageView.layer.zPosition = 2
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        recalculatePaths()
    }

    private func configureBagCountIndicator(_ countView: UIView, color: UIColor) {
        countView.layer.cornerRadius = 2
        countView.layer.borderWidth = 1
        countView.layer.borderColor = color.cgColor
    }

    private func handleTap(in point: CGPoint) {
        guard let nextTeam = gameScorer.nextTeamToThrow(),
              self.gameScorer.gameState == .roundInProgress
        else {
            return
        }

        let newBag = BagView(color: BagColor.color(for: nextTeam))
        playView.addSubview(newBag)
        newBag.center = point

        addThrowForBag(bag: newBag)
        bagViews.append(newBag)
        refreshViews()
    }

    private func addThrowForBag(bag: BagView) {
        let newThrow = self.newThrow(in: bag.center)
        gameScorer.addThrow(newThrow)

        if newThrow == .hole {
            bag.layer.zPosition = 1
        } else {
            bag.layer.zPosition = 3
        }

        switch gameScorer.gameState {
        case .roundOver:
            presentRoundOverAlert()
        case .gameOver:
            presentGameOverAlert()
        default:
            break
        }
    }

    private func newThrow(in point: CGPoint) -> Throw {
        if holePath.contains(point) {
            return .hole
        } else if boardPath.contains(point) {
            return .board
        } else {
            return .out
        }
    }

    private func presentRoundOverAlert() {
        let startNextRoundAction = UIAlertAction(title: "Start Next Round", style: .default) { _ in
            self.clearBoard()
            self.gameScorer.startNewRound()
            self.refreshViews()
        }

        let title: String
        let message: String
        switch gameScorer.result(forRound: gameScorer.game.currentRound) {
        case let .over(winner, points):
            if let winner = winner {
                title = "\(winner.name) Team wins round \(gameScorer.game.currentRoundNumber)!"
                message = "\(points) \(points == 1 ? "point" : "points") added to their total score"
            } else {
                title = "Round \(gameScorer.game.currentRoundNumber) is a tie!"
                message = "No point will be added to either team"
            }
        case .inProgress:
            fatalError("Can't call presentRoundOverAlert when round is inProgress")
        }

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(startNextRoundAction)

        present(alertController, animated: true, completion: nil)
    }

    private func presentGameOverAlert() {
        guard let winner = gameScorer.winner else {
            fatalError("There must be a winner before attempting to present the game over alert")
        }

        let startNewGameAction = UIAlertAction(title: "Start New Game", style: .default) { _ in
            self.clearBoard()
            self.gameScorer = GameScorer()
            self.refreshViews()
        }

        let title = "\(winner.name) Team Wins!"
        let message = "Final score:\n" +
            "\(Team.red.name) Team: \(gameScorer.score(for: .red)), " +
            "\(Team.blue.name) Team: \(gameScorer.score(for: .blue))"

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(startNewGameAction)

        present(alertController, animated: true, completion: nil)
    }

    private func clearBoard() {
        bagViews.forEach { $0.removeFromSuperview() }
        bagViews.removeAll()
    }

    // For simplicity when users drag and drop a bag we regenerate all the
    // throws in the round
    @objc private func regenerateAllThrowsInRound() {
        gameScorer.clearCurrentRound()
        bagViews.forEach { self.addThrowForBag(bag: $0) }
        refreshViews()
    }

    private func refreshViews() {
        roundLabel.text = "Round \(gameScorer.game.currentRoundNumber)"
        redGameScoreLabel.text = "\(gameScorer.score(for: .red))"
        blueGameScoreLabel.text = "\(gameScorer.score(for: .blue))"
        redRoundScoreLabel.text = "\(gameScorer.scoreInRound(gameScorer.game.currentRound, forTeam: .red))"
        blueRoundScoreLabel.text = "\(gameScorer.scoreInRound(gameScorer.game.currentRound, forTeam: .blue))"
        redThrowIndicatorView.isHidden = gameScorer.nextTeamToThrow() != .red
        blueThrowIndicatorView.isHidden = gameScorer.nextTeamToThrow() != .blue
        upateBagCountView(redBagCountContainerStackView, for: .red)
        upateBagCountView(blueBagCountContainerStackView, for: .blue)
    }

    /// Updates the bag indicators that show app below the round's score
    private func upateBagCountView(_ bagCountView: UIStackView, for team: Team) {
        let throwCount = team == .red ? gameScorer.numberOfThrowsInRound(gameScorer.game.currentRound, forTeam: .red) : gameScorer.numberOfThrowsInRound(gameScorer.game.currentRound, forTeam: .blue)
        let color = team == .red ? ScoringViewController.redColor : ScoringViewController.blueColor
        let remainingThrows = 4 - throwCount

        bagCountView.arrangedSubviews.enumerated().forEach { index, view in
            if remainingThrows > index {
                view.backgroundColor = color
            } else {
                view.backgroundColor = .clear
            }
        }
    }

    // These paths are based on where the shapes and sizes of the board and the whole in the
    // original assets

    private func recalculatePaths() {
        recalculateHolePath()
        recalculateBoardPath()
    }

    private func recalculateBoardPath() {
        boardPath = UIBezierPath(rect: CGRect(x: boardImageView.frame.minX + 23,
                                              y: boardImageView.frame.minY + 16,
                                              width: 204,
                                              height: 408))
    }

    private func recalculateHolePath() {
        let enclosingRect = CGRect(x: boardImageView.frame.minX + 97,
                                   y: boardImageView.frame.minY + 68,
                                   width: 56,
                                   height: 56)

        holePath = UIBezierPath(ovalIn: enclosingRect)
    }

    // MARK: Actions

    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            handleTap(in: sender.location(in: playView))
        }
    }
}
