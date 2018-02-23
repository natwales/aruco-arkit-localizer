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

struct SceneObject: Codable {
    let m11: Float
    let m12: Float
    let m13: Float
    let m14: Float
    let m21: Float
    let m22: Float
    let m23: Float
    let m24: Float
    let m31: Float
    let m32: Float
    let m33: Float
    let m34: Float
    let m41: Float
    let m42: Float
    let m43: Float
    let m44: Float
    let id: Int
    
    init(matrix: SCNMatrix4, objectId: Int ) {
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
    }
    
    func getMatrix() -> SCNMatrix4 {
        let matrix = SCNMatrix4(m11: m11, m12: m12, m13: m13, m14: m14, m21: m21, m22: m22, m23: m23, m24: m24, m31: m31, m32: m32, m33: m33, m34: m34, m41: m41, m42: m42, m43: m43, m44: m44);
        
        return matrix;
    }
}
