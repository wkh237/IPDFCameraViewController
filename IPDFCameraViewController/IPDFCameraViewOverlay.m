//
//  IPDFCameraViewOverlay.m
//  InstaPDF
//
//  Created by Maximilian Mackh on 06/01/15.
//  Copyright (c) 2015 mackh ag. All rights reserved.
//


#import "IPDFCameraViewOverlay.h"

#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

#define SHOW_DEBUGGER_OVERLAY 0

#define textAtPoint(text, point) [text drawAtPoint:CGPointMake(point.x - text.length*3, point.y) withAttributes:[NSDictionary dictionaryWithObjects: \
@[[UIFont fontWithName:@"Helvetica Neue" size:10.0], [UIColor whiteColor]] forKeys:@[NSFontAttributeName, NSForegroundColorAttributeName]]];

#define roundPointStr(point, offsetY) NSStringFromCGPoint(CGPointMake(roundf(point.x), roundf(point.y + offsetY)))

@implementation OverlayFrame {
    CIRectangleFeature * borderRectFeature;
    CGSize rawImageRect;
    NSMutableArray * lastDetectedFeatures;
    CGAffineTransform viewMatrix;
    BOOL drawOverlay;
    NSMutableArray * queue;
    NSMutableArray * rejectedQueue;
    UIColor * frameBorderColor;
    UIColor * frameFillColor;
    float frameBorderWidth;
}

@synthesize overlayRenderHandler;

-(id) init
{
    self = [super init];
    queue = [[NSMutableArray alloc] init];
    rejectedQueue = [[NSMutableArray alloc]init];
    frameBorderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    frameFillColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.4];
    frameBorderWidth = 3;
    lastDetectedFeatures = [[NSMutableArray alloc]init];
    return self;
}

-(NSArray *) getLastFeatures
{
    return lastDetectedFeatures;
}

-(void) setFrameStyle:(UIColor *)fill borderColor:(UIColor *)stroke borderWidth:(float)width
{
    frameBorderWidth = width;
    frameFillColor = fill;
    frameBorderColor = stroke;
    
}

-(BOOL) pointFilter:(NSArray *) features
{
    CGPoint fTopLeft = [[features objectAtIndex:0] CGPointValue];
    CGPoint fTopRight = [[features objectAtIndex:1] CGPointValue];
    CGPoint fBottomLeft = [[features objectAtIndex:2] CGPointValue];
    CGPoint fBottomRight = [[features objectAtIndex:3] CGPointValue];
    
    CGFloat avgX = 0;
    CGFloat avgY = 0;
    
    // compute average
    for(NSArray * p in queue)
    {
        CGPoint topLeft = [[p objectAtIndex:0] CGPointValue];
        CGPoint topRight = [[p objectAtIndex:1] CGPointValue];
        CGPoint bottomLeft = [[p objectAtIndex:2] CGPointValue];
        CGPoint bottomRight = [[p objectAtIndex:3] CGPointValue];
        avgX += topLeft.x + topRight.x + bottomLeft.x + bottomRight.x;
        avgY += topRight.y + topRight.y + bottomRight.y + bottomLeft.y;
    }
    avgX /= queue.count*4;
    avgY /= queue.count*4;
    CGPoint fScore = [self getFeatureScore:fTopLeft topRight:fTopRight bottomLeft:fBottomLeft bottomRight:fBottomRight];
    
    float scoreX = fScore.x / avgX;
    float scoreY = fScore.y / avgY;
    
#if SHOW_DEBUGGER_OVERLAY == 1
    textAtPoint(NSStringFromCGPoint(CGPointMake(roundf(scoreX*100), roundf(scoreY*100))), CGPointMake(self.frame.size.width/2, self.frame.size.height/2 + 24));
#endif
    
    // tolerance 10%
    if(fabs(1 - scoreX) > 0.1 || fabs(1 - scoreY) > 0.1) {
        // when consecutive 9 frames corrected, restart the score base
        if(rejectedQueue.count < 9)
        {
            [rejectedQueue addObject:@[ [NSValue valueWithCGPoint:fTopLeft], [NSValue valueWithCGPoint:fTopRight], [NSValue valueWithCGPoint:fBottomLeft], [NSValue valueWithCGPoint:fBottomRight]]];
        }
        else
        {
            [queue removeAllObjects];
            [rejectedQueue removeAllObjects];
            
        }
        return NO;
    }
    else {
        [rejectedQueue removeAllObjects];
        if(queue.count < 6)
        {
            [queue addObject:@[ [NSValue valueWithCGPoint:fTopLeft], [NSValue valueWithCGPoint:fTopRight], [NSValue valueWithCGPoint:fBottomLeft], [NSValue valueWithCGPoint:fBottomRight]]];
        }
        else
        {
            [queue removeObjectAtIndex:0];
            [queue addObject:@[ [NSValue valueWithCGPoint:fTopLeft], [NSValue valueWithCGPoint:fTopRight], [NSValue valueWithCGPoint:fBottomLeft], [NSValue valueWithCGPoint:fBottomRight]]];
        }
        return YES;
    }
}

-(CGPoint) getFeatureScore:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight
{
    CGFloat avgX = (topLeft.x + topRight.x + bottomLeft.x + bottomRight.x)/4;
    CGFloat avgY = (topRight.y + topRight.y + bottomRight.y + bottomLeft.y)/4;
    return CGPointMake(avgX, avgY);
}

-(void) updateFrame:(CIRectangleFeature *)rectFeature rawRect:(CGSize)rawRect
{
    borderRectFeature = rectFeature;
    rawImageRect = rawRect;
    drawOverlay = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsDisplay];
    });
}

-(void) drawRect:(CGRect)rect
{
    if(borderRectFeature == nil) {
        return;
    }
    
    
    if(drawOverlay == NO)
    {
        #if SHOW_DEBUGGER_OVERLAY == 1
        [self drawDebugLayer:UIGraphicsGetCurrentContext() rect:rect text:@"NO REGION DETECTED"];
        #endif
    }
    else
    {
        #if SHOW_DEBUGGER_OVERLAY == 1
        [self drawDebugLayer:UIGraphicsGetCurrentContext() rect:rect text:@"TEST MODE"];
        #endif
        [self drawOVerlay:UIGraphicsGetCurrentContext() rect:rect ];
    }
    
}

-(void) drawDebugLayer:(CGContextRef)ctx rect:(CGRect)rect text:(NSString *)text
{

#if SHOW_DEBUGGER_OVERLAY == 1
    textAtPoint(text, CGPointMake(rect.size.width/2, rect.size.height/2));
    CGContextSetFillColorWithColor(ctx, frameFillColor.CGColor);
    CGContextSetRGBFillColor(ctx, 0.0, 1.0, 0.0, 1.0);
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetRGBFillColor(ctx, 0, 0, 1, 0.25);
    CGContextFillRect(ctx, CGRectMake(0, 0, rect.size.width/2, rect.size.height/2));
    CGContextSetRGBFillColor(ctx, 0, 1, 0, 0.25);
    CGContextFillRect(ctx, CGRectMake(rect.size.width/2, rect.size.height/2, rect.size.width/2, rect.size.height/2));
#endif
}

-(void) clearOverlayFrame
{
    drawOverlay = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsDisplay];
    });
}

-(void) drawOVerlay:(CGContextRef)ctx rect:(CGRect)rect
{
    CGPoint topLeft = borderRectFeature.topLeft;
    CGPoint topRight = borderRectFeature.topRight;
    CGPoint bottomLeft = borderRectFeature.bottomLeft;
    CGPoint bottomRight = borderRectFeature.bottomRight;
    
    topLeft = CGContextConvertPointToUserSpace(ctx, topLeft);
    topRight = CGContextConvertPointToUserSpace(ctx, topRight);
    bottomLeft = CGContextConvertPointToUserSpace(ctx, bottomLeft);
    bottomRight = CGContextConvertPointToUserSpace(ctx, bottomRight);
    
    CGFloat xOffset = (((rect.size.width / rect.size.height) * rawImageRect.width) - rect.size.width)/2;
    
    viewMatrix = CGAffineTransformMake(2*rect.size.height/rawImageRect.height, 0, 0, -2*rect.size.height/rawImageRect.height, -1*xOffset, rect.size.height);
    
    topLeft = CGPointApplyAffineTransform(topLeft, viewMatrix);
    topRight = CGPointApplyAffineTransform(topRight, viewMatrix);
    bottomLeft = CGPointApplyAffineTransform(bottomLeft, viewMatrix);
    bottomRight = CGPointApplyAffineTransform(bottomRight, viewMatrix);
    
    if(overlayRenderHandler != nil)
    {
        overlayRenderHandler(ctx, rect, topLeft, topRight, bottomLeft, bottomRight);
        return;
    }
    
    BOOL draw = [self pointFilter:@[ [NSValue valueWithCGPoint:topLeft], [NSValue valueWithCGPoint:topRight], [NSValue valueWithCGPoint:bottomLeft], [NSValue valueWithCGPoint:bottomRight] ]];

#if SHOW_DEBUGGER_OVERLAY == 1
    // frame before corrected (blue)
    CGContextSetLineWidth(ctx, 1);
    CGContextSetRGBStrokeColor(ctx, 0, 0, 1, 1);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, topLeft.x, topLeft.y);
    CGContextAddLineToPoint(ctx, topRight.x, topRight.y);
    CGContextAddLineToPoint(ctx, bottomRight.x, bottomRight.y);
    CGContextAddLineToPoint(ctx, bottomLeft.x, bottomLeft.y);
    CGContextClosePath(ctx);
    CGContextStrokePath(ctx);
#endif
    
    // the feature points are regarded as noise, use last valid feature point set
    if(!draw)
    {
        if(queue.count < 6)
            return;
        NSArray * previousFrame = [queue objectAtIndex:3];
        topLeft = [[previousFrame objectAtIndex:0] CGPointValue];
        topRight = [[previousFrame objectAtIndex:1] CGPointValue];
        bottomLeft = [[previousFrame objectAtIndex:2] CGPointValue];
        bottomRight = [[previousFrame objectAtIndex:3] CGPointValue];
        [UIView animateWithDuration:0.3f animations:^{
            [self setAlpha:1.0f];
        } completion:nil];
        
    }
    
    // overlay region
    CGContextBeginPath(ctx);
    CGContextSetFillColorWithColor(ctx, frameFillColor.CGColor);
    CGContextSetStrokeColorWithColor(ctx, frameBorderColor.CGColor);

#if SHOW_DEBUGGER_OVERLAY == 1
    
    if(draw == NO)
    {
        textAtPoint(@"CORRECTED", CGPointMake(rect.size.width/2 - 24, rect.size.height/2 - 24));
        CGContextSetRGBStrokeColor(ctx, 0, 1, 0, 1);
        CGContextSetFillColorWithColor(ctx, frameFillColor.CGColor);
    }
#endif

    
    CGContextSetLineWidth(ctx, frameBorderWidth);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, topLeft.x, topLeft.y);
    CGContextAddLineToPoint(ctx, topRight.x, topRight.y);
    CGContextAddLineToPoint(ctx, bottomRight.x, bottomRight.y);
    CGContextAddLineToPoint(ctx, bottomLeft.x, bottomLeft.y);
    CGContextClosePath(ctx);
    CGContextDrawPath(ctx, kCGPathFillStroke);
    lastDetectedFeatures = [[NSMutableArray alloc]
                            initWithObjects:
                            [NSValue valueWithCGPoint:topLeft ],
                            [NSValue valueWithCGPoint:topRight ],
                            [NSValue valueWithCGPoint:bottomLeft ],
                            [NSValue valueWithCGPoint:bottomRight ],
                            nil];
    
#if SHOW_DEBUGGER_OVERLAY == 1
    // show coord of feature points
    textAtPoint(roundPointStr(topLeft, 0), topLeft);
    textAtPoint(roundPointStr(topRight, 12), topRight);
    textAtPoint(roundPointStr(bottomLeft, 0), bottomRight);
    textAtPoint(roundPointStr(bottomRight, 12), bottomLeft);
#endif
    
    
}

@end
