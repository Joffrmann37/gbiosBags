//
//  Team.swift
//  gciosBags
//
//  Created by Eduardo Arenas on 8/8/17.
//  Copyright © 2017 GameChanger. All rights reserved.
//

import Foundation

/// Possible teams in a game
enum Team {
    case red
    case blue

    var name: String {
        switch self {
        case .red: return "Red"
        case .blue: return "Blue"
        }
    }
}
