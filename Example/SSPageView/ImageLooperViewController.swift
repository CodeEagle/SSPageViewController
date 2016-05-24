//
//  ImageLooperViewController.swift
//  SSPageView
//
//  Created by LawLincoln on 16/3/15.
//  Copyright © 2016年 CocoaPods. All rights reserved.
//

import UIKit
import SSPageViewController
final class ImageLooperViewController: UIViewController {

	private lazy var tableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Plain)

	let images = [
		["http://7xkszy.com2.z0.glb.qiniucdn.com/pics/vol/56e04233bae99.jpg?imageView2/1/w/640/h/452",
			"http://i2.pixiv.net/c/480x960/img-master/img/2010/01/24/09/58/08/8357905_p0_master1200.jpg",
			"http://i3.pixiv.net/c/480x960/img-master/img/2011/02/14/09/04/53/16665194_p0_master1200.jpg",
			"http://i1.pixiv.net/c/480x960/img-master/img/2014/08/01/00/08/02/45046588_p0_master1200.jpg"],
		["http://i1.pixiv.net/c/480x960/img-master/img/2011/08/08/23/16/35/20925480_p0_master1200.jpg"],
		["http://i4.pixiv.net/c/480x960/img-master/img/2011/04/23/23/13/47/18356651_p0_master1200.jpg"],
		["http://i3.pixiv.net/c/480x960/img-master/img/2014/10/24/09/16/02/46703818_p0_master1200.jpg"],
		["http://i2.pixiv.net/c/480x960/img-master/img/2010/01/24/09/58/08/8357905_p0_master1200.jpg"],
		["http://7xkszy.com2.z0.glb.qiniucdn.com/pics/vol/56dc30bf5ea1d.jpg?imageView2/1/w/640/h/452"],
		["http://i3.pixiv.net/c/480x960/img-master/img/2011/02/14/09/04/53/16665194_p0_master1200.jpg"],
		["http://i4.pixiv.net/c/480x960/img-master/img/2015/08/31/15/17/31/52292387_p0_master1200.jpg"],
		["http://i1.pixiv.net/c/480x960/img-master/img/2014/08/01/00/08/02/45046588_p0_master1200.jpg"],
		["http://i4.pixiv.net/c/480x960/img-master/img/2008/12/16/17/04/37/2422079_p0_master1200.jpg",
			"http://i4.pixiv.net/c/480x960/img-master/img/2011/04/23/23/13/47/18356651_p0_master1200.jpg"]
	]

	override func viewDidLoad() {
		super.viewDidLoad()
		view.addSubview(tableView)
		tableView.registerClass(ImageLoopCell.self, forCellReuseIdentifier: ImageLoopCell.idf)
		tableView.delegate = self
		tableView.dataSource = self
		tableView.snp_makeConstraints { (make) -> Void in
			make.left.bottom.right.equalTo(view)
			make.top.equalTo(view).offset(64)
		}
		automaticallyAdjustsScrollViewInsets = false
		// Do any additional setup after loading the view.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

extension ImageLooperViewController: UITableViewDataSource, UITableViewDelegate {
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return images.count
	}

	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 300
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(ImageLoopCell.idf) as? ImageLoopCell
		cell?.configure(images[indexPath.row])
		return cell!
	}
}

private class ImageLoopCell: UITableViewCell {

	static let idf = "cell"

	private var manager: SSAdBannerManager!

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: .Default, reuseIdentifier: ImageLoopCell.idf)
		manager = SSAdBannerManager()
		contentView.addSubview(manager.view)
		manager.view.snp_makeConstraints { (make) -> Void in
			make.top.left.bottom.right.equalTo(contentView)
		}
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	func configure(list: [String], scroll: Bool = true) {
		manager.reset(list, loop: scroll)
	}
}
