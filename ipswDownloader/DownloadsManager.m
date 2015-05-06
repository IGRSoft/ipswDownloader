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

@interface DownloadsManager () <NSUserNotificationCenterDelegate>

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
		
	return self;
}

- (NSInteger)addDownloadFile:(NSURL*)downloadURL withSHA1:(NSString*)downloadSHA1
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
	
	NSInteger result = [self startDownloadWithRequest:request atIndex:-1];
	
	fileName = [NSString stringWithString:[URLHelper splitURL:[request url]][1]];
	
	Item *item = [[Item alloc] initWithName:[IPSWInfoHelper nameIPWS:fileName]
									Request:request
									   Sha1:downloadSHA1];
	
	[self.downloadsInfoData addObject:item];
	[self.pausedInfoData addObject:[NSString string]];
	
	return result;
}

- (NSInteger)startDownloadWithRequest:(ASIHTTPRequest*)request atIndex:(NSInteger)index
{
	[request setAllowResumeForFileDownloads:YES];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(URLFetchWithProgressComplete:)];
	[request setDidFailSelector:@selector(URLFetchWithProgressFailed:)];
	request.userAgentString = @"ipswDownloader";
    
	[request startAsynchronous];
	
	if (index >= 0)
	{
		Item *item = self.downloadsInfoData[index];
		item.request = request;
	}
	
    return index;
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
    
    if (self.successCompletionBlock)
    {
        self.successCompletionBlock(filePath);
    }
	
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
				
                NSUserNotification *notification = [[NSUserNotification alloc] init];
                [notification setTitle:NSLocalizedString(@"ipswDownloader", "Notification notification title")];
                [notification setSubtitle:[IPSWInfoHelper nameIPWS:fileName]];
                [notification setInformativeText:NSLocalizedString(NOTIFICATION_CHECKSUM_FAIL, @"Notification SHA1 Checksum Fail")];
                NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
                [center scheduleNotification:notification];
			}
			else
			{
				DBNSLog(@"%@", NSLocalizedString(NOTIFICATION_CHECKSUM_FAIL, @"Notification SHA1 Checksum Fail"));
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
				
                NSUserNotification *notification = [[NSUserNotification alloc] init];
                [notification setTitle:NSLocalizedString(@"ipswDownloader", "Notification notification title")];
                [notification setSubtitle:[IPSWInfoHelper nameIPWS:fileName]];
                [notification setInformativeText:NSLocalizedString(NOTIFICATION_DOWNLOAD_COMPLETE, @"Notification Download Complete")];
                [notification setUserInfo:@{@"filePath": filePath}];
                NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
                [center setDelegate:self];
                [center scheduleNotification:notification];
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
			
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            [notification setTitle:NSLocalizedString(@"ipswDownloader", "Notification notification title")];
            [notification setSubtitle:[IPSWInfoHelper nameIPWS:fileName]];
            [notification setInformativeText:NSLocalizedString(NOTIFICATION_DOWNLOAD_COMPLETE, @"Notification Download Complete")];
            [notification setUserInfo:@{@"filePath": filePath}];
            NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
            [center setDelegate:self];
            [center scheduleNotification:notification];
		}
		
		[self playSystemSound:@"Tink"];
	}
}

- (void)URLFetchWithProgressFailed:(ASIHTTPRequest *)request
{	
	if (![request isCancelled])
	{
		needWaitProcess = YES;
        
        if (self.failedCompletionBlock)
        {
            self.failedCompletionBlock(request.temporaryFileDownloadPath);
        }
	}
	
	if ([[request error] domain] == NetworkRequestErrorDomain && [[request error] code] == ASIRequestCancelledErrorType)
	{
		//
	}
	else
	{
		// Inform the user.
		DBNSLog(@"Download failed! Error - %@ %@",
				[[request error] localizedDescription],
				[[request error] userInfo][NSURLErrorFailingURLStringErrorKey]);
		BOOL m_bShowNotification = [[NSUserDefaults standardUserDefaults] boolForKey:defaultsUseNotificationKey];
		
		if (m_bShowNotification)
		{
			NSString* fileName = [NSString stringWithString:[URLHelper splitURL:[request url]][1]];
			
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            [notification setTitle:NSLocalizedString(@"ipswDownloader", "Notification notification title")];
            [notification setSubtitle:[IPSWInfoHelper nameIPWS:fileName]];
            [notification setInformativeText:NSLocalizedString(NOTIFICATION_DOWNLOAD_FAIL, @"Notification Download Fail")];
            NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
            [center scheduleNotification:notification];
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

