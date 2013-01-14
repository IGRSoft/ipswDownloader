//
//  Item.m
//  ipswDownloader
//
//  Created by Vitaly Parovishnik on 2/11/12.
//  Copyright 2012 IGR Soft. All rights reserved.
//

#import "Item.h"
#import "ASIHTTPRequest.h"

@implementation Item

-(id)initWithName:(NSString*)itemName Request:(ASIHTTPRequest*)itemRequest Sha1:(NSString*)itemSha1
{
	if (!(self = [super init]))
	{
		return nil;
	}
	
	_name = itemName;
	_details = NSLocalizedString(@"Expect to start download", @"Expect to start download");
	
	NSImage *img = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource: @"document"
																						   ofType: @"png"]];
	_icon = img;
	_downloadPath = [itemRequest downloadDestinationPath];
	_tempDownloadPath = [itemRequest temporaryFileDownloadPath];
	_request = itemRequest;
	_sha1 = itemSha1;
	_state = DOWNLOAD_IN_PROGRESS;
	_timeShift = 0;
	_startrTimer = [NSDate timeIntervalSinceReferenceDate];
	_pauseTimer = 0;

	return self;
}

- (void)dealloc {
	_request = nil;
	_state = 0;
	_timeShift = 0;
	_startrTimer = 0;
	_pauseTimer = 0;
}

@end
