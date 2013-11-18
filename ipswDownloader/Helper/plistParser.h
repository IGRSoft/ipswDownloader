//
//  plistParser.h
//  ipswDownloader
//
//  Created by Vitaly Parovishnik on 27.12.11.
//  Copyright (c) 2011 IGR Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface plistParser : NSObject {

}

- (NSMutableDictionary*) loadListWithInterval:(int)interval;

- (NSString*) getBaseband:(NSMutableDictionary*)fw;
- (NSString*) getJBIndicatir:(NSMutableDictionary*)fw;
- (NSString*) getUnlockIndicatir:(NSMutableDictionary*)fw;
- (NSString*) getSize:(NSMutableDictionary*)fw;
- (NSString*) getInfo:(NSMutableDictionary*)fw;
- (NSString*) getURL:(NSMutableDictionary*)fw;
- (NSString*) getDocks:(NSMutableDictionary*)fw;
- (NSString*) getJBTools:(NSMutableDictionary*)fw;
- (NSString*) getUnlockTools:(NSMutableDictionary*)fw;
- (NSString*) getSHA1:(NSMutableDictionary*)fw;
- (NSString*) getBuild:(NSMutableDictionary*)fw;
- (NSString*) getReleaseDate:(NSMutableDictionary*)fw;

- (NSString *)findOrCreateDirectory:(NSSearchPathDirectory)searchPathDirectory
						   inDomain:(NSSearchPathDomainMask)domainMask
				appendPathComponent:(NSString *)appendComponent
							  error:(NSError * __autoreleasing *)errorOut;
@end
