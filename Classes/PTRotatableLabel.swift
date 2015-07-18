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
				.filter({$0 ==  "\u{00002028}"}).count + 1 : 0)
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
	
	required public init?(coder aDecoder: NSCoder) {
		label = UILabel()
		label.textAlignment = NSTextAlignment.Center
		label.translatesAutoresizingMaskIntoConstraints = false
		super.init(coder: aDecoder)
		self.translatesAutoresizingMaskIntoConstraints = false
		self.addConstraint(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
		self.addConstraint(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0))
		self.addSubview(label)
		sizeToFit()
	}
	
	override public init(frame : CGRect) {
		label = UILabel()
		label.textAlignment = NSTextAlignment.Center
		super.init(frame : frame)
		self.addSubview(label)
		sizeToFit()
	}
	
	public override func sizeToFit() {
		for c in self.constraints {
			if c.firstItem === self as AnyObject && c.secondItem === nil {
				self.removeConstraint(c)
			}
		}
		for c in self.constraints {
			if c.firstItem === label as AnyObject && c.secondItem === nil {
				self.removeConstraint(c)
			}
		}
		
		label.translatesAutoresizingMaskIntoConstraints = true
		label.sizeToFit()
		label.translatesAutoresizingMaskIntoConstraints = false
		
		for c in self.constraints {
			if c.firstItem === label as AnyObject && c.secondItem === nil {
				self.removeConstraint(c)
			}
		}
		
		//label
		self.addConstraint(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: label.frame.width))
		self.addConstraint(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: label.frame.height))
		
		// self
		self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: label.frame.width))
		self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: label.frame.height))
	}
	
	public override func layoutIfNeeded() {
		sizeToFit()
		super.layoutIfNeeded()
	}
}
