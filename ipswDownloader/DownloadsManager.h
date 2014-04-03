//
//  DownloadsManager.h
//  ipswDownloader
//
//  Created by Vitalii Parovishnyk on 01.03.12.
//  Copyright (c) 2012 IGR Spftware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Growl/Growl.h>

@class ASIHTTPRequest;

@interface DownloadsManager : NSObject <GrowlApplicationBridgeDelegate, NSUserNotificationCenterDelegate>
{	
}

@property (nonatomic, retain) NSMutableArray	*pausedInfoData;
@property (nonatomic, retain) NSMutableArray	*downloadsInfoData;

- (BOOL) addDownloadFile:(NSURL*)downloadURL withSHA1:(NSString*)downloadSHA1;
- (void) startDownloadWithRequest:(ASIHTTPRequest*)request atIndex:(NSInteger)index;
- (void) pauseDownloadAtIndex:(NSUInteger)index withObject:(NSDictionary*)object;

@end
