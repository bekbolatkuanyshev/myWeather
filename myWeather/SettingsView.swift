//
//  SettingsView.swift
//  myWeather
//
//  Created by Бекболат Куанышев on 03.05.17.
//  Copyright © 2017 Bekbolat. All rights reserved.
//

import UIKit

class SettingsView: FXBlurView {

    var animator : UIDynamicAnimator!
    var container : UICollisionBehavior!
    var snap : UISnapBehavior!
    var dynamicItem : UIDynamicItemBehavior!
    var gravity : UIGravityBehavior!
    
    var panGestureRecognizer : UIPanGestureRecognizer!
    
    func setup() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: Selector(("handlePan:")))
        panGestureRecognizer.cancelsTouchesInView = false
        
        self.addGestureRecognizer(panGestureRecognizer)
        
        animator = UIDynamicAnimator(referenceView: self.superview!)
        dynamicItem = UIDynamicItemBehavior(items : [self])
        dynamicItem.allowsRotation = false
        dynamicItem.elasticity = 0
        
        gravity = UIGravityBehavior(items: [self])
        gravity.gravityDirection = CGVector(dx: 0, dy: -1)
        
        container = UICollisionBehavior(items: [self])
        
        configureContainer()
        
        animator.addBehavior(gravity)
        animator.addBehavior(dynamicItem)
        animator.addBehavior(container)
    }
    
    func configureContainer() {
        let boundaryWidth = UIScreen.main.bounds.size.width
        container.addBoundary(withIdentifier: "upper" as NSCopying, from: CGPoint(x: 0, y: -self.frame.size.height + 66), to: CGPoint(x: 0, y: -self.frame.size.height + 66))
        
        let boundaryHeight = UIScreen.main.bounds.size.height
        container.addBoundary(withIdentifier: "lower" as NSCopying, from: CGPoint(x: 0, y: boundaryHeight), to: CGPoint(x: boundaryWidth, y: boundaryHeight))
    }
    
    func handlePan (pan: UIPanGestureRecognizer) {
        let velocity = pan.velocity(in: self.superview).y
        
        var movement = self.frame
        movement.origin.x = 0
        movement.origin.y = movement.origin.y + (velocity * 0.05)
        
        if pan.state == .ended {
            panGestureEnded()
        } else if pan.state == .began {
            snapToBottom()
        } else {
            animator.removeBehavior(snap)
            snap = UISnapBehavior(item: self, snapTo: CGPoint(x: CGRect(dictionaryRepresentation: movement as! CFDictionary)!.midX, y: (CGRect(dictionaryRepresentation: movement as! CFDictionary)?.midY)!))
            animator.addBehavior(snap)
        }
    }
    
    func panGestureEnded () {
        animator.removeBehavior(snap)
        let velocity = dynamicItem.linearVelocity(for: self)
        
        if fabs(Float(velocity.y)) > 250 {
            if velocity.y < 0 {
                snapToTop()
            } else {
                snapToBottom()
            }
        } else {
            if let superViewHeight = self.superview?.bounds.size.height {
                if self.frame.origin.y > superViewHeight / 2 {
                    snapToBottom()
                } else {
                    snapToTop()
                }
            }
        }
        
    }
    
    func snapToBottom () {
        gravity.gravityDirection = CGVector(dx: 0, dy: 2.5)
    }
    
    func snapToTop () {
        gravity.gravityDirection = CGVector(dx: 0, dy: -2.5)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.tintColor = UIColor.clear
    }
}





