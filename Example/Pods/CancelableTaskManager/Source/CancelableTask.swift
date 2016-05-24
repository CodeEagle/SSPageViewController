//
//  CancelableTask.swift
//  LuooFM
//
//  Created by LawLincoln on 16/2/26.
//  Copyright © 2016年 LawLincoln. All rights reserved.
//

import Foundation
//Code From https://gist.github.com/nixzhu/983cedfd05afe9401ba5
//MARK:- CancelableTask

public typealias CancelableTask = (cancel: Bool) -> Void

public struct CancelableTaskManager {

	public static func delay(time: NSTimeInterval, work: dispatch_block_t) -> CancelableTask? {

		var finalTask: CancelableTask?

		let cancelableTask: CancelableTask = { cancel in
			if cancel {
				finalTask = nil // key
			} else {
				dispatch_async(dispatch_get_main_queue(), work)
			}
		}

		finalTask = cancelableTask

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
			if let task = finalTask {
				task(cancel: false)
			}
		}

		return finalTask
	}

	public static func cancel(cancelableTask: CancelableTask?) {
		cancelableTask?(cancel: true)
	}
}
