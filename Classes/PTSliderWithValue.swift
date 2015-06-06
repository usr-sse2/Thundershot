//
//  PTSliderWithValue.swift
//  Thundershot
//
//  Created by гык-sse2 on 03.06.15.
//
//

import UIKit

public class PTSliderWithValue: UISlider {
	private var maxLen = 0
	private var label = UILabel()
	private var _toStringLambda : ((Float) -> String) = {
		(v : Float) -> String in
		return String(format: "%f", v)
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
			let minSize = count(minString), maxSize = count(maxString);
			
			label.text = minSize > maxSize ? minString : maxString
			maxLen = max(minSize, maxSize)
		}
		else {
			label.text = example
			maxLen = count(example!)
		}
		label.sizeToFit()
	}
	
	required public init(coder aDecoder: NSCoder) {
		label.font = UIFont(name: "Helvetica", size: 11)
		label.textColor = UIColor(white: 1, alpha: 1)
		super.init(coder: aDecoder)
		continuous = true
		recalcSize()
		onValueChanged()
		self.addTarget(self, action:"onValueChanged", forControlEvents: UIControlEvents.ValueChanged)
	}
	
	@IBAction func onValueChanged () {
		label.text = toStringLambda(value)
		if count(label.text!) > maxLen {
			recalcSize(example: label.text)
		}
		minimumValueImage = label.imageFromLayer()
	}
}
