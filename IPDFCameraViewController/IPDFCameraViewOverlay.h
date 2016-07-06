//
//  IPDFCameraViewOverlay.h
//  InstaPDF
//
//  Created by Maximilian Mackh on 06/01/15.
//  Copyright (c) 2015 mackh ag. All rights reserved.
//


#ifndef IPDFCameraViewOverlay_h
#define IPDFCameraViewOverlay_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OverlayFrame : UIView

@property (nonatomic, assign) void(^overlayRenderHandler)(CGContextRef ctx, CGRect rect, CGPoint topLeft, CGPoint topRight, CGPoint bottomLeft, CGPoint bottomRight);

-(void) updateFrame:(CIRectangleFeature *)rectFeature rawRect:(CGSize)rawRect;
-(void) clearOverlayFrame;
-(NSArray *) getLastFeatures;
-(void) setFrameStyle:(UIColor *)fill borderColor:(UIColor *)stroke borderWidth:(float)width;

@end

#endif /* IPDFCameraViewOverlay_h */
