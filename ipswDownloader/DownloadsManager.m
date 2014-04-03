//
//  DownloadsManager.m
//  ipswDownloader
//
//  Created by Vitalii Parovishnyk on 01.03.12.
//  Copyright (c) 2012 IGR Spftware. All rights reserved.
//

#import "DownloadsManager.h"
#import "PreferenceController.h"

#import "ASIHTTPRequest.h"

#import "sha1.h"
#import <AudioToolbox/AudioToolbox.h>
#import "URLHelper.h"
#import "IPSWInfoHelper.h"
#import "Item.h"

extern BOOL needWaitProcess;

@interface DownloadsManager ()
- (void)URLFetchWithProgressComplete:(ASIHTTPRequest *)request;
- (void)URLFetchWithProgressFailed:(ASIHTTPRequest *)request;
- (void)playSystemSound:(NSString*) name;
@end

@implementation DownloadsManager

- (id)init
{
	if (!(self = [super init]))
	{
		return nil;
	}
	
	_downloadsInfoData = [[NSMutableArray alloc] initWithCapacity:127];
	_pausedInfoData = [[NSMutableArray alloc] initWithCapacity:127];
	
	[GrowlApplicationBridge setGrowlDelegate: self];
	
	return self;
}

- (BOOL)addDownloadFile:(NSURL*)downloadURL withSHA1:(NSString*)downloadSHA1
{
	NSString* fileName = [NSString stringWithString:[URLHelper splitURL:downloadURL][1]];
	
	NSString *downloadsDirectory = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES)[0];
	
	NSString* tempFileName = [[NSMutableString alloc] initWithString:[downloadsDirectory stringByAppendingFormat:@"/%@.download", fileName]];
	BOOL mayStart = NO;
	if (![[NSFileManager defaultManager] fileExistsAtPath:tempFileName])
	{
		mayStart = YES;
	}
	
	NSUInteger shift = 1;
	
	while (!mayStart)
	{
		NSRange range = [fileName rangeOfString:@".ipsw"];
		NSString *tmp = [NSString stringWithFormat:@"%@_%@%@", [fileName substringToIndex:(range.location)], @(shift++), [fileName substringFromIndex:range.location]];
		tempFileName = [downloadsDirectory stringByAppendingFormat:@"/%@.download", tmp];
		if (![[NSFileManager defaultManager] fileExistsAtPath:tempFileName])
		{
			fileName = tmp;
			mayStart = YES;
		}
	}

	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:downloadURL];
	[request setDownloadDestinationPath:[downloadsDirectory stringByAppendingFormat:@"/%@", fileName]];
	[request setTemporaryFileDownloadPath:tempFileName];
	
	[self startDownloadWithRequest:request atIndex:-1];
	
	fileName = [NSString stringWithString:[URLHelper splitURL:[request url]][1]];
	
	Item *item = [[Item alloc] initWithName:[IPSWInfoHelper nameIPWS:fileName]
									Request:request
									   Sha1:downloadSHA1];
	
	[self.downloadsInfoData addObject:item];
	[self.pausedInfoData addObject:[NSString string]];
	
	return YES;
}

- (void)startDownloadWithRequest:(ASIHTTPRequest*)request atIndex:(NSInteger)index
{
	[request setAllowResumeForFileDownloads:YES];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(URLFetchWithProgressComplete:)];
	[request setDidFailSelector:@selector(URLFetchWithProgressFailed:)];
	
	[request startAsynchronous];
	
	if (index >= 0)
	{
		Item *item = self.downloadsInfoData[index];
		item.request = request;
	}
	
	NSMutableArray *ma = [[NSMutableArray alloc] init];
	NSDictionary * expDict = @{@"index": @(index)};
	[ma addObject:expDict];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ADD_DOWNLOAD_OBJECT_NOTIFICATION
														object:ma];
	
}

- (void)pauseDownloadAtIndex:(NSUInteger)index withObject:(NSDictionary*)object
{
	[self.pausedInfoData insertObject:object atIndex:index];
}

- (void)URLFetchWithProgressComplete:(ASIHTTPRequest *)request
{
	needWaitProcess = YES;
	
	Item *item = nil;
	for (Item *itm in [self downloadsInfoData])
	{
		if (itm.request == request)
		{
			item = itm;
		}
	}
	
	if (!item)
	{
		return;
		
	}
	
	NSString *filePath = [item downloadPath];
	[[NSNotificationCenter defaultCenter] postNotificationName:REMOVE_DOWNLOAD_OBJECT_NOTIFICATION
														object:filePath];
	
	BOOL m_bNeedCheckCRC = [[NSUserDefaults standardUserDefaults] boolForKey:defaultsCheckSHA1Key];
	if (m_bNeedCheckCRC)
	{
		CFStringRef sha1hash = FileSHA1HashCreateWithPath((__bridge CFStringRef)filePath, FileHashDefaultChunkSizeForReadingData);
		DBNSLog(@"SHA1 hash of file at path \"%@\": %@", filePath, (__bridge NSString *)sha1hash);
		
		NSString *sha1 = [item sha1];
		
		if (![sha1 isEqualToString:(__bridge NSString *)sha1hash])
		{
			BOOL m_bShowNotification = [[NSUserDefaults standardUserDefaults] boolForKey:defaultsUseNotificationKey];
			
			if (m_bShowNotification)
			{
				NSString* fileName = [NSString stringWithString:[URLHelper splitURL:[request url]][1]];
				
				if (NSClassFromString(@"NSUserNotificationCenter"))
				{
					NSUserNotification *notification = [[NSUserNotification alloc] init];
					[notification setTitle:NSLocalizedString(@"ipswDownloader", "Growl notification title")];
					[notification setSubtitle:[IPSWInfoHelper nameIPWS:fileName]];
					[notification setInformativeText:NSLocalizedString(GROWL_CHECKSUM_FAIL, @"Growl SHA1 Checksum Fail")];
					NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
					[center scheduleNotification:notification];
				}
				else
				{
					NSString *description = [NSString stringWithFormat:@"%@ - %@", [IPSWInfoHelper nameIPWS:fileName],  NSLocalizedString(GROWL_CHECKSUM_FAIL, @"Growl SHA1 Checksum Fail")];
					//Growl
					[GrowlApplicationBridge notifyWithTitle: NSLocalizedString(@"ipswDownloader", "Growl notification title")
												description: description
										   notificationName: GROWL_CHECKSUM_FAIL
												   iconData: nil
												   priority: 0
												   isSticky: NO
											   clickContext: nil];
				}
			}
			else
			{
				DBNSLog(@"%@", NSLocalizedString(GROWL_CHECKSUM_FAIL, @"Growl SHA1 Checksum Fail"));
			}
			
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:[request downloadDestinationPath]])
			{
				[[NSFileManager defaultManager] removeItemAtPath:[request downloadDestinationPath] error:nil];
			}
			[self playSystemSound:@"Basso"];
		}
		else {
			BOOL m_bShowNotification = [[NSUserDefaults standardUserDefaults] boolForKey:defaultsUseNotificationKey];
			
			if (m_bShowNotification)
			{
				NSString* fileName = [NSString stringWithString:[URLHelper splitURL:[request url]][1]];
				
				if (NSClassFromString(@"NSUserNotificationCenter"))
				{
					NSUserNotification *notification = [[NSUserNotification alloc] init];
					[notification setTitle:NSLocalizedString(@"ipswDownloader", "Growl notification title")];
					[notification setSubtitle:[IPSWInfoHelper nameIPWS:fileName]];
					[notification setInformativeText:NSLocalizedString(GROWL_DOWNLOAD_COMPLETE, @"Growl Download Complete")];
					[notification setUserInfo:@{@"filePath": filePath}];
					NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
					[center setDelegate:self];
					[center scheduleNotification:notification];
				}
				else
				{
					//Growl
					NSMutableDictionary * clickContext = [NSMutableDictionary dictionaryWithObject: GROWL_DOWNLOAD_COMPLETE forKey: @"Type"];
					NSString *description = [NSString stringWithFormat:@"%@ - %@", [IPSWInfoHelper nameIPWS:fileName], NSLocalizedString(GROWL_DOWNLOAD_COMPLETE, @"Growl Download Complete")];
					
					clickContext[@"Location"] = [request downloadDestinationPath];
					
					[GrowlApplicationBridge notifyWithTitle: NSLocalizedString(@"ipswDownloader", "Growl notification title")
												description: description
										   notificationName: GROWL_DOWNLOAD_COMPLETE
												   iconData: nil
												   priority: 0
												   isSticky: NO
											   clickContext: clickContext];
				}
			}
			[self playSystemSound:@"Tink"];
		}
		
		if (sha1hash) CFRelease(sha1hash);
	}
	else
	{
		BOOL m_bShowNotification = [[NSUserDefaults standardUserDefaults] boolForKey:defaultsUseNotificationKey];
		
		if (m_bShowNotification)
		{
			NSString* fileName = [NSString stringWithString:[URLHelper splitURL:[request url]][1]];
			
			if (NSClassFromString(@"NSUserNotificationCenter"))
			{
				NSUserNotification *notification = [[NSUserNotification alloc] init];
				[notification setTitle:NSLocalizedString(@"ipswDownloader", "Growl notification title")];
				[notification setSubtitle:[IPSWInfoHelper nameIPWS:fileName]];
				[notification setInformativeText:NSLocalizedString(GROWL_DOWNLOAD_COMPLETE, @"Growl Download Complete")];
				[notification setUserInfo:@{@"filePath": filePath}];
				NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
				[center setDelegate:self];
				[center scheduleNotification:notification];
			}
			else
			{
				//Growl
				NSMutableDictionary * clickContext = [NSMutableDictionary dictionaryWithObject: GROWL_DOWNLOAD_COMPLETE forKey: @"Type"];
				NSString *description = [NSString stringWithFormat:@"%@ - %@", [IPSWInfoHelper nameIPWS:fileName], NSLocalizedString(GROWL_DOWNLOAD_COMPLETE, @"Growl Download Complete")];
				
				clickContext[@"Location"] = [request downloadDestinationPath];
				
				[GrowlApplicationBridge notifyWithTitle: NSLocalizedString(@"ipswDownloader", "Growl notification title")
											description: description
									   notificationName: GROWL_DOWNLOAD_COMPLETE
											   iconData: nil
											   priority: 0
											   isSticky: NO
										   clickContext: clickContext];
			}
		}
		
		[self playSystemSound:@"Tink"];
	}
}

- (void)URLFetchWithProgressFailed:(ASIHTTPRequest *)request
{	
	if (![request isCancelled])
	{
		needWaitProcess = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:FAILED_DOWNLOAD_OBJECT_NOTIFICATION
															object:request.temporaryFileDownloadPath];
	}
	
	if ([[request error] domain] == NetworkRequestErrorDomain && [[request error] code] == ASIRequestCancelledErrorType)
	{
		//
	}
	else
	{
		
		//Growl
		// Inform the user.
		DBNSLog(@"Download failed! Error - %@ %@",
				[[request error] localizedDescription],
				[[request error] userInfo][NSURLErrorFailingURLStringErrorKey]);
		BOOL m_bShowNotification = [[NSUserDefaults standardUserDefaults] boolForKey:defaultsUseNotificationKey];
		
		if (m_bShowNotification)
		{
			NSString* fileName = [NSString stringWithString:[URLHelper splitURL:[request url]][1]];
			
			if (NSClassFromString(@"NSUserNotificationCenter"))
			{
				NSUserNotification *notification = [[NSUserNotification alloc] init];
				[notification setTitle:NSLocalizedString(@"ipswDownloader", "Growl notification title")];
				[notification setSubtitle:[IPSWInfoHelper nameIPWS:fileName]];
				[notification setInformativeText:NSLocalizedString(GROWL_DOWNLOAD_FAIL, @"Growl Download Fail")];
				NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
				[center scheduleNotification:notification];
			}
			else
			{
				NSString *description = [NSString stringWithFormat:@"%@ - %@", [IPSWInfoHelper nameIPWS:fileName], NSLocalizedString(GROWL_DOWNLOAD_FAIL, @"Growl Download Fail")];
				//Growl
				[GrowlApplicationBridge notifyWithTitle: NSLocalizedString(@"ipswDownloader", "Growl notification title")
											description: description
									   notificationName: GROWL_DOWNLOAD_FAIL
											   iconData: nil
											   priority: 0
											   isSticky: NO
										   clickContext: nil];
			}
		}
		[self playSystemSound:@"Basso"];
	}
}

- (void)playSystemSound:(NSString*)name
{
	BOOL m_bUseSound = [[NSUserDefaults standardUserDefaults] boolForKey:defaultsUseSoundKey];
	if (!m_bUseSound)
	{
		return;
	}
	
	NSString* soundFile = [[NSString alloc] initWithFormat:@"/System/Library/Sounds/%@.aiff", name];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	if ([ fm fileExistsAtPath:soundFile] == YES)
	{
		NSURL* filePath = [NSURL fileURLWithPath: soundFile isDirectory: NO];
		SystemSoundID soundID;
		AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
		AudioServicesPlaySystemSound(soundID);
	}
}

#pragma mark ---- Growl ----

- (NSDictionary *)registrationDictionaryForGrowl
{
    NSArray * notifications = @[GROWL_DOWNLOAD_COMPLETE, 
							   GROWL_DOWNLOAD_FAIL, 
							   GROWL_CHECKSUM_FAIL, 
							   GROWL_DOWNLOAD_CANCELED];
	
    return @{GROWL_NOTIFICATIONS_ALL: notifications, GROWL_NOTIFICATIONS_DEFAULT: notifications};
}

- (void)growlNotificationWasClicked:(id)clickContext
{
    if (!clickContext || ![clickContext isKindOfClass: [NSDictionary class]])
        return;
    
    NSString * type = clickContext[@"Type"], * location;
    if (([type isEqualToString: GROWL_DOWNLOAD_COMPLETE])
		&& (location = clickContext[@"Location"]))
    {
		[[NSWorkspace sharedWorkspace] selectFile: location inFileViewerRootedAtPath: nil];
    }
}

#pragma mark -UserNotificationCenter

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
	NSString *filePath = [notification userInfo][@"filePath"];
    if (filePath)
	{
        [[NSWorkspace sharedWorkspace] selectFile: filePath inFileViewerRootedAtPath: nil];
    }
	[center removeDeliveredNotification:notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)userNotification;
{
	return YES;
}

@end

