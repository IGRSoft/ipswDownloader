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

@interface DownloadsManager : NSObject <GrowlApplicationBridgeDelegate, NSUserNotificationCenterDelegate> {
	
}

@property (nonatomic, retain) NSMutableArray				*pausedInfoData;
@property (nonatomic, retain) NSMutableArray				*downloadsInfoData;

- (BOOL) addDownloadFile:(NSURL*)downloadURL withSHA1:(NSString*)downloadSHA1;
- (void) startDownloadWithRequest:(ASIHTTPRequest*)request AtIndex:(int)index;
- (void) pauseDownloadAtIndex:(int)index withObject:(NSDictionary*)object;

@end
