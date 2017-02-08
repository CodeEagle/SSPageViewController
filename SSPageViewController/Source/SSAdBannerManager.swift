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
    public var indicatorLocationPercantage: ((Float) -> ())? {
        didSet {
            if indicatorLocationPercantage != nil {
                _pageController.showsIndicator = false
            }
        }
    }
	public var backgroundColor: UIColor? {
		didSet {
			_pageController.view.backgroundColor = backgroundColor
			_pageController.scrollView.backgroundColor = backgroundColor
            _pageController.initializeTemplateConfiguration = {
                [weak self](display, backup) in
                guard let sself = self else { return }
                display.layer.backgroundColor = sself.backgroundColor?.cgColor
                backup.layer.backgroundColor = sself.backgroundColor?.cgColor
            }
		}
	}
	public var view: UIView { return _pageController.view }

	public var imageContentMode: UIViewContentMode = .scaleAspectFit {
		didSet {
			_pageController.initializeTemplateConfiguration = {
				[weak self](display, backup) in
				guard let sself = self else { return }
				display.imageContentMode = sself.imageContentMode
				backup.imageContentMode = sself.imageContentMode
			}
		}
	}
    
    public var placeHolderImage: UIImage? {
        didSet {
            _pageController.initializeTemplateConfiguration = {
                [weak self](display, backup) in
                guard let sself = self else { return }
                display.placeHolderImage = sself.placeHolderImage
                backup.placeHolderImage = sself.placeHolderImage
                if display.image == nil {
                    display.image = display.placeHolderImage
                    display.contentMode = display.placeHolderMode
                }
                if backup.image == nil {
                    backup.image = backup.placeHolderImage
                    display.contentMode = display.placeHolderMode
                }
            }
        }
    }
    public var placeHolderMode: UIViewContentMode = .scaleAspectFit {
        didSet {
            _pageController.initializeTemplateConfiguration = {
                [weak self](display, backup) in
                guard let sself = self else { return }
                display.placeHolderMode = sself.placeHolderMode
                backup.placeHolderMode = sself.placeHolderMode
                if display.image == display.placeHolderImage {
                    display.contentMode = display.placeHolderMode
                }
                if backup.image == backup.placeHolderImage {
                    backup.contentMode = backup.placeHolderMode
                }
            }
        }
    }

	// MARK:- Private
	fileprivate lazy var _pageController: SSPageViewController<SSAdBannerManager.Template, SSAdBannerManager> = SSPageViewController(scrollDirection: .horizontal)
	fileprivate lazy var _loopDisplay = true
	fileprivate lazy var _map: [Int: String] = [:]
    fileprivate lazy var _indexCache: [Int : Int] = [:]
	fileprivate lazy var _hash = 0
    fileprivate var _index = 0
    

	deinit { _pageController.ss_delegate = nil }

	public override init() {
		super.init()
		backgroundColor = UIColor.white
		_pageController.indicatorAlignStyle = .center
		_pageController.ss_delegate = self
		_pageController.showsIndicator = true
        _pageController.currentOffset = {[weak self] offset in self?.deal(scroll: offset) }
	}

    fileprivate func deal(scroll offset: CGFloat) {
        
        let length = _pageController.itemLength
        let total =  length * CGFloat(_map.count)
        let realOffset = offset - length
        let current = CGFloat(_index) * length + realOffset
        if realOffset >= length {
            if _index == _pageController.indicator.currentPage {
                _index = _pageController.indicator.currentPage + 1
                if _index >= _map.count { _index = 0 }
            }
        } else if realOffset <= -length {
            if _index == _pageController.indicator.currentPage {
                _index = _pageController.indicator.currentPage - 1
                if _index < 0 { _index = _map.count - 1 }
            }
        }
        let percentage = current / total
        indicatorLocationPercantage?(Float(percentage))
    }
    
	public func reset(_ list: [String], loop: Bool = false) {
		var map = [Int: String]()
		for (index, item) in list.enumerated() { map[index] = item }
		let canScoll = list.count > 1
		_pageController.indicator.numberOfPages = list.count
		_loopDisplay = canScoll
		_map = map

		var indicatorIndex = 0
		if list.count > 1 {
			let total = list.joined(separator: ",")
			_hash = total.hash
			if let _index = _indexCache[_hash] { indicatorIndex = _index }
            else { _indexCache[_hash] = 0 }
		}
		_pageController.indicator.currentPage = indicatorIndex
        indicatorLocationPercantage?(Float(indicatorIndex) / Float(list.count))
		_pageController.configurationBlock = { [weak self]
			(display, backup) -> Void in
			guard let sself = self else { return }
			display.tapBlock = nil
			backup.tapBlock = nil
			let handler: (Int) -> Void = { [weak self]
				index in
				self?.didTapBannerHandler?(index)
			}
			if list.count <= indicatorIndex { return }
            let item = sself.getItemBefore(id: indicatorIndex + 1)
			display.configure(item)
			display.tapBlock = handler
			if list.count <= indicatorIndex + 1 { return }
            let item2 = sself.getItemBefore(id: indicatorIndex + 2)
			backup.configure(item2)
			backup.tapBlock = handler
		}
		_pageController.loopInterval = canScoll ? (loop ? 5 : 0) : 0
	}

	public func getItemBefore(after: Bool = false, id: Int) -> (String?, Int?, Int?, Int?) {
		if id < 0 { return (nil, nil, nil, nil) }
		let count = _map.count
		var nextId: Int? = nil
		var previousId: Int? = nil
		if count == 1 { return (_map[0], 0, nil, nil) }
		var now: Int?
		if after {
			if id >= count - 1 { if _loopDisplay { now = 0 } }
            else { now = id + 1 }
		} else {
			if id == 0 { if _loopDisplay { now = count - 1 } }
            else { now = id - 1 }
		}
		guard let nowId = now else { return (nil, now, nextId, previousId) }
		let value = _map[nowId]
		if count == 1 { return (value, now, nextId, previousId) }
		if nowId >= count - 1 { if _loopDisplay { nextId = 0 } }
        else { nextId = nowId + 1 }
		if nowId == 0 { if _loopDisplay { previousId = count - 1 } }
        else { previousId = nowId - 1 }
		return (value, nowId, nextId, previousId)
	}
}
// MARK: - SSPageViewDelegate
extension SSAdBannerManager: SSPageViewDelegate {

	public func pageView(_ pageView: SSPageViewController<Template, SSAdBannerManager>, configureForView view: Template, beforeView: Template) {
		guard let value = Int(beforeView.ss_identifer) else { return }
        view.configure(getItemBefore(id: value))
	}

	public func pageView(_ pageView: SSPageViewController<Template, SSAdBannerManager>, configureForView view: Template, afterView: Template) {
		guard let value = Int(afterView.ss_identifer) else { return }
		view.configure(getItemBefore(after: true, id: value))
	}

	public func pageView(_ pageView: SSPageViewController<Template, SSAdBannerManager>, didScrollToView view: Template) {
		guard let value = Int(view.ss_identifer) else { return }
		_pageController.indicator.currentPage = value
        _index = value
        deal(scroll: _pageController.itemLength)
		if _map.count > 1 { _indexCache[_hash] = value }
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
    fileprivate var placeHolderImage: UIImage?
    fileprivate var placeHolderMode: UIViewContentMode = .scaleAspectFit
    fileprivate var imageContentMode: UIViewContentMode = .scaleAspectFit
    
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
        identifer = con.id?.ss_string
        nextId = con.next?.ss_string
        previousId = con.previous?.ss_string
        _task?.cancel()
        guard let u = con.url else { return }
        if _url == u && image != nil && image != placeHolderImage { return }
        image = placeHolderImage
        contentMode = placeHolderMode
        DispatchQueue.global(qos: .userInitiated).async {
            self._url = u
            guard let url = URL(string: u) else { return }
            let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20)
            if let data = URLCache.shared.cachedResponse(for: request)?.data, let img = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.contentMode = self.imageContentMode
                    self.image = img
                }
                return
            }
            self._task = URLSession.shared.dataTask(with: request, completionHandler: { (data, reps, error) in
                guard let data = data, let img = UIImage(data: data) else { return }
                if let hr = reps as? HTTPURLResponse {
                    let cap = CachedURLResponse(response: hr, data: data)
                    URLCache.shared.storeCachedResponse(cap, for: request)
                }
                DispatchQueue.main.async(execute: { [weak self]() -> Void in
                    guard let sself = self else { return }
                    sself.contentMode = sself.imageContentMode
                    UIView.transition(
                        with: sself,
                        duration: 0.1,
                        options: .transitionCrossDissolve,
                        animations: { sself.image = img },
                        completion: nil
                    )
                })
            })
            self._task?.resume()
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
	var ss_string: String { return "\(self)" }
}

protocol StringConvertible {
	var ss_string: String { get }
}
extension String: StringConvertible {
	var ss_string: String { return self }
}
