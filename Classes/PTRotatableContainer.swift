//
//  PTRotatableContainer.swift
//  Thundershot
//
//  Created by гык-sse2 on 29.06.15.
//  Copyright © 2015 PaztalomTechnologiez. All rights reserved.
//

import UIKit

public class PTRotatableContainer: UIView {
	
	public var subviewTransform : CGAffineTransform {
		get {
			return (self.subviews.count != 1) ? CGAffineTransformIdentity : self.subviews[0].transform
		}
		set (newTransform) {
			if self.subviews.count == 1 {
				self.subviews[0].transform = newTransform
			}
			sizeToFit()
		}
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		sizeToFit()
	}
	
	public override func addSubview(view: UIView) {
		if self.subviews.count >= 1 { return; }
		super.addSubview(view)
		sizeToFit()
	}
	
	public override func sizeToFit() {
		if self.subviews.count != 1 { return; }
		let subview = self.subviews[0]
		subview.removeConstraints(subview.constraints)
		subview.sizeToFit()
		//subview.frame = CGRectMake(0, 0, subview.frame.width, subview.frame.height)
		frame = CGRectMake(frame.origin.x, frame.origin.y, subview.frame.width, subview.frame.height)
		for c in self.constraints {
			if c.firstItem === self as AnyObject && c.secondItem === nil {
				self.removeConstraint(c)
			}
		}
		self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: frame.width))
		self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: frame.height))
	}
	
	public override func layoutIfNeeded() {
		sizeToFit()
		super.layoutIfNeeded()
	}
}
