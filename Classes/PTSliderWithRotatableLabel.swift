//
//  PTSliderWithValue.swift
//  Thundershot
//
//  Created by гык-sse2 on 03.06.15.
//
//

import UIKit

@IBDesignable
public class PTSliderWithRotatableLabel : UISlider {
	private var minLabel = UILabel()
	private var maxLabel = UILabel()
	private var tran = CGAffineTransformIdentity
	
	public var labelTransform : CGAffineTransform {
		get {
			return tran
		}
		set (newTransform) {
			tran = newTransform
			refresh()
		}
	}
	
	required public init(coder aDecoder: NSCoder) {
		minLabel.font = UIFont(name: "Helvetica", size: 12)
		maxLabel.font = UIFont(name: "Helvetica", size: 12)
		minLabel.textColor = UIColor(white: 1, alpha: 1)
		maxLabel.textColor = UIColor(white: 1, alpha: 1)
		super.init(coder: aDecoder)
	}
	
	public override init(frame: CGRect) {
		minLabel.font = UIFont(name: "Helvetica", size: 12)
		maxLabel.font = UIFont(name: "Helvetica", size: 12)
		minLabel.textColor = UIColor(white: 1, alpha: 1)
		maxLabel.textColor = UIColor(white: 1, alpha: 1)
		super.init(frame: frame)
	}
	
	private func refresh() {
		minLabel.sizeToFit()
		minimumValueImage = minLabel.imageFromLayerWithTransform(tran)
		maxLabel.sizeToFit()
		maximumValueImage = maxLabel.imageFromLayerWithTransform(tran)
	}
	
	@IBInspectable
	public var minimumValueText : String? {
		get {
			return minLabel.text
		}
		set (newText) {
			minLabel.text = newText
			minLabel.sizeToFit()
			minimumValueImage = minLabel.imageFromLayerWithTransform(tran)
		}
	}
	
	@IBInspectable
	public var maximumValueText : String? {
		get {
			return maxLabel.text
		}
		set (newText) {
			maxLabel.text = newText
			maxLabel.sizeToFit()
			maximumValueImage = maxLabel.imageFromLayerWithTransform(tran)
		}
	}
}
