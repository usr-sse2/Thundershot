//
//  PTRotatableLabel.swift
//  Thundershot
//
//  Created by гык-sse2 on 29.06.15.
//  Copyright © 2015 PaztalomTechnologiez. All rights reserved.
//

import UIKit

@IBDesignable
public class PTRotatableLabel: UIView {
	public var label : UILabel
	
	@IBInspectable
	public var text : String? {
		get {
			return label.text
		}
		set (newText) {
			label.text = newText
			label.numberOfLines = (newText != nil ? newText!.characters
				.filter({$0 ==  "\n"}).count : 0)
			sizeToFit()
		}
	}
	
	@IBInspectable
	public var alignment : NSTextAlignment {
		get {
			return label.textAlignment
		}
		set (newTextAlignment) {
			label.textAlignment = newTextAlignment
		}
	}
	
	@IBInspectable
	public var color : UIColor {
		get {
			return label.textColor
		}
		set (newColor) {
			label.textColor = newColor
		}
	}
	
	@IBInspectable
	public var fontSize : CGFloat {
		get {
			return label.font.pointSize
		}
		set (newFontSize) {
			label.font = label.font.fontWithSize(newFontSize)
		}
	}
	
	public var labelTransform : CGAffineTransform {
		get {
			return label.transform
		}
		set (newTransform) {
			label.transform = newTransform
			sizeToFit()
		}
	}
	
	required public init(coder aDecoder: NSCoder) {
		label = UILabel()
		super.init(coder: aDecoder)
		self.addSubview(label)
		sizeToFit()
	}
	
	override public init(frame : CGRect) {
		label = UILabel()
		super.init(frame : frame)
		self.addSubview(label)
		sizeToFit()
	}
	
	public override func sizeToFit() {
		label.sizeToFit()
		label.frame = CGRectMake(0, 0, label.frame.width, label.frame.height)
		frame = CGRectMake(frame.origin.x, frame.origin.y, label.frame.width, label.frame.height)
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
