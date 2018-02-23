//
//  CodableMatrix4.swift
//  ARUcoTest
//
//  Created by Nat Wales on 2/22/18.
//  Copyright © 2018 HHCC. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

struct CodableSceneObject: Codable {
    private let m11: Float
    private let m12: Float
    private let m13: Float
    private let m14: Float
    private let m21: Float
    private let m22: Float
    private let m23: Float
    private let m24: Float
    private let m31: Float
    private let m32: Float
    private let m33: Float
    private let m34: Float
    private let m41: Float
    private let m42: Float
    private let m43: Float
    private let m44: Float
    let id: String
    
    var transform: SCNMatrix4 {
        return SCNMatrix4(m11: m11, m12: m12, m13: m13, m14: m14, m21: m21, m22: m22, m23: m23, m24: m24, m31: m31, m32: m32, m33: m33, m34: m34, m41: m41, m42: m42, m43: m43, m44: m44);
    }
    
    init(matrix: SCNMatrix4, objectId: String ) {
        m11 = matrix.m11;
        m12 = matrix.m12;
        m13 = matrix.m13;
        m14 = matrix.m14;
        m21 = matrix.m21;
        m22 = matrix.m22;
        m23 = matrix.m23;
        m24 = matrix.m24;
        m31 = matrix.m31;
        m32 = matrix.m32;
        m33 = matrix.m33;
        m34 = matrix.m34;
        m41 = matrix.m41;
        m42 = matrix.m42;
        m43 = matrix.m43;
        m44 = matrix.m44;
        id = objectId;
    }
    
}
