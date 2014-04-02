//
//  ItemCellView.h
//  ipswDownloader
//
//  Created by Vitaly Parovishnik on 12/29/11.
//  Copyright 2011 IGR Software. All rights reserved.
//

#import "ItemCellView.h"

@implementation ItemCellView

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
	NSColor *textColor = (backgroundStyle == NSBackgroundStyleDark) ? [NSColor windowBackgroundColor] : [NSColor controlShadowColor];
	self.detailTextField.textColor = textColor;
	[super setBackgroundStyle:backgroundStyle];
}

@end
