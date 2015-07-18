//
//  PTSliderWithValue.swift
//  Thundershot
//
//  Created by гык-sse2 on 03.06.15.
//
//

import UIKit

@IBDesignable
public class PTSliderWithValue: UISlider {
	private var maxLen = 0
	private var label = UILabel()
	private var _toStringLambda : ((Float) -> String) = {
		(v : Float) -> String in
		return String(format: "%f", v)
	}
	
	private var tran = CGAffineTransformIdentity
	
	public var labelTransform : CGAffineTransform {
		get {
			return tran
		}
		set (newTransform) {
			tran = newTransform
			onValueChanged()
		}
	}
	
	public override var value : Float {
		get {
			return super.value
		}
		set (newValue) {
			super.value = newValue
			self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
		}
	}
	
	
	
	public var toStringLambda : ((Float) -> String) {
		get {
			return _toStringLambda
		}
		set (newToStringLambda) {
			_toStringLambda = newToStringLambda
			recalcSize()
			onValueChanged()
		}
	}
	
	@IBInspectable
	public var maxValue : Float {
		get {
			return maximumValue
		}
		set (newMaxValue) {
			maximumValue = newMaxValue
			recalcSize()
		}
	}
	
	@IBInspectable
	public var minValue : Float {
		get {
			return minimumValue
		}
		set (newMinValue) {
			minimumValue = newMinValue
			recalcSize()
		}
	}
	
	private func recalcSize(example : String? = nil) {
		if example == nil {
			
			let minString = toStringLambda(minimumValue), maxString = toStringLambda(maximumValue);
			let minSize = minString.characters.count, maxSize = maxString.characters.count;
			
			label.text = minSize > maxSize ? minString : maxString
			maxLen = max(minSize, maxSize)
		}
		else {
			label.text = example
			maxLen = (example!).characters.count
		}
		label.bounds = CGRectMake(label.bounds.origin.x, label.bounds.origin.y, 0, label.bounds.height)
		label.sizeToFit()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		label.font = UIFont(name: "Helvetica", size: 12)
		label.textColor = UIColor(white: 1, alpha: 1)
		label.textAlignment = NSTextAlignment.Center
		label.lineBreakMode = NSLineBreakMode.ByTruncatingMiddle
		label.numberOfLines = 2
		super.init(coder: aDecoder)
		continuous = true
		recalcSize()
		onValueChanged()
		self.addTarget(self, action:"onValueChanged", forControlEvents: UIControlEvents.ValueChanged)
	}
	
	override public init(frame : CGRect) {
		label.font = UIFont(name: "Helvetica", size: 12)
		label.textColor = UIColor(white: 1, alpha: 1)
		label.textAlignment = NSTextAlignment.Center
		label.lineBreakMode = NSLineBreakMode.ByTruncatingMiddle
		label.numberOfLines = 2
		super.init(frame : frame)
		continuous = true
		recalcSize()
		onValueChanged()
		self.addTarget(self, action:"onValueChanged", forControlEvents: UIControlEvents.ValueChanged)
	}
	
	@IBAction func onValueChanged () {
		label.text = toStringLambda(value)
		if (label.text!).characters.count > maxLen {
			recalcSize(label.text)
		}
		minimumValueImage = label.imageFromLayerWithTransform(tran)
	}
}
