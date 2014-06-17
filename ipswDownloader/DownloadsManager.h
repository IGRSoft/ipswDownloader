//
//  DownloadsManager.h
//  ipswDownloader
//
//  Created by Vitalii Parovishnyk on 01.03.12.
//  Copyright (c) 2012 IGR Spftware. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASIHTTPRequest;

typedef void (^DownloadSuccessCompletionBlock)(NSString *downloadingPath);
typedef void (^DownloadFailedCompletionBlock)(NSString *downloadingPath);

@interface DownloadsManager : NSObject

@property (nonatomic, strong) NSMutableArray	*pausedInfoData;
@property (nonatomic, strong) NSMutableArray	*downloadsInfoData;

@property (nonatomic, copy)   DownloadSuccessCompletionBlock successCompletionBlock;
@property (nonatomic, copy)   DownloadFailedCompletionBlock failedCompletionBlock;

- (NSInteger) addDownloadFile:(NSURL*)downloadURL withSHA1:(NSString*)downloadSHA1;
- (NSInteger) startDownloadWithRequest:(ASIHTTPRequest*)request atIndex:(NSInteger)index;
- (void) pauseDownloadAtIndex:(NSUInteger)index withObject:(NSDictionary*)object;

@end
