//
//  PopButton.swift
//  RamenCompass
//
//  Created by Ian Parker on 4/8/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit


class PopButton: UIButton {
    //
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    func setup(){
        self.addTarget(self, action:"scaleToSmall", forControlEvents: .TouchDown | .TouchDragEnter)
        self.addTarget(self, action:"scaleAnimation", forControlEvents: .TouchUpInside)
        self.addTarget(self, action:"scaleToDefault", forControlEvents: .TouchDragExit)
    }
    
    func scaleToSmall(){
        var scaleAnimation: POPBasicAnimation = POPBasicAnimation(propertyNamed: kPOPLayerScaleXY)
        scaleAnimation.toValue = NSValue(CGSize: CGSizeMake(0.90, 0.90))
        self.layer.pop_addAnimation(scaleAnimation, forKey: "layerScaleSmallAnimation")
    }
    
    func scaleAnimation(){
        var scaleAnimation: POPSpringAnimation = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)
        scaleAnimation.velocity = NSValue(CGSize: CGSizeMake(5.0, 5.0))
        scaleAnimation.toValue = NSValue(CGSize: CGSizeMake(1.0, 1.0))
        scaleAnimation.springBounciness = 25.0
        self.layer.pop_addAnimation(scaleAnimation, forKey: "layerScaleSpringAnimation")
        
        if (self.tag == 100){ //Buttons tagged with 1 are rotation as well
            var spinAnimation: POPSpringAnimation = POPSpringAnimation(propertyNamed: kPOPLayerRotation)
            spinAnimation.velocity = 20
            spinAnimation.toValue = 2*M_PI
            spinAnimation.springBounciness = 10.0
            self.layer.pop_addAnimation(spinAnimation, forKey: "layerSpinSpringAnimation")
        }
    }
    
    func scaleToDefault(){
        var scaleAnimation: POPBasicAnimation = POPBasicAnimation(propertyNamed: kPOPLayerScaleXY)
        scaleAnimation.toValue = NSValue(CGSize: CGSizeMake(1.0, 1.0))
        self.layer.pop_addAnimation(scaleAnimation, forKey: "layerScaleDefaultAnimation")
    }

}