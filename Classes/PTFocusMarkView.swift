//
//  PTFocusMarkView.swift
//  Thundershot
//
//  Created by гык-sse2 on 17.07.15.
//  Copyright © 2015 PaztalomTechnologiez. All rights reserved.
//

import UIKit

@IBDesignable
class PTFocusMarkView: UIView {
	var willHide = false
	private var pt = CGPointZero
	
	var point : CGPoint {
		get {
			return pt
		}
		set (newPoint) {
			pt = newPoint
			self.setNeedsDisplay()
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		pt = self.center
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		pt = self.center
	}

	override func drawRect(rect: CGRect) {
		super.drawRect(rect)
		let ctx = UIGraphicsGetCurrentContext()
		CGContextSetRGBStrokeColor(ctx, 0xff/255.0, 0xcc/255.0, 0x66/255.0, 1)
		
		CGContextMoveToPoint(ctx, self.pt.x - 50, self.pt.y - 50)
		CGContextAddLineToPoint(ctx, self.pt.x - 50, self.pt.y + 50)
		CGContextAddLineToPoint(ctx, self.pt.x + 50, self.pt.y + 50)
		CGContextAddLineToPoint(ctx, self.pt.x + 50, self.pt.y - 50)
		CGContextAddLineToPoint(ctx, self.pt.x - 50, self.pt.y - 50)
		CGContextStrokePath(ctx)
	}
}
