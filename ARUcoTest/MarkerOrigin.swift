//
//  MarkerOriginSCN.swift
//  ARUcoTest
//
//  Created by Nat Wales on 2/23/18.
//  Copyright © 2018 HHCC. All rights reserved.
//

import Foundation
import ARKit

class MarkerOrigin : SCNNode {
    private let markerSize:CGFloat;
    
    init(markerSize:CGFloat) {
        self.markerSize = markerSize;
        super.init();
        renderSelf();
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func renderSelf() {
        //let geo = SCNPlane(width: markerSize, height: markerSize)
        let geo = SCNPyramid(width: markerSize, height: markerSize/2, length: markerSize)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.blue
        self.geometry = geo
        self.geometry?.materials = [mat]
    }
    
}
