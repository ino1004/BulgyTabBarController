//
//  BulgyTabBarController.swift
//  BulgyTabBarController
//
//  Created by Stephen Chui on 2019/2/14.
//  Copyright © 2019 Stephen Chui. All rights reserved.
//

import UIKit

final class BulgyTabBarController: UITabBarController {
    
    // TabBar icons
    public var iconImageViews: [UIImageView] = []
    
    // Scale of the icon
    private var scaleTransform = CGAffineTransform(scaleX: 1.16, y: 1.16)
    
    // Index of the selection of TabBar
    private var previousIndex: Int = 0
    private var currentIndex: Int = 0
    
    // Is the first tap of TabBar icons, scaleFrame will stored a scale frame at the first time
    private var isFirstTap: Bool = true
    
    // Frame
    private var originalFrame: CGRect = .zero
    private var scaleFrame: CGRect = .zero

    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupIconImageViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Preset the first tabBarItem
        let frame = defaultFrame()
        let scaleFrame = presetScaleFrame(frame)
        setupIconImageView(frame: scaleFrame)
    }
    
    
    // MARK: - UI
    
    private func setupIconImageViews() {
        guard let tabBar = tabBar as? BulgyTabBar else { return }
        tabBar.layer.insertSublayer(tabBar.curveLayer, at: 0)
        tabBar.layer.insertSublayer(tabBar.backgroundLayer, at: 0)
        
        if !tabBar.subviews.isEmpty {
            for subview in tabBar.subviews {
                if let imageView = subview.subviews.first as? UIImageView {
                    iconImageViews.append(imageView)
                    imageView.contentMode = .top
                }
            }
        }
    }

    private func defaultFrame(atIndex index: Int = 0) -> CGRect {
        return iconImageViews[index].layer.frame
    }
    
    private func presetScaleFrame(_ frame: CGRect) -> CGRect {
        return CGRect(x: frame.minX, y: frame.minY - 5, width: frame.width, height: frame.height + 10)
    }
    
    private func setupIconImageView(atIndex index: Int = 0, frame: CGRect) {
        iconImageViews[index].frame = frame
        iconImageViews[index].transform = scaleTransform
    }
    
    
    // MARK: - TabBar's action
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let items = tabBar.items, let index = items.index(of: item) {
            previousIndex = currentIndex
            currentIndex = item.tag
            animate(item: items[index])
        }
    }
    
    
    // MARK: - Animation
    
    private func animate(item: UITabBarItem) {
        guard let tabBar = tabBar as? BulgyTabBar else { return }
        // Reset imageView to identity
        for subview in tabBar.subviews {
            if let imageView = subview.subviews.first as? UIImageView {
                imageView.transform = .identity
            }
        }
        
        // Record the origin frame and the scaled frame
        let frame = defaultFrame(atIndex: item.tag)
        if originalFrame == scaleFrame {
            originalFrame = frame
            if isFirstTap {
                scaleFrame = presetScaleFrame(frame)
            }
        }
        
        // Animation
        let center = iconImageViews[item.tag].center
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 6.0, options: .curveEaseIn, animations: {
            self.setupIconImageView(atIndex: item.tag, frame: self.scaleFrame)
            tabBar.updateCurvePosition(atIndex: item.tag + 1)
            // Prevent weird shake of the animation
            self.iconImageViews[item.tag].layer.position = center
        }, completion: { _ in
            if self.isFirstTap {
                self.isFirstTap = false
            }
        })
    }
}


final class BulgyTabBar: UITabBar {

    public var backgroundLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = #colorLiteral(red: 0.9271890863, green: 0.9271890863, blue: 0.9271890863, alpha: 1).cgColor
        return layer
    }()
    
    public var curveLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = #colorLiteral(red: 0.9271890863, green: 0.9271890863, blue: 0.9271890863, alpha: 1).cgColor
        return layer
    }()
    
    private var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayers()
    }
    
    private func setupViews() {
        self.tintColor = .red
        self.backgroundColor = .clear
        self.backgroundImage = UIImage()
        self.shadowImage = UIImage()
        
        updateCurvePosition()
    }
    
    private func setupLayers() {
        backgroundLayer.frame = self.bounds
        if curveLayer.path == nil {
            createPath()
        }
    }
    
    
    // MARK: - Curve
    
    public func updateCurvePosition(atIndex index: Int = 0) {
        let itemCount: CGFloat = CGFloat(items?.count ?? 1)
        let itemWidth: CGFloat = screenWidth / itemCount
        
        var positionX: CGFloat = 0
        guard index >= 0 else { return }
        if index == 0 {
            positionX = 0
        } else {
            positionX = (CGFloat(index) - 1) * itemWidth
        }
        
        let animation = CASpringAnimation(keyPath: "position.x")
        animation.fromValue = curveLayer.position.x
        animation.toValue = positionX
        
        curveLayer.position = CGPoint(x: positionX, y: 0)
        
        animation.duration = animation.settlingDuration
        animation.damping = 16
        animation.mass = 1
        animation.initialVelocity = 4
        animation.stiffness = 200
        curveLayer.add(animation, forKey: animation.keyPath)
    }
    
    // MARK: - Path
    
    public func createPath() {
        let itemCount: CGFloat = CGFloat(items?.count ?? 1)
        let itemWidth: CGFloat = screenWidth / itemCount
        let itemCenter = itemWidth / 2

        let path = UIBezierPath()

        // Total path required 60 points
        let requiredWidth: CGFloat = 60
        // First point ready to curve
        let pointA: CGFloat = (itemWidth - requiredWidth) / 2
        // After curved from point A
        let pointB: CGFloat = pointA + 10
        // The point after an arc
        let pointC: CGFloat = itemWidth - pointB
        // After curved from point C
        let pointD: CGFloat = pointC + 10

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: pointA, y: 0))
        path.addQuadCurve(to: CGPoint(x: pointB, y: -5), controlPoint: CGPoint(x: pointB, y: -4))
        path.addQuadCurve(to: CGPoint(x: pointC, y: -5), controlPoint: CGPoint(x: itemCenter, y: -20))
        path.addQuadCurve(to: CGPoint(x: pointD, y: 0), controlPoint: CGPoint(x: pointC, y: -4))
        path.addLine(to: CGPoint(x: itemWidth, y: 0))
        path.addLine(to: CGPoint(x: itemWidth, y: 30))
        path.addLine(to: CGPoint(x: 0, y: 30))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.close()

        curveLayer.path = path.cgPath
    }
}
