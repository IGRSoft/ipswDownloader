//
//  Item.h
//  ipswDownloader
//
//  Created by Vitaly Parovishnik on 2/11/12.
//  Copyright 2012 IGR Soft. All rights reserved.
//

@class ASIHTTPRequest;

typedef NS_ENUM(NSUInteger, DownloadStatus)
{
	DOWNLOAD_IN_PROGRESS = 0,
	DOWNLOAD_PAUSED,
	DOWNLOAD_COMPLEATED,
	DOWNLOAD_FAILED,
	
	DOWNLOAD_COUNT
};

@interface Item : NSObject {

}

-(id)initWithName:(NSString*)itemName Request:(ASIHTTPRequest*)itemRequest Sha1:(NSString*)itemSha1;

@property (nonatomic, copy)		NSString		*name;
@property (nonatomic, copy)		NSString		*details;
@property (nonatomic, copy)		NSImage			*icon;
@property (nonatomic, copy)		NSString		*tempDownloadPath;
@property (nonatomic, copy)		NSString		*downloadPath;
@property (nonatomic, weak)		ASIHTTPRequest	*request;
@property (nonatomic, assign)	DownloadStatus  state;
@property (nonatomic, assign)	NSTimeInterval	timeShift;
@property (nonatomic, assign)	NSTimeInterval	startrTimer;
@property (nonatomic, assign)	NSTimeInterval	pauseTimer;
@property (nonatomic, copy)		NSString		*sha1;

@end
