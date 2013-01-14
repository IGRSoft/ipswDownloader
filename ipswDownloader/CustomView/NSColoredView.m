//
//  NSColoredView.m
//  ipswDownloader
//
//  Created by Vitalii Parovishnyk on 12/27/12.
//
//

#import "NSColoredView.h"

@implementation NSColoredView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetRGBFillColor(context, 0.227,0.251,0.337,0.8);
    CGContextFillRect(context, NSRectToCGRect(dirtyRect));
}

@end
