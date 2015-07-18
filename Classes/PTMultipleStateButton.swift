//
//  PTRotatableBarSegmentedControl.swift
//  Thundershot
//
//  Created by гык-sse2 on 02.07.15.
//  Copyright © 2015 PaztalomTechnologiez. All rights reserved.
//

import UIKit

@IBDesignable
class PTMultipleStateButton : UIButton {
	
	var _orientation : UIInterfaceOrientation = UIInterfaceOrientation.Portrait
	
	var stateLabels : [String] = [ "" ]
	
	@IBInspectable
	var semicolonSeparatedStateLabels : String {
		get {
			var r = String()
			for i in stateLabels {
				r.extend(i + ";")
			}
			if r != "" {
				r.removeAtIndex(r.endIndex.predecessor())
			}
			return r
		}
		set (newStateLabels) {
			stateLabels = newStateLabels.componentsSeparatedByString(";")
			selectedState = _state // refresh label
		}
	}
	
	var _state : Int = 0
	
	@IBInspectable
	var selectedState : Int {
		get {
			return _state
		}
		set (newState) {
			_state = newState
			setTitle(stateLabels[selectedState % stateLabels.count], forState: UIControlState.Normal)
			sizeToFit()
		}
	}
	
	@IBAction
	func onClick() {
		selectedState = (selectedState + 1) % stateLabels.count
	}
	
	func initialize() {
		addTarget(self, action: "onClick", forControlEvents: UIControlEvents.TouchUpInside)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}
	
	override init(frame: CGRect) {
		super.init(frame : frame)
		initialize()
	}
	
	
	var orientation : UIInterfaceOrientation {
		get {
			return _orientation
		}
		set (o) {
			var angle : Double
			switch (o) {
			case UIInterfaceOrientation.PortraitUpsideDown:
				angle = M_PI
				break
			case UIInterfaceOrientation.LandscapeLeft:
				angle = M_PI_2
				break
			case UIInterfaceOrientation.LandscapeRight:
				angle = -M_PI_2
				break
			case UIInterfaceOrientation.Portrait:
				angle = 0
				break
			default:
				return
			}
			
			_orientation = o
			transform = CGAffineTransformMakeRotation(CGFloat(angle));
			layoutSubviews()
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		if orientation.isLandscape {
			if let imageView = self.imageView {
				imageView.frame.origin.x = (self.bounds.size.width - imageView.frame.size.width) / 2.0
				imageView.frame.origin.y = 0.0
			}
			if let titleLabel = self.titleLabel {
				titleLabel.frame.origin.x = (self.bounds.size.width - titleLabel.frame.size.width) / 2.0
				titleLabel.frame.origin.y = self.bounds.size.height// - titleLabel.frame.size.height
			}
		}
	}
	
	
	override func imageRectForContentRect(contentRect : CGRect) -> CGRect {
		if orientation == UIInterfaceOrientation.PortraitUpsideDown {
			var frame = super.imageRectForContentRect(contentRect)
			frame.origin.x = CGRectGetMaxX(contentRect) - CGRectGetWidth(frame) -  imageEdgeInsets.right + imageEdgeInsets.left
			return frame
		}
		else {
			return super.imageRectForContentRect(contentRect)
		}
	}
	
	override func titleRectForContentRect(contentRect : CGRect) -> CGRect {
		if orientation == UIInterfaceOrientation.PortraitUpsideDown {
			var frame = super.titleRectForContentRect(contentRect)
			frame.origin.x = CGRectGetMinX(frame) - CGRectGetWidth(imageRectForContentRect(contentRect))
			return frame
		}
		else {
			return super.titleRectForContentRect(contentRect)
		}
	}
}
