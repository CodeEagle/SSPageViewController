//
//  Indicator.swift
//  SSPageView
//
//  Created by LawLincoln on 2016/10/19.
//  Copyright © 2016年 CocoaPods. All rights reserved.
//

import UIKit
public final class PageIndicator: UIView {
    
    private var indicator = CALayer()
    private var _indicatorBackup = CALayer()
    public var totalPage: UInt = 0 { didSet { updateIndicator() } }
    public var locationPercentage: Float = 0 { didSet { updateLocation() } }
    public var indicatorTintColor: UIColor = .red {
        didSet {
            indicator.backgroundColor = indicatorTintColor.cgColor
            _indicatorBackup.backgroundColor = indicatorTintColor.cgColor
        }
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    private func initialize() {
        layer.addSublayer(indicator)
        layer.addSublayer(_indicatorBackup)
        indicator.speed = 999
        _indicatorBackup.speed = 999
        indicator.backgroundColor = indicatorTintColor.cgColor
        _indicatorBackup.backgroundColor = indicatorTintColor.cgColor
        frame = CGRect(origin: CGPoint.zero, size: CGSize(width: UIScreen.main.bounds.width, height: 2))
        indicator.frame = CGRect(x: 0, y: 0, width: 0, height: frame.height)
        _indicatorBackup.frame = CGRect(x: 0, y: 0, width: 0, height: frame.height)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        var f = indicator.frame
        f.size.height = frame.height
        indicator.frame = f
        f = _indicatorBackup.frame
        f.size.height = frame.height
        _indicatorBackup.frame = f
    }
    
    private func updateIndicator() {
        if totalPage < 2 { return }
        let width = frame.width / CGFloat(totalPage)
        var f = indicator.frame
        f.size.width = width
        indicator.frame = f
        f = _indicatorBackup.frame
        f.origin.x = -width
        _indicatorBackup.frame = f
        updateLocation()
    }
    
    private func updateLocation() {
        if totalPage < 2 { return }
        let x = CGFloat(locationPercentage) * frame.width
        var f = indicator.frame
        f.origin.x = x
        var backUpX = -f.width
        if f.maxX > frame.width {
            let delta = f.maxX - frame.width
            backUpX = delta - f.width
        }
        if f.minX < 0 {
            let delta = f.minX
            backUpX =  frame.width + delta
        }
        indicator.frame = f
        f = _indicatorBackup.frame
        f.origin.x = backUpX
        f.size.width = indicator.frame.width
        _indicatorBackup.frame = f
    }
}
