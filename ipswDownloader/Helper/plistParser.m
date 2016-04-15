//
//  plistParser.m
//  ipswDownloader
//
//  Created by Vitaly Parovishnik on 27.12.11.
//  Copyright (c) 2011 IGR Software. All rights reserved.
//

#import "plistParser.h"

static NSString * const firmwareFileName = @"Firmware.plist";
static NSString * const linksFileName = @"Links.plist";
static NSString * const deviceFileName = @"Devices.plist";

@implementation plistParser

- (NSMutableDictionary*)loadListWithInterval:(NSUInteger)interval
{
	NSString *executableName = [[NSBundle mainBundle] infoDictionary][@"CFBundleExecutable"];
	NSError *error;
	NSString *result = [self findOrCreateDirectory:NSApplicationSupportDirectory
										  inDomain:NSUserDomainMask
							   appendPathComponent:executableName
											 error:&error];
	
	if (!result)
	{
		DBNSLog(@"Unable to find or create application support directory:\n%@", [error localizedDescription]);
	}
	
	BOOL needUpdateDB = NO;
	NSFileManager* fm = [NSFileManager defaultManager];
	
	if (![fm fileExistsAtPath:[result stringByAppendingPathComponent:firmwareFileName]] 
		|| ![fm fileExistsAtPath:[result stringByAppendingPathComponent:linksFileName]]
		|| ![fm fileExistsAtPath:[result stringByAppendingPathComponent:deviceFileName]])
	{
		needUpdateDB = YES;
	}
	else if (interval == UPDATE_AT_APP_START) 
	{		
		needUpdateDB = YES;
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
		while ((file = [enumerator nextObject]))
		{
			if ([file isEqualToString:firmwareFileName])
			{
				NSDictionary *attributes = [enumerator fileAttributes];
				
				fileDate = attributes[NSFileCreationDate];
			}
		}
		
		if (fileDate)
		{
			components = [calendar components:units fromDate:fileDate];
			NSInteger fileDay = [components day];
			NSInteger fileMonth = [components month];
			
			if (interval == UPDATE_EVERY_DAY)
			{
				if (currentMonth != fileMonth || (currentDay - fileDay) >= 1)
				{
					needUpdateDB = YES;
				}
				
			}
			else
			{
				if (currentMonth != fileMonth || (currentDay - fileDay) >= 7)
				{
					needUpdateDB = YES;
				}
			}
		}
	}
	
	if (needUpdateDB)
	{
        NSString *firmwareFileUrl = FIRMWARE_URL;
        firmwareFileUrl = [firmwareFileUrl stringByAppendingPathComponent:firmwareFileName];
		NSData *theData = [NSData dataWithContentsOfFile:firmwareFileUrl];
		[theData writeToFile:[result stringByAppendingPathComponent:firmwareFileName] atomically:YES];
        
        NSString *linksFileUrl = FIRMWARE_URL;
        linksFileUrl = [linksFileUrl stringByAppendingPathComponent:linksFileName];
        theData = [NSData dataWithContentsOfFile:linksFileUrl];
        [theData writeToFile:[result stringByAppendingPathComponent:linksFileName] atomically:YES];
        
        NSString *deviceFileUrl = FIRMWARE_URL;
        deviceFileUrl = [deviceFileUrl stringByAppendingPathComponent:deviceFileName];
        theData = [NSData dataWithContentsOfFile:deviceFileUrl];
        [theData writeToFile:[result stringByAppendingPathComponent:deviceFileName] atomically:YES];
	}
	
	NSMutableDictionary *_plist = [[NSMutableDictionary alloc] initWithCapacity:3];
    
    NSString* tempFileName = [NSString stringWithString:[result stringByAppendingPathComponent:firmwareFileName]];
	_plist[FIRMWARE_NAME] = [NSMutableDictionary dictionaryWithContentsOfFile:tempFileName];
    
    tempFileName = [NSString stringWithString:[result stringByAppendingPathComponent:deviceFileName]];
    _plist[DEVICES_NAME] = [NSMutableDictionary dictionaryWithContentsOfFile:tempFileName];
    
    tempFileName = [NSString stringWithString:[result stringByAppendingPathComponent:linksFileName]];
    _plist[LINKS_NAME] = [NSMutableDictionary dictionaryWithContentsOfFile:tempFileName];
	
	return _plist;
}

#pragma mark ==================== one firmware ==================

- (NSString*)getBaseband:(NSMutableDictionary*)fw
{
	return fw[@"baseband"];
}

- (NSString*)getJBIndicatir:(NSMutableDictionary*)fw
{
	BOOL value = NO;
	NSString* image;
	
	value = [fw[@"jailbreak"] boolValue];
	
	if (value)
	{
		image = @"on";
	}
	else
	{
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

- (NSString*)getUnlockIndicatir:(NSMutableDictionary*)fw
{
	BOOL value = NO;
	NSString* image;
	
	value = [fw[@"unlock"] boolValue];
	
	if (value)
	{
		image = @"on";
	}
	else if ([[self getBaseband:fw] isEqualToString:@"none"])
	{
		image = @"none";
	}
	else
	{
		image = @"off";
	}
	
	return image;
}

- (NSString*)getSize:(NSMutableDictionary*)fw
{
	CGFloat size = 0;
	size = [fw[@"size"] floatValue];
	size = size / BYTE_IN_MB;
	
	return [NSString stringWithFormat:@"%.2f Mb", size];
}

- (NSString*)getURL:(NSMutableDictionary*)fw
{
	return fw[@"url"];
}

- (NSString*)getInfo:(NSMutableDictionary*)fw
{
	return fw[@"info"];
}

- (NSString*)getDocks:(NSMutableDictionary*)fw
{
	return fw[@"docs"];
}

- (NSString*)getJBTools:(NSMutableDictionary*)fw
{
	return fw[@"jbtools"];
}

- (NSString*)getUnlockTools:(NSMutableDictionary*)fw
{
	return fw[@"utools"];
}

- (NSString*)getSHA1:(NSMutableDictionary*)fw
{
	return fw[@"sha1"];
}

- (NSString*)getBuild:(NSMutableDictionary*)fw
{
	return fw[@"build"];
}

- (NSString*)getReleaseDate:(NSMutableDictionary*)fw
{
	NSString *sDate = fw[@"date"];
	NSDateFormatter *format = [[NSDateFormatter alloc] init];
	[format setDateFormat:@"dd MMM yyyy"];
	[format setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];
	NSDate *date = [format dateFromString:sDate];
	return [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterNoStyle];
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
