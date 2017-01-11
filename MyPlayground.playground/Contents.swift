//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

var _map = [Int: String]()
_map[0] = "item0"
_map[1] = "item1"
_map[2] = "item2"
_map[3] = "item3"
_map[4] = "item4"
_map[5] = "item5"
let _loopDisplay = true
typealias Back = (value: String?, target: Int?, targetNext: Int?, targetPreviousId:Int?)
func itemAfter(_ id: Int, after: Bool = false) -> Back {
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


let one = itemAfter(0)
let two = itemAfter(1)
let three = itemAfter(2)
let four = itemAfter(3)
let five = itemAfter(4)
let zero = itemAfter(5)


