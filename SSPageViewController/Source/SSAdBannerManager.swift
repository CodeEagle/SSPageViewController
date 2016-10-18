//
//  SSImageLooper.swift
//  SSPageView
//
//  Created by LawLincoln on 16/3/15.
//  Copyright © 2016年 CocoaPods. All rights reserved.
//

import UIKit

public final class SSAdBannerManager: NSObject {

	public typealias Template = SSBannerItem

	// MARK:- Public
	public var didShowBannerHandler: ((Int) -> Void)?
	public var didTapBannerHandler: ((Int) -> Void)?
	public var backgroundColor: UIColor? {
		didSet {
			_pageController.view.backgroundColor = backgroundColor
			_pageController.scrollView.backgroundColor = backgroundColor
		}
	}
	public var view: UIView { return _pageController.view }

	public var imageContentMode: UIViewContentMode = .scaleAspectFit {
		didSet {
			_pageController.initializeTemplateConfiguration = {
				[weak self](display, backup) in
				guard let sself = self else { return }
				display.contentMode = sself.imageContentMode
				backup.contentMode = sself.imageContentMode
			}
		}
	}

	// MARK:- Private
	fileprivate lazy var _pageController: SSPageViewController<SSAdBannerManager.Template, SSAdBannerManager> = SSPageViewController(scrollDirection: .horizontal)
	fileprivate lazy var _loopDisplay = true
	fileprivate lazy var _map: [Int: String] = [:]
    fileprivate lazy var _indexCache: [Int : Int] = [:]
	fileprivate lazy var _hash = 0

	deinit {
		_pageController.ss_delegate = nil
	}

	public override init() {
		super.init()
		backgroundColor = UIColor.white
		_pageController.indicatorAlignStyle = .center
		_pageController.ss_delegate = self
		_pageController.showsIndicator = true
	}

	public func reset(_ list: [String], loop: Bool = false) {
		var map = [Int: String]()
		for (index, item) in list.enumerated() {
			map[index] = item
		}
		let canScoll = list.count > 1
		_pageController.indicator.numberOfPages = list.count
		_loopDisplay = canScoll

		_map = map

		var indicatorIndex = 0
		if list.count > 1 {
			let total = list.joined(separator: ",")
			_hash = total.hash
			if let _index = _indexCache[_hash] {
				indicatorIndex = _index
			} else {
				_indexCache[_hash] = 0
			}
		}

		_pageController.indicator.currentPage = indicatorIndex
		_pageController.configurationBlock = { [weak self]
			(display, backup) -> Void in
			guard let sself = self else { return }
			backup.image = nil
			display.image = nil
			display.tapBlock = nil
			backup.tapBlock = nil
//			backup.configure((url: nil, id: nil, next: nil, previous: nil))
//			display.configure((url: nil, id: nil, next: nil, previous: nil))
			let handler: (Int) -> Void = { [weak self]
				index in
				self?.didTapBannerHandler?(index)
			}
			if list.count <= indicatorIndex { return }

			let item = sself.itemAfter(indicatorIndex + 1)
			display.configure(item)
			display.tapBlock = handler
			if list.count <= indicatorIndex + 1 { return }
			let item2 = sself.itemAfter(indicatorIndex + 2)
			backup.configure(item2)
			backup.tapBlock = handler
		}
		_pageController.loopInterval = canScoll ? (loop ? 5 : 0) : 0
	}

	public func itemAfter(_ id: Int, after: Bool = false) -> (String?, Int?, Int?, Int?) {
		if id < 0 { return (nil, nil, nil, nil) }
		let count = _map.count
		var nextId: Int? = nil
		var previousId: Int? = nil
		if count == 1 { return (_map[0], 0, nil, nil) }
		var now: Int?
		if after {
			if id >= count - 1 {
				if _loopDisplay {
					now = 0
				}
			} else {
				now = id + 1
			}
		} else {
			if id == 0 {
				if _loopDisplay {
					now = count - 1
				}
			} else {
				now = id - 1
			}
		}
		guard let nowId = now else { return (nil, now, nextId, previousId) }

		let value = _map[nowId]

		if count == 1 { return (value, now, nextId, previousId) }

		if nowId >= count - 1 {
			if _loopDisplay {
				nextId = 0
			}
		} else {
			nextId = nowId + 1
		}
		if nowId == 0 {
			if _loopDisplay {
				previousId = count - 1
			}
		} else {
			previousId = nowId - 1
		}
		return (value, nowId, nextId, previousId)
	}
}
// MARK: - SSPageViewDelegate
extension SSAdBannerManager: SSPageViewDelegate {

	public func pageView(_ pageView: SSPageViewController<Template, SSAdBannerManager>, configureForView view: Template, beforeView: Template) {
		guard let value = Int(beforeView.ss_identifer) else { return }
		view.configure(itemAfter(value))
	}

	public func pageView(_ pageView: SSPageViewController<Template, SSAdBannerManager>, configureForView view: Template, afterView: Template) {
		guard let value = Int(afterView.ss_identifer) else { return }
		view.configure(itemAfter(value, after: true))
	}

	public func pageView(_ pageView: SSPageViewController<Template, SSAdBannerManager>, didScrollToView view: Template) {
		guard let value = Int(view.ss_identifer) else { return }
		_pageController.indicator.currentPage = value
		if _map.count > 1 {
			_indexCache[_hash] = value
		}
		didShowBannerHandler?(value)
	}
}
//MARK:- SSImageLooper
public final class SSBannerItem: UIImageView {

	public typealias DidTapItemClosure = (Int) -> Void

	fileprivate var identifer: String?
	fileprivate var previousId: String?
	fileprivate var nextId: String?
	public var tapBlock: DidTapItemClosure?
	fileprivate var _task: URLSessionDataTask?
	fileprivate var _url = ""

	public convenience init() {
		self.init(frame: CGRect.zero)
		layer.backgroundColor = UIColor.lightGray.cgColor
		contentMode = .scaleAspectFit
		isUserInteractionEnabled = true
		clipsToBounds = true
		let tap = UITapGestureRecognizer(target: self, action: #selector(SSBannerItem.tap))
		addGestureRecognizer(tap)
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	public func configure(_ con: (url: String?, id: Int?, next: Int?, previous: Int?)) {

		autoreleasepool { () -> () in
			image = nil
			_task?.cancel()
            DispatchQueue.global().async {
				guard let u = con.url else { return }
				if self._url == u { return }
				self._url = u
				guard let url = URL(string: u) else { return }
				let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20)
				self._task = URLSession.shared.dataTask(with: request, completionHandler: { (data, reps, error) in
					guard let data = data, let img = UIImage(data: data) else { return }
					DispatchQueue.main.async(execute: { [weak self]() -> Void in
						guard let sself = self else { return }
						UIView.transition(
							with: sself,
							duration: 0.2,
							options: .transitionCrossDissolve,
							animations: { [weak self] in
								self?.image = img
							},
							completion: nil
						)
					})
				})
				self._task?.resume()
			}

			identifer = con.id?.string
			nextId = con.next?.string
			previousId = con.previous?.string
		}
	}

	@objc fileprivate func tap() {
		guard let idf = identifer, let value = Int(idf) else { return }
		tapBlock?(value)
	}
}
// MARK: - SSPageViewContentProtocol
extension SSBannerItem: SSPageViewContentProtocol {
	public var ss_identifer: String {
		return identifer ?? ""
	}
	public var ss_previousId: String? { return previousId }
	public var ss_nextId: String? { return nextId }
	public var ss_content: UIView { return self }
}

extension Int {
	var string: String { return "\(self)" }
}

protocol StringConvertible {
	var ss_string: String { get }
}
extension String: StringConvertible {
	var ss_string: String { return self }
}