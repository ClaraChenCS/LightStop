//
//  JSQMessage.swift
//  Vidabase
//
//  Created by Carlos Martinez on 4/15/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//
//  Extension of Class to add propertiy to existing class:
//  http://stackoverflow.com/questions/24133058/is-there-a-way-to-set-associated-objects-in-swift

import Foundation
import  JSQMessagesViewController

// Declare a global var to produce a unique address as the assoc object handle
var AssociatedObjectHandle: UInt8 = 0

extension JSQMessage {
    public var avatar: UIImage? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectHandle) as? UIImage
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}