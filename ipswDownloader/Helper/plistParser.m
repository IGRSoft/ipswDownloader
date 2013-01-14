//
//  plistParser.m
//  ipswDownloader
//
//  Created by Vitaly Parovishnik on 27.12.11.
//  Copyright (c) 2011 IGR Software. All rights reserved.
//

#import "plistParser.h"
#include "ZipArchive.h"

NSString * const firmwareFileName = @"Firmware.db";
NSString * const linksFileName = @"Links.db";
NSString * const deviceFileName = @"Devices.db";

@implementation plistParser

- (NSMutableDictionary*) loadListWithInterval:(int)interval
{
	NSString *executableName = [[NSBundle mainBundle] infoDictionary][@"CFBundleExecutable"];
	NSError *error;
	NSString *result = [self findOrCreateDirectory:NSApplicationSupportDirectory
										  inDomain:NSUserDomainMask
							   appendPathComponent:executableName
											 error:&error];
	
	if (!error)
	{
		DBNSLog(@"Unable to find or create application support directory:\n%@", [error localizedDescription]);
	}
	
	bool needUpdateDB = false;
	NSFileManager* fm = [NSFileManager defaultManager];
	
	if (![fm fileExistsAtPath:[result stringByAppendingPathComponent:firmwareFileName]] 
		|| ![fm fileExistsAtPath:[result stringByAppendingPathComponent:linksFileName]]
		|| ![fm fileExistsAtPath:[result stringByAppendingPathComponent:deviceFileName]])
	{
		needUpdateDB = true;
	}
	else if (interval == UPDATE_AT_APP_START) 
	{		
		needUpdateDB = true;
	}
	else if (interval == UPDATE_EVERY_DAY || interval == UPDATE_EVERY_WEEK)
	{		
		NSDate *now = [NSDate date];
		// Specify which units we would like to use
		unsigned units = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSDateComponents *components = [calendar components:units fromDate:now];
		NSInteger currentDay = [components day];
		NSInteger currentMonth = [components month];
		
		NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:result];
		NSString *file = nil;
		NSDate *fileDate = nil;
		while ((file = [enumerator nextObject])) {
			
			if ([file isEqualToString:firmwareFileName]) {
				NSDictionary *attributes = [enumerator fileAttributes];
				
				fileDate = attributes[NSFileCreationDate];
			}
		}
		
		if (fileDate) {
			components = [calendar components:units fromDate:fileDate];
			NSInteger fileDay = [components day];
			NSInteger fileMonth = [components month];
			
			if (interval == UPDATE_EVERY_DAY) {
				if (currentMonth != fileMonth || (currentDay - fileDay) >= 1) {
					needUpdateDB = true;
				}
				
			} else {
				if (currentMonth != fileMonth || (currentDay - fileDay) >= 7) {
					needUpdateDB = true;
				}
			}
		}
	}
	
	if (needUpdateDB) {
		NSString *url = [NSString stringWithFormat:@"%@%@%@", FIRMWARE_URL1, FIRMWARE_URL2, FIRMWARE_URL3];
		NSData *theData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
		[theData writeToFile:[result stringByAppendingPathComponent:firmwareFileName] atomically:YES];
	}
	
	ZipArchive *za = [[ZipArchive alloc] init];
	NSString *pas = [NSString stringWithFormat:@"%@%@%@%@", ARCH_PASS1, ARCH_PASS2, ARCH_PASS3, ARCH_PASS4];
	if ([za UnzipOpenFile: [result stringByAppendingPathComponent:firmwareFileName] Password:pas]) {
		BOOL ret = [za UnzipFileTo: result overWrite: YES];
		
		if (NO == ret){} [za UnzipCloseFile];
	}
	NSString* tempFileName = [NSString stringWithString:[result stringByAppendingPathComponent:@"Firmware.plist"]];
	
	NSMutableDictionary* _plist;
	_plist = [[NSMutableDictionary alloc] initWithCapacity:2];
	
	_plist[@"firmware"] = [NSMutableDictionary dictionaryWithContentsOfFile:tempFileName];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:tempFileName]) {
		[[NSFileManager defaultManager] removeItemAtPath:tempFileName error:nil];
	}
	
	if (needUpdateDB) {
		NSString *url = [NSString stringWithFormat:@"%@%@%@", FIRMWARE_URL1, FIRMWARE_URL2, FIRMWARE_URL4];
		NSData *theData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
		[theData writeToFile:[result stringByAppendingPathComponent:linksFileName] atomically:YES];
	}
	
	za = [[ZipArchive alloc] init];
	pas = [NSString stringWithFormat:@"%@%@%@%@", ARCH_PASS1, ARCH_PASS2, ARCH_PASS3, ARCH_PASS4];
	if ([za UnzipOpenFile: [result stringByAppendingPathComponent:linksFileName] Password:pas]) {
		BOOL ret = [za UnzipFileTo: result overWrite: YES];
		
		if (NO == ret){} [za UnzipCloseFile];
	}
	
	tempFileName = [NSString stringWithString:[result stringByAppendingPathComponent:@"Links.plist"]];
	
	_plist[@"links"] = [NSMutableDictionary dictionaryWithContentsOfFile:tempFileName];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:tempFileName]) {
		[[NSFileManager defaultManager] removeItemAtPath:tempFileName error:nil];
	}
	
	if (needUpdateDB) {
		NSString *url = [NSString stringWithFormat:@"%@%@%@", FIRMWARE_URL1, FIRMWARE_URL2, FIRMWARE_URL5];
		NSData *theData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
		[theData writeToFile:[result stringByAppendingPathComponent:deviceFileName] atomically:YES];
	}
	
	za = [[ZipArchive alloc] init];
	pas = [NSString stringWithFormat:@"%@%@%@%@", ARCH_PASS1, ARCH_PASS2, ARCH_PASS3, ARCH_PASS4];
	if ([za UnzipOpenFile: [result stringByAppendingPathComponent:deviceFileName] Password:pas]) {
		BOOL ret = [za UnzipFileTo: result overWrite: YES];
		
		if (NO == ret){} [za UnzipCloseFile];
	}
	
	tempFileName = [NSString stringWithString:[result stringByAppendingPathComponent:@"Devices.plist"]];
	
	_plist[@"devices"] = [NSMutableDictionary dictionaryWithContentsOfFile:tempFileName];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:tempFileName]) {
		[[NSFileManager defaultManager] removeItemAtPath:tempFileName error:nil];
	}
	
	return _plist;
}

#pragma mark ==================== one firmware ==================

- (NSString*) getBaseband:(NSMutableDictionary*)fw
{
	return fw[@"baseband"];
}

- (NSString*) getJBIndicatir:(NSMutableDictionary*)fw
{
	bool value = false;
	NSString* image;
	
	value = [fw[@"jailbreak"] boolValue];
	
	if (value) {
		image = @"on";
	} else {
		image = @"off";
	}
	
	NSString *_info = fw[@"info"];
	
	NSRange textRange;
	textRange =[[_info lowercaseString] rangeOfString:[@"Tethered jailbreak" lowercaseString]];
	
	if(textRange.location != NSNotFound)
	{
		image = @"tether";
	}
	
	return image;
}

- (NSString*) getUnlockIndicatir:(NSMutableDictionary*)fw
{
	bool value = false;
	NSString* image;
	
	value = [fw[@"unlock"] boolValue];
	
	if (value) {
		image = @"on";
	} else if ([[self getBaseband:fw] isEqualToString:@"none"]) {
		image = @"none";
	} else {
		image = @"off";
	}
	
	return image;
}

- (NSString*) getSize:(NSMutableDictionary*)fw
{
	float size = 0;
	size = [fw[@"size"] intValue];
	size = size / BYTE_IN_MB;
	
	return [NSString stringWithFormat:@"%.2f Mb", size];
}

- (NSString*) getURL:(NSMutableDictionary*)fw
{
	return fw[@"url"];
}

- (NSString*) getInfo:(NSMutableDictionary*)fw
{
	return fw[@"info"];
}

- (NSString*) getDocks:(NSMutableDictionary*)fw
{
	return fw[@"docs"];
}

- (NSString*) getJBTools:(NSMutableDictionary*)fw
{
	return fw[@"jbtools"];
}

- (NSString*) getUnlockTools:(NSMutableDictionary*)fw
{
	return fw[@"utools"];
}

- (NSString*) getSHA1:(NSMutableDictionary*)fw
{
	return fw[@"sha1"];
}

- (NSString*) getBuild:(NSMutableDictionary*)fw
{
	return fw[@"build"];
}

- (NSString *)findOrCreateDirectory:(NSSearchPathDirectory)searchPathDirectory
						   inDomain:(NSSearchPathDomainMask)domainMask
				appendPathComponent:(NSString *)appendComponent
							  error:(NSError * __autoreleasing *)errorOut
{
	//
	// Search for the path
	//
	NSArray* paths = NSSearchPathForDirectoriesInDomains(searchPathDirectory, domainMask, YES);
	if ([paths count] == 0)
	{
		if (errorOut)
		{
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"No path found for directory in domain.", @"Errors", nil),
									  @"NSSearchPathDirectory": @(searchPathDirectory),
									  @"NSSearchPathDomainMask": @(domainMask)};
			*errorOut = [NSError errorWithDomain:@"DirectoryLocationDomain"
											code:DirectoryLocationErrorNoPathFound
										userInfo:userInfo];
		}
		return nil;
	}
	
	//
	// Normally only need the first path returned
	//
	NSString *resolvedPath = paths[0];
	
	//
	// Append the extra path component
	//
	if (appendComponent)
	{
		resolvedPath = [resolvedPath stringByAppendingPathComponent:appendComponent];
	}
	
	//
	// Check if the path exists
	//
	BOOL exists;
	BOOL isDirectory;
	exists = [[NSFileManager defaultManager] fileExistsAtPath:resolvedPath 
												  isDirectory:&isDirectory];
	
	if (!exists || !isDirectory)
	{
		if (exists)
		{
			if (errorOut)
			{
				NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(	@"File exists at requested directory location.", @"Errors", nil),
										  @"NSSearchPathDirectory": @(searchPathDirectory),
										  @"NSSearchPathDomainMask": @(domainMask)};
				*errorOut = [NSError errorWithDomain:@"DirectoryLocationDomain"
												code:DirectoryLocationErrorFileExistsAtLocation
											userInfo:userInfo];
			}
			return nil;
		}
		
		//
		// Create the path if it doesn't exist
		//
		NSError *error = nil;
		BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:resolvedPath
												 withIntermediateDirectories:YES
																  attributes:nil
																	   error:&error];
		if (!success) 
		{
			if (errorOut)
			{
				*errorOut = error;
			}
			return nil;
		}
	}
	
	if (errorOut)
	{
		*errorOut = nil;
	}
	
	return resolvedPath;
}


@end