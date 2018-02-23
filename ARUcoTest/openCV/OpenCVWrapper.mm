//
//  OpenCVWrapper.m
//  ARKitBasics
//
//  Created by Nat Wales on 9/25/17.
//  Copyright © 2017 Apple. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/core.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc/imgproc.hpp>
#include "opencv2/aruco.hpp"
#include "opencv2/aruco/dictionary.hpp"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <CoreVideo/CoreVideo.h>

#include  "OpenCVWrapper.h"

using namespace std;

@implementation OpenCVWrapper


+(UIImage*) getMarkerForId:(int)id {
    cv::Mat markerImage;
    cv::Ptr<cv::aruco::Dictionary> dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_6X6_250);
    cv::aruco::drawMarker(dictionary, id, 400, markerImage);
    UIImage *finalImage = MatToUIImage(markerImage);
    return finalImage;
}

//http://answers.opencv.org/question/23089/opencv-opengl-proper-camera-pose-using-solvepnp/

+(SCNMatrix4) transformMatrixFromPixelBuffer:(CVPixelBufferRef)pixelBuffer withIntrinsics:(matrix_float3x3)intrinsics andMarkerSize:(Float64)markerSize {
    
    cv::Mat intrinMat(3,3,CV_64F);
    cv::Mat distMat(3,3,CV_64F);
    
    intrinMat.at<Float64>(0,0) = intrinsics.columns[0][0];
    intrinMat.at<Float64>(0,1) = intrinsics.columns[1][0];
    intrinMat.at<Float64>(0,2) = intrinsics.columns[2][0];
    intrinMat.at<Float64>(1,0) = intrinsics.columns[0][1];
    intrinMat.at<Float64>(1,1) = intrinsics.columns[1][1];
    intrinMat.at<Float64>(1,2) = intrinsics.columns[2][1];
    intrinMat.at<Float64>(2,0) = intrinsics.columns[0][2];
    intrinMat.at<Float64>(2,1) = intrinsics.columns[1][2];
    intrinMat.at<Float64>(2,2) = intrinsics.columns[2][2];
    
    distMat.at<Float64>(0,0) = 0;
    distMat.at<Float64>(0,1) = 0;
    distMat.at<Float64>(0,2) = 0;
    distMat.at<Float64>(0,3) = 0;
    
    cv::Ptr<cv::aruco::Dictionary> dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_6X6_250);
    
    // The first plane / channel (at index 0) is the grayscale plane
    // See more infomation about the YUV format
    // http://en.wikipedia.org/wiki/YUV
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    CGFloat width = CVPixelBufferGetWidth(pixelBuffer);
    CGFloat height = CVPixelBufferGetHeight(pixelBuffer);
    cv::Mat mat(height, width, CV_8UC1, baseaddress, 0); //CV_8UC1
    
    std::vector<int> ids;
    std::vector<std::vector<cv::Point2f>> corners;
    cv::aruco::detectMarkers(mat,dictionary,corners,ids);
    
    if(ids.size() > 0) {
        //cv::Mat colorMat;
        //cv::cvtColor(mat, colorMat, CV_GRAY2RGB);
        //cv::aruco::drawDetectedMarkers(colorMat, corners, ids, cv::Scalar(0,255,24));
        std::vector<cv::Vec3d> rvecs, tvecs;
        cv::Mat distCoeffs = cv::Mat::zeros(8, 1, CV_64F); //zero out distortion for now
        cv::aruco::estimatePoseSingleMarkers(corners, markerSize, intrinMat, distCoeffs, rvecs, tvecs);
        //cv::aruco::drawAxis(colorMat, intrinMat, distCoeffs, rvecs[0], tvecs[0], 0.14);
        //UIImage *finalImage = MatToUIImage(colorMat); //just for testing
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
        //Todo : somehow handle situation with multiple markers - just grab first I suppose
        
        cv::Mat rotMat, tranMat;
        cv::Rodrigues(rvecs, rotMat); //convert results rotation matrix
        cv::Mat extrinsics(4, 4, CV_64F);
        
        for( int row = 0; row < rotMat.rows; row++) {
            for (int col = 0; col < rotMat.cols; col++) {
                extrinsics.at<double>(row,col) = rotMat.at<double>(row,col); //copy rotation matrix values
            }
            extrinsics.at<double>(row,3) = tvecs[0][row];
        }
        extrinsics.at<double>(3,3) = 1;
        
        //The important thing to remember about the extrinsic matrix is that it describes how the world is transformed relative to the camera. This is often counter-intuitive, because we usually want to specify how the camera is transformed relative to the world.
        
        // Convert coordinate systems of opencv to openGL (SceneKit)
        extrinsics = [OpenCVWrapper GetCVToGLMat] * extrinsics;
        
        return [OpenCVWrapper transformToSceneKitMatrix:extrinsics];
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return SCNMatrix4Identity;
}

// Note that in openCV z goes away the camera (in openGL goes into the camera)
// and y points down and on openGL point up
+(cv::Mat) GetCVToGLMat {
    cv::Mat cvToGL = cv::Mat::zeros(4,4,CV_64F);
    cvToGL.at<double>(0,0) = 1.0f;
    cvToGL.at<double>(1,1) = -1.0f; //invert y
    cvToGL.at<double>(2,2) = -1.0f; //invert z
    cvToGL.at<double>(3,3) = 1.0f;
    return cvToGL;
}

+(SCNMatrix4) transformToSceneKitMatrix:(cv::Mat&) openCVTransformation {
    SCNMatrix4 mat = SCNMatrix4Identity;
    
    //Transpose (think this is to switch from col order to row order matrix)
    openCVTransformation = openCVTransformation.t();
    
    //copy rotation rows
    // copy the rotationRows
    mat.m11 = (float) openCVTransformation.at<double>(0, 0);
    mat.m12 = (float) openCVTransformation.at<double>(0, 1);
    mat.m13 = (float) openCVTransformation.at<double>(0, 2);
    mat.m14 = (float) openCVTransformation.at<double>(0, 3);
    
    mat.m21 = (float)openCVTransformation.at<double>(1, 0);
    mat.m22 = (float)openCVTransformation.at<double>(1, 1);
    mat.m23 = (float)openCVTransformation.at<double>(1, 2);
    mat.m24 = (float)openCVTransformation.at<double>(1, 3);
    
    mat.m31 = (float)openCVTransformation.at<double>(2, 0);
    mat.m32 = (float)openCVTransformation.at<double>(2, 1);
    mat.m33 = (float)openCVTransformation.at<double>(2, 2);
    mat.m34 = (float)openCVTransformation.at<double>(2, 3);
    
    //copy the translation row
    mat.m41 = (float)openCVTransformation.at<double>(3, 0);
    mat.m42 = (float)openCVTransformation.at<double>(3, 1);
    mat.m43 = (float)openCVTransformation.at<double>(3, 2);
    mat.m44 = (float)openCVTransformation.at<double>(3, 3);
    
    return mat;
}

@end
