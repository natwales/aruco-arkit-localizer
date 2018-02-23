//
//  OpenCVWrapper.h
//  ARKitBasics
//
//  Created by Nat Wales on 9/25/17.
//  Copyright © 2017 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>

@interface OpenCVWrapper : NSObject
+(SCNMatrix4) transformMatrixFromPixelBuffer:(CVPixelBufferRef)pixelBuffer withIntrinsics:(matrix_float3x3)intrinsics andMarkerSize:(Float64)markerSize;
+(UIImage*) getMarkerForId:(int)id;
@end
