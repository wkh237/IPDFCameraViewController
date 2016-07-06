//
//  IPDFCameraViewController.h
//  InstaPDF
//
//  Created by Maximilian Mackh on 06/01/15.
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,IPDFCameraViewType)
{
    IPDFCameraViewTypeBlackAndWhite,
    IPDFCameraViewTypeNormal
};

typedef void(^RenderBlock)(CGContextRef ctx, CGRect rect, CGPoint topLeft, CGPoint topRight, CGPoint bottomLeft, CGPoint bottomRight);

@interface IPDFCameraViewController : UIView

- (void)setupCameraView;

- (void)start;
- (void)stop;

@property (nonatomic,assign,getter=isBorderDetectionEnabled) BOOL enableBorderDetection;
@property (nonatomic,assign,getter=isTorchEnabled) BOOL enableTorch;

@property (nonatomic, assign) float refreshInterval;
@property (nonatomic, assign) BOOL postEdit;
@property (nonatomic, assign) RenderBlock overlayRenderBlock;

@property (nonatomic,assign) IPDFCameraViewType cameraViewType;

- (void)setEnableBorderDetection:(BOOL)enable;
- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)())completionHandler;
- (void)captureImageWithCompletionHander:(void(^)(NSString *imageFilePath))completionHandler;
- (void)captureImageForPostEditWithCompletionHander:(void(^)(NSString *imgPath, NSArray *features))handler;
- (void)setBorderDetectionFrameStyle:(UIColor *)fill border:(UIColor *)borderColor borderWidth:(float) width;

@end
