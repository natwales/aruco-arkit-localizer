//
//  RedBox.swift
//  ARUcoTest
//
//  Created by Nat Wales on 2/23/18.
//  Copyright © 2018 HHCC. All rights reserved.
//

import Foundation
import ARKit

class RedBox : SCNNode {
    
    override init() {
        super.init();
        
        self.geometry = SCNBox(width: 0.0254, height: 0.0254, length: 0.0254, chamferRadius: 0)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.red
        self.geometry?.materials = [mat]
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

