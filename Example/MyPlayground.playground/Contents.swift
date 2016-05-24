//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"
typealias ConfigureBlock = () -> UIImageView
var block: (ConfigureBlock) -> UIImageView = {
    imageBlock -> UIImageView in
    let image = imageBlock()
    return image
}

var a: Int?
a
