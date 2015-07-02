//
//  UISwitchButton.swift
//  Thundershot
//
//  Created by гык-sse2 on 28.06.15.
//
//

import UIKit

class UISwitchButton: UIButton {
	required init(coder aDecoder: NSCoder) {
		super.init(coder:aDecoder)
		self.addTarget(self, action:"onClick", forControlEvents: UIControlEvents.TouchUpInside)
	}
	
	@IBAction func onClick() {
		self.selected = !self.selected
		self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
	}
}
