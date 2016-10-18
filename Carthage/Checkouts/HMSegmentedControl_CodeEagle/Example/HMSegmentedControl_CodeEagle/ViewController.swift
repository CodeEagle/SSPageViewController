//
//  ViewController.swift
//  HMSegmentedControl_CodeEagle
//
//  Created by CodeEagle on 03/16/2016.
//  Copyright (c) 2016 CodeEagle. All rights reserved.
//

import UIKit
import HMSegmentedControl_CodeEagle
class ViewController: UIViewController {
    override func loadView() {
        view = UIView()
    }

	fileprivate var segmentControl: HMSegmentedControl_CodeEagle!
	override func viewDidLoad() {
		super.viewDidLoad()
		dealSegment()
		// Do any additional setup after loading the view, typically from a nib.
	}

    
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func dealSegment() {
        view.backgroundColor = UIColor.white
		let mainScreenWidth = UIScreen.main.bounds.width
		let buttons: [HMSegmentTitleConvertible] = ["a", "b", "c", "asdflkasdfma", "e", "f", "g", "h"]
		segmentControl = HMSegmentedControl_CodeEagle(sectionTitles: buttons)
		segmentControl.toggleMatchTitle(buttons.first, hide: false)
//		segmentControl.backgroundColor = UIColor.orangeColor()
		segmentControl?.frame = CGRect(x: 0, y: 64, width: mainScreenWidth, height: 44)
		segmentControl?.selectionIndicatorLocation = .down
		segmentControl?.selectionIndicatorColor = UIColor.red
		segmentControl?.segmentWidthStyle = .dynamic
		segmentControl?.selectedSegmentIndex = 0
		segmentControl?.segmentEdgeInset = UIEdgeInsetsMake(0, 10, 0, 10)
		segmentControl?.titleTextAttributes = [
			NSForegroundColorAttributeName: UIColor.black,
			NSFontAttributeName: UIFont.systemFont(ofSize: 15)
		]
		segmentControl?.selectedTitleTextAttributes = [
			NSForegroundColorAttributeName: UIColor.black,
			NSFontAttributeName: UIFont.systemFont(ofSize: 15)
		]
		segmentControl?.selectionIndicatorHeight = 2

		segmentControl?.indexChangeBlock = { [weak self]
			nextIndex in
//			guard let sself = self else { return }
//			sself.segmentControl.toggleMatchTitle(buttons[Int(nextIndex)], hide: true)
		}
		view.addSubview(segmentControl!)
	}
}
