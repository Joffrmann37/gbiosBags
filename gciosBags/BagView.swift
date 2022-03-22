//
//  BagView.swift
//  gciosBags
//
//  Created by Eduardo Arenas on 2/8/17.
//  Copyright © 2017 GameChanger. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let bagViewMoved = Notification.Name("bagViewMoved")
}

enum BagColor {
    case blue
    case red

    fileprivate var image: UIImage {
        switch self {
        case .blue: return #imageLiteral(resourceName: "bluebag")
        case .red: return #imageLiteral(resourceName: "redbag")
        }
    }

    static func color(for team: Team) -> BagColor {
        switch team {
        case .red: return .red
        case .blue: return .blue
        }
    }
}

class BagView: UIView {
    let imageView: UIImageView

    init(color: BagColor) {
        imageView = UIImageView(image: color.image)
        super.init(frame: CGRect(x: 0, y: 0, width: 52, height: 52))
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        isUserInteractionEnabled = true
        imageView.isUserInteractionEnabled = true
        transform = CGAffineTransform(rotationAngle: CGFloat.pi * 2 * CGFloat(arc4random_uniform(100)) / 100)
        layer.shadowOpacity = 0.6
        addSubview(imageView)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        handleTouches(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
        handleTouches(touches)
        layer.zPosition = 3
    }

    override func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) {
        handleTouches(touches)
        NotificationCenter.default.post(name: .bagViewMoved, object: self)
    }

    private func handleTouches(_ touches: Set<UITouch>) {
        guard let superview = superview,
              let location = touches.first?.location(in: superview),
              superview.bounds.contains(location)
        else {
            return
        }

        center = location
    }
}
