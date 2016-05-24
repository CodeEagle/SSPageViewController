//
//  ViewController.swift
//  SSPageView
//
//  Created by LawLincoln on 16/3/11.
//  Copyright © 2016年 Luoo. All rights reserved.
//

import UIKit
import SSPageViewController

final class ViewController: UIViewController {

	typealias Template = SSTableView
	private var scrollView: SSPageViewController<Template, ViewController>!

	private var contexts: [String: SSTableContext]!

	override func viewDidLoad() {
		super.viewDidLoad()
		contexts = [:]
		contexts["1"] = SSTableContext(idf: "1", next: "2", previous: nil)
		contexts["2"] = SSTableContext(idf: "2", next: "3", previous: "1")
		contexts["3"] = SSTableContext(idf: "3", next: "4", previous: "2")
		contexts["4"] = SSTableContext(idf: "4", next: nil, previous: "3")

		scrollView = SSPageViewController(scrollDirection: .Horizontal)
		let obk = contexts["1"]
		scrollView.segment.sectionTitles = ["a", "b", "c", "d"]
		scrollView.segment.selectionIndicatorLocation = .Down
		scrollView.segment.selectionIndicatorColor = UIColor.orangeColor()
		scrollView.segment.selectedSegmentIndex = 0
		scrollView.showsSegment = true
		scrollView.configurationBlock = {
			(display, _) -> Void in
			display.context = obk
		}
		var previousIndex = 0
		scrollView.segment.indexChangeBlock = {
			[weak self] index in
			guard let sself = self else { return }

			let direction: UIPageViewControllerNavigationDirection = Int(index) > previousIndex ? .Forward : .Reverse
			previousIndex = Int(index)
			let key = "\(index + 1)"
			let context = sself.contexts[key]
			sself.scrollView.scrollTo({ (template) -> Template in
				let t = template
				t.context = context
				return t
				}, direction: direction)
		}
		automaticallyAdjustsScrollViewInsets = false
		view.addSubview(scrollView.view)
		scrollView.view.snp_makeConstraints { (make) -> Void in
			make.top.equalTo(view).offset(64)
			make.left.bottom.right.equalTo(view)
		}
		scrollView.ss_delegate = self
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

extension ViewController: SSPageViewDelegate {

	func pageView(pageView: SSPageViewController<Template, ViewController>, configureForView view: Template, afterView: Template) {
		if let idf = afterView.ss_nextId {
			view.context = contexts[idf]
//			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { [weak self]() -> Void in
//				view.context = self?.contexts[idf]
//			}
		}
	}

	func pageView(pageView: SSPageViewController<Template, ViewController>, configureForView view: Template, beforeView: Template) {
		if let idf = beforeView.ss_previousId {
			view.context = contexts[idf]
//			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { [weak self]() -> Void in
//				view.context = self?.contexts[idf]
//			}
		}
	}

	func pageView(pageView: SSPageViewController<Template, ViewController>, didScrollToView view: Template) {
	}
}

public class SSTableView: UITableView {

	convenience public required init() {
		self.init(frame: CGRectZero, style: .Plain)
		separatorStyle = .None
	}

	public weak var context: SSTableContext? {
		didSet {
			delegate = context
			dataSource = context
			reloadData()
		}
	}

	override init(frame: CGRect, style: UITableViewStyle) {
		super.init(frame: frame, style: style)
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
}

public final class SSTableContext: NSObject {
	public let identifer: String
	public let nextId: String?
	public let previousId: String?

	init(idf: String, next: String?, previous: String?) {
		identifer = idf
		nextId = next
		previousId = previous
		super.init()
	}
}

extension SSTableContext: UITableViewDataSource, UITableViewDelegate {

	public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return Int(identifer) ?? 0
	}

	public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("cell")
		if cell == nil {
			cell = UITableViewCell(style: .Default, reuseIdentifier: "cell")
		}
		cell?.textLabel?.text = "\(indexPath.row)"
		return cell!
	}
}

extension SSTableView: SSPageViewContentProtocol {
	public var ss_identifer: String { return context?.identifer ?? "" }
	public var ss_previousId: String? { return context?.previousId }
	public var ss_nextId: String? { return context?.nextId }
	public var ss_content: UIView { return self }
}