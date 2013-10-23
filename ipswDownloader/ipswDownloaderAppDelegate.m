//
//  ipswDownloaderAppDelegate.m
//  ipswDownloader
//
//  Created by Vitaly Parovishnik on 31.01.11.
//  Copyright 2011 IGR Software. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "ipswDownloaderAppDelegate.h"
#import "PreferenceController.h"
#import "DeviceInfo.h"
#import "Reachability.h"
#import "plistParser.h"

#import "DownloadsManager.h"
#import "ItemCellView.h"
#import <Foundation/NSData.h>
#import "Item.h"

#import "ZipArchive.h"

#import "ASIHTTPRequest.h"
#import "URLHelper.h"

#import "MobileDeviceServer.h"

bool needWaitProcess = false;

@implementation ipswDownloaderAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	NSString *filePath = [aNotification userInfo][@"filePath"];
    if (filePath){
		DBNSLog(@"%@", aNotification);
        [[NSWorkspace sharedWorkspace] selectFile: filePath inFileViewerRootedAtPath: nil];
    }
	
	m_bInternet = false;
	[[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(reachabilityChanged:) 
                                                 name:kReachabilityChangedNotification 
                                               object:nil];
    
    Reachability * reach = [Reachability reachabilityWithHostname:@"igrsoft.com"];
    
    reach.reachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            m_bInternet = true;
        });
    };
    
    reach.unreachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            m_bInternet = false;
        });
    };
    
    [reach startNotifier];
	
	NSUserDefaults* appPrefs = [NSUserDefaults standardUserDefaults];
	
	m_dbUpdateInterval = [appPrefs integerForKey:defaultsDBUpdateKey];
	m_bSimpleMode = [appPrefs boolForKey:defaultsSimpleModeKey];
	
	[self simpleMode:nil];
	[self setControlsEnabled: NO];
	
	NSString* path = @"none";
    
	[self openImageFor: _firmwareUnlock withImageName: path];
	[self openImageFor: _firmwareJailbreak withImageName: path];
	
	m_DownloadsManager = [[DownloadsManager alloc] init];
	
	DownloadUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
														   target:self
														 selector:@selector(updateDownloadInfo)
														 userInfo:nil
														  repeats:YES];
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	dispatch_async(queue, ^{
		m_MobileDeviceServer = [[MobileDeviceServer alloc] init];
		[m_MobileDeviceServer setDelegate:self];
	});
}

- (id) init {
	if (!(self = [super init])) 
	{
		return nil;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(addDownloadObject:) 
												 name:ADD_DOWNLOAD_OBJECT_NOTIFICATION
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(removeDownloadObject:) 
												 name:REMOVE_DOWNLOAD_OBJECT_NOTIFICATION
											   object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(failedDownloadObject:) 
												 name:FAILED_DOWNLOAD_OBJECT_NOTIFICATION
											   object:nil];

	m_plistParser = [[plistParser alloc] init];
	m_FirmwareList = [[NSMutableDictionary alloc] init];
	
    return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Download Manager

- (IBAction) downloadIPSW:(id)sender
{
	if (![self internetEnabledWithAlert:true]) {
		return;
	}
	
	NSString* fileName = [NSString stringWithString:[URLHelper splitURL:m_DownloadURL][1]];
	fileName = [fileName substringToIndex:[fileName length]-5];
	
	bool blockDownload = false;
	NSRange textRange;
	bool needCheckonDisk = true;
	
	for (Item *item in [m_DownloadsManager downloadsInfoData]) {
		textRange = [item.downloadPath rangeOfString:fileName];
		if(textRange.location != NSNotFound) {
			
			needCheckonDisk = false;
			
			m_Tempitem = item;
			
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];
			[alert addButtonWithTitle:NSLocalizedString(@"Download", @"Download")];
			[alert setMessageText:NSLocalizedString(@"Duplicate finded", @"Duplicate finded")];
			
			switch (m_Tempitem.state) {
				case DOWNLOAD_IN_PROGRESS:
					[alert setInformativeText:NSLocalizedString(@"You are currently downloading that firmware. Do You want start new download?", @"Start new Download 1")];
					[self startAlert:alert selector:@selector(closDownloadAlert:returnCode:contextInfo:)];
					blockDownload = true;
					break;
				case DOWNLOAD_COMPLEATED:
					[alert setInformativeText:NSLocalizedString(@"You are downloaded that firmware before. Do You want start new download?", @"Start new Download 2")];
					[alert addButtonWithTitle:NSLocalizedString(@"Show in Finder", @"Show in Finder")];
					[self startAlert:alert selector:@selector(closDownloadAlert:returnCode:contextInfo:)];
					blockDownload = true;
					break;
				case DOWNLOAD_PAUSED:
					[alert setInformativeText:NSLocalizedString(@"That firmware is paused. Do You want start new or resume download?", @"Start new Download 3")];
					[alert addButtonWithTitle:NSLocalizedString(@"Resume", @"Resume")];
					[self startAlert:alert selector:@selector(closDownloadAlertWithResume:returnCode:contextInfo:)];
					blockDownload = true;
					break;
				default:
					break;
			}
			
			break;
		}
	}
	
	if (needCheckonDisk) {
		
		fileName = [NSString stringWithString:[URLHelper splitURL:m_DownloadURL][1]];
		NSString *downloadsDirectory = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES)[0];
		NSString* tempFileName = [NSString stringWithString:[downloadsDirectory stringByAppendingFormat:@"/%@", fileName]];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:tempFileName]) {
			
			Item *item = [[Item alloc] init];
			item.downloadPath = tempFileName;
			item.state = DOWNLOAD_COMPLEATED;
			
			m_Tempitem = item;
			
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];
			[alert addButtonWithTitle:NSLocalizedString(@"Download", @"Download")];
			[alert addButtonWithTitle:NSLocalizedString(@"Show in Finder", @"Show in Finder")];
			
			[alert setMessageText:NSLocalizedString(@"Duplicate finded", @"Duplicate finded")];
			[alert setInformativeText:NSLocalizedString(@"You are downloaded that firmware before. Do You want start new download?", @"Start new Download 2")];
			[self startAlert:alert selector:@selector(closDownloadAlert:returnCode:contextInfo:)];
			
			blockDownload = true;
		}
	}
	
	if (!blockDownload) {
		[self.downloadsButton highlight:YES];
		[self performSelector:@selector(removeHighlight) withObject:self afterDelay:0.2];
		
		[m_DownloadsManager addDownloadFile:m_DownloadURL withSHA1:[self.firmwareSHA1 stringValue]];
	}
}

- (void) removeHighlight
{
	[self.downloadsButton highlight:NO];
}

- (void) addDownloadObject:(NSNotification *) notification
{
	if ([[notification name] isEqualToString:ADD_DOWNLOAD_OBJECT_NOTIFICATION])
	{
		NSDictionary* downloadsInfo = [notification object][0];
		if (downloadsInfo)
		{
			int _index = [[downloadsInfo valueForKey:@"index"] intValue];
			if (_index == -1) {
				DBNSLog(@"add download");
				[self.downloadsList reloadData];
			}
			else {
				DBNSLog(@"resume download");
				Item *item = [m_DownloadsManager downloadsInfoData][_index];
				item.state = DOWNLOAD_IN_PROGRESS;
				item.timeShift += ([NSDate timeIntervalSinceReferenceDate] - item.pauseTimer);
				
				[self.downloadsList reloadData];
			}
		}
	}
}

- (void) removeDownloadObject:(NSNotification *) notification
{
	DBNSLog(@"compleate");
	if ([[notification name] isEqualToString:REMOVE_DOWNLOAD_OBJECT_NOTIFICATION])
	{
		NSString* downloadsInfo = [notification object];
		for (Item *item in [m_DownloadsManager downloadsInfoData]) {
			if ([item.downloadPath isEqualToString:downloadsInfo]) {
				item.state = DOWNLOAD_COMPLEATED;
				needWaitProcess = false;
				break;
			}
		}
	}
}

- (void) failedDownloadObject:(NSNotification *) notification
{
	DBNSLog(@"failed");
	if ([[notification name] isEqualToString:FAILED_DOWNLOAD_OBJECT_NOTIFICATION])
	{
		NSString* downloadsInfo = [notification object];
		int pos = 0;
		for (Item *item in [m_DownloadsManager downloadsInfoData]) {
			if ([item.tempDownloadPath isEqualToString:downloadsInfo]) {
				item.state = DOWNLOAD_FAILED;
				id _object = item.request;
				[_object setTag:pos];
				[self cancelButtonPressed:_object];
				needWaitProcess = false;
				break;
			}
			++pos;
		}
	}
}

- (IBAction) showInFinder:(id)sender
{
	Item *item;
	
	if ([NSStringFromClass([sender class]) isEqualToString:@"Item"]) {
		item = (Item*)sender;
	}
	else {
		NSInteger row = [sender tag];
		item = [m_DownloadsManager downloadsInfoData][row];
	}
	
	switch ([item state]) {
		case DOWNLOAD_IN_PROGRESS:
		case DOWNLOAD_PAUSED:
		case DOWNLOAD_FAILED:
		{
			NSString *path = [item tempDownloadPath];
			[[NSWorkspace sharedWorkspace] selectFile: path inFileViewerRootedAtPath: nil];
		}
			break;
		case DOWNLOAD_COMPLEATED:
		{
			NSString *path = [item downloadPath];
			[[NSWorkspace sharedWorkspace] selectFile: path inFileViewerRootedAtPath: nil];
		}
			break;
	}
}

- (IBAction) cancelButtonPressed:(id) sender
{	
	Item *item = nil;
	NSInteger row = 0;
	
	if ([NSStringFromClass([sender class]) isEqualToString:@"Item"]) {
		item = (Item*)sender;
		for (Item *_item in [m_DownloadsManager downloadsInfoData]) {
			++row;
			if (_item == item) {
				--row;
				break;
			}
		}
	}
	else {
		row = [sender tag];
		item = [m_DownloadsManager downloadsInfoData][row];
	}
	
	switch ([item state]) {
		case DOWNLOAD_IN_PROGRESS:
		{
			DBNSLog(@"pause");
			item.state = DOWNLOAD_PAUSED;
			item.pauseTimer = [NSDate timeIntervalSinceReferenceDate];
			
			ASIHTTPRequest *request = [item request];
			
			NSDictionary * expDict = @{@"url": [request url],
									  @"downloadDestinationPath": [request downloadDestinationPath],
									  @"temporaryFileDownloadPath": [request temporaryFileDownloadPath]};
			
			[m_DownloadsManager pauseDownloadAtIndex:row withObject:expDict];
			
			[request cancel];
			request = nil;
		}
			break;
		case DOWNLOAD_PAUSED:
		{
			DBNSLog(@"resume");
			NSDictionary * expDict = [m_DownloadsManager pausedInfoData][row];
			
			ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:expDict[@"url"]];
			[request setDownloadDestinationPath:expDict[@"downloadDestinationPath"]];
			[request setTemporaryFileDownloadPath:expDict[@"temporaryFileDownloadPath"]];
			
			[m_DownloadsManager startDownloadWithRequest:request AtIndex:row];
		}
			break;
		case DOWNLOAD_FAILED:
		{
			item.state = DOWNLOAD_PAUSED;
			
			ASIHTTPRequest *request = sender;
			
			NSDictionary * expDict = @{@"url": [request url],
									  @"downloadDestinationPath": [request downloadDestinationPath],
									  @"temporaryFileDownloadPath": [request temporaryFileDownloadPath]};
			
			[m_DownloadsManager pauseDownloadAtIndex:row withObject:expDict];
		
			request = nil;
		}
			break;
		case DOWNLOAD_COMPLEATED:
		default:
			break;
	}
}

#pragma mark - NSTableViewDelegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[m_DownloadsManager downloadsInfoData] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	ItemCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	
	result.detailPauseResumeButton.tag = row;
	result.detailShowInFinderButton.tag = row;
	
	Item *item = [m_DownloadsManager downloadsInfoData][row];
	
	if (needWaitProcess) {
		return result;
	}
	
	switch ([item state]) {
		case DOWNLOAD_IN_PROGRESS:
		{
			result.textField.stringValue = [item name];
			
			ASIHTTPRequest *request = [item request];
			
			//remove that faik
			float size = (float)([request contentLength] + [request partialDownloadSize]) / BYTE_IN_MB;
			float cur_size = (float)([request totalBytesRead]+[request partialDownloadSize]) / BYTE_IN_MB;
			
			int percentComplete = (cur_size / size) * 10.0 + 0.2;
			
			NSImage* img = [NSImage imageNamed:[NSString stringWithFormat:@"NSStopProgressFreestandingTemplate"]];
			[result.detailPauseResumeButton setImage:img];
			
			if (percentComplete == 10) {
				NSString * imgstr = [NSString stringWithFormat:@"download100.png"];
				img = [NSImage imageNamed:imgstr];
			}
			else {
				NSString * imgstr = [NSString stringWithFormat:@"download0%d0.png", percentComplete];
				img = [NSImage imageNamed:imgstr];
			}
			
			result.imageView.image = img;
			
			NSString* text;
			
			NSTimeInterval timeNow = [NSDate timeIntervalSinceReferenceDate];
			float speed = cur_size / (timeNow - [item startrTimer] - [item timeShift]);
			
			int _time = (size - cur_size) / speed;
			if (_time > 60) {
				text = [NSString stringWithFormat:NSLocalizedString(@"%.1f/%.1fMb (%.1f Mb/s) - %i min %i sec", @"Download time min/sec"), cur_size, size, speed, (_time/60), (_time % 60)];
			}
			if (_time <= 60) {
				text = [NSString stringWithFormat:NSLocalizedString(@"%.1f/%.1fMb (%.1f Mb/s) - %i sec", @"Download time sec"), cur_size, size, speed, _time];
			}
			if (_time < 0) {
				text = [NSString stringWithString:NSLocalizedString(@"Expect to start download", @"Expect to start download")];
			}
			
			result.detailTextField.stringValue = text;
		}
			break;
		case DOWNLOAD_PAUSED:
		{
			NSImage* img = [NSImage imageNamed:[NSString stringWithFormat:@"NSRefreshFreestandingTemplate"]];
			[result.detailPauseResumeButton setImage:img];
			
			result.textField.stringValue = [item name];
			result.detailTextField.stringValue = NSLocalizedString(@"Paused", @"Paused");
		}	
			break;
		case DOWNLOAD_COMPLEATED:
		{
			[result.detailPauseResumeButton setEnabled:NO];
			result.textField.stringValue = [item name];
			result.detailTextField.stringValue = NSLocalizedString(@"Compleated", @"Compleated");
		}	
			break;
		case DOWNLOAD_FAILED:
		{
			result.textField.stringValue = [item name];
			result.detailTextField.stringValue = NSLocalizedString(@"Failed", @"Failed");
			
			NSImage* img = [NSImage imageNamed:[NSString stringWithFormat:@"downloaderror.png"]];
			result.imageView.image = img;
		}	
			break;
		default:
			break;
	}
	
	return result;
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	return NO;
}

#pragma mark - Firmware

- (IBAction) selectDevice:(id)sender
{
	[self addItemsToFirmware: [sender stringValue]];
}

- (IBAction) selectFirmware: (id)sender
{
	[self updateInfo:[sender stringValue]];
}

- (void) addItemsToDevice
{
	if (!m_PlistDict && [m_PlistDict count] == 0 )
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK")];
		[alert setMessageText:NSLocalizedString(@"Connection error", @"Connection error")];
		[alert setInformativeText:NSLocalizedString(@"Can't download ipsw list", @"Can't download ipsw list")];
		[alert setAlertStyle:NSCriticalAlertStyle];
		
		[self startAlert:alert selector:@selector(closeAlert:returnCode:contextInfo:)];
		
		return;
	}
	
	[self.device removeAllItems];
	
	NSArray* arrayKey = [[NSArray alloc] initWithArray:[m_PlistDict allKeys]];
	NSArray* sortedKeys = [arrayKey sortedArrayUsingSelector:@selector(localizedCompare:)];
	
	[self.device addItemsWithObjectValues:sortedKeys];
	[self.device selectItemAtIndex:0];
	[self addItemsToFirmware:sortedKeys[0]];
	
}

- (void) addItemsToFirmware: (NSString*)device
{	
	[self.firmware removeAllItems];
	
	m_FirmwareList = [[NSMutableDictionary alloc] initWithDictionary:m_PlistDict[device]];
	
	NSArray* arrayKey = [[NSArray alloc] initWithArray:[m_FirmwareList allKeys]];
	NSArray* sortedKeys = [arrayKey sortedArrayUsingSelector:@selector(localizedCompare:)];
	
	for (int i = [sortedKeys count]; i > 0; --i) {
		[self.firmware addItemWithObjectValue:sortedKeys[(i-1)]];
	}
	
	[self.firmware selectItemAtIndex:0];
	[self updateInfo:[self.firmware stringValue]];
	
}

- (void) updateInfo: (NSString*)firmware
{	
	NSMutableDictionary* oneDeviceFirmware = [[NSMutableDictionary alloc] initWithDictionary:(m_FirmwareList)[firmware]];
	
	[self.firmwareBaseband setStringValue: [m_plistParser getBaseband:oneDeviceFirmware]];
	
	[self openImageFor: self.firmwareJailbreak
				  withImageName: [m_plistParser getJBIndicatir:oneDeviceFirmware]];
	
	[self openImageFor: self.firmwareUnlock
				  withImageName: [m_plistParser getUnlockIndicatir:oneDeviceFirmware]];
	
	[self.firmwareSize setStringValue:[m_plistParser getSize:oneDeviceFirmware]];

	[self.firmwareInfo setStringValue: [m_plistParser getInfo:oneDeviceFirmware]];
	
	m_DownloadURL = [NSURL URLWithString:[m_plistParser getURL:oneDeviceFirmware] ];
	
	if ([[m_DownloadURL relativeString] length] > 0)
	{
		[self.downloadButton setEnabled:YES];
	} else {
		[self.downloadButton setEnabled:NO];
	}
	
	m_DocsURL = [NSURL URLWithString: [m_plistParser getDocks:oneDeviceFirmware]];
	
	[self.firmwareJBTools setString: [m_plistParser getJBTools:oneDeviceFirmware]];
	[self setHiperLinkForTextField:self.firmwareJBTools];
	 
	[self.firmwareUTools setString: [m_plistParser getUnlockTools:oneDeviceFirmware]];
	[self setHiperLinkForTextField:self.firmwareUTools];
	
	[self.firmwareSHA1 setStringValue: [m_plistParser getSHA1:oneDeviceFirmware]];
	
	[self.firmwareBuild setStringValue: [m_plistParser getBuild:oneDeviceFirmware]];
	
	[self.tfJailbreak setHidden:NO];
	[self.tfUnlock setHidden:NO];
}

- (void) openImageFor:(NSImageView*)_imageView withImageName:(NSString*)name
{	
	[_imageView setImage:[NSImage imageNamed:name]];
}

- (IBAction) appleInfo:(id)sender
{
	if (![self internetEnabledWithAlert:true]) {
		return;
	}
	
	[self.animation setHidden:false];
	[self.animation startAnimation:self];
	
	NSString *executableName = [[NSBundle mainBundle] infoDictionary][@"CFBundleExecutable"];
	NSError *error;
	NSString *result = [m_plistParser findOrCreateDirectory:NSApplicationSupportDirectory
										  inDomain:NSUserDomainMask
							   appendPathComponent:executableName
											 error:&error];
	if (!result)
	{
		DBNSLog(@"Unable to find or create application support directory:\n%@", error);
	}
	
	NSString *fileName = @"docs.zip";
	NSString *folderName = @"docs";
	
	NSData *theData = [NSData dataWithContentsOfURL:m_DocsURL];
	[theData writeToFile:[result stringByAppendingPathComponent:fileName] atomically:YES];
	
	ZipArchive *za = [[ZipArchive alloc] init];
	if ([za UnzipOpenFile: [result stringByAppendingPathComponent:fileName]]) {
		BOOL ret = [za UnzipFileTo: [result stringByAppendingPathComponent:folderName] overWrite: YES];
		
		if (NO == ret){} [za UnzipCloseFile];
	}
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:[result stringByAppendingPathComponent:fileName]]) {
		[[NSFileManager defaultManager] removeItemAtPath:[result stringByAppendingPathComponent:fileName] error:nil];
	}
	
	NSString* readmeFile = [[NSString alloc] initWithString:[result stringByAppendingPathComponent:folderName]];
	NSString* sufix = [[NSString alloc] initWithString:[[[NSLocale currentLocale] localeIdentifier] substringToIndex:2]];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:[readmeFile stringByAppendingPathComponent:sufix]]) {
		readmeFile = [readmeFile stringByAppendingPathComponent:sufix];
	} else {
		readmeFile = [readmeFile stringByAppendingPathComponent:@"en"];
	}
		
	readmeFile = [readmeFile stringByAppendingPathComponent:@"ReadMe.rtf"];
	
	[self.animation setHidden:true];
	[self.animation stopAnimation:self];
	
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK")];
	[alert setMessageText:NSLocalizedString(@"Firmware Update Info", @"Firmware Update Info")];
	[alert setAlertStyle:NSInformationalAlertStyle];
	
	NSTextView	*appleFirmwareInfo;
	NSScrollView *scroll;
	
	scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 400, 190)];
	appleFirmwareInfo = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 390, 100)];
	
	[scroll setHasVerticalScroller:YES];
	[scroll setHasHorizontalScroller:NO];
	[scroll setAutohidesScrollers:YES];
	[scroll setDocumentView:(NSView *)appleFirmwareInfo];
	
	[[appleFirmwareInfo textContainer] setContainerSize:NSMakeSize(500000.0,500000.0)];
	[[appleFirmwareInfo textContainer] setWidthTracksTextView:YES];
	[[appleFirmwareInfo textContainer] setHeightTracksTextView:NO];
	[appleFirmwareInfo setHorizontallyResizable:NO];
	[appleFirmwareInfo setVerticallyResizable:YES];
	[appleFirmwareInfo setMaxSize:NSMakeSize(500000.0,500000.0)]; 
	
    // append some coloured text
    [appleFirmwareInfo readRTFDFromFile:readmeFile];
	
	[alert setAccessoryView:scroll];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:[result stringByAppendingPathComponent:folderName]]) {
		[[NSFileManager defaultManager] removeItemAtPath:[result stringByAppendingPathComponent:folderName] error:nil];
	}

	
	[self startAlert:alert selector:@selector(closeFirmwareInfo:returnCode:contextInfo:)];

}

#pragma mark - Alert / Panel

- (void) startAlert:(NSAlert*) alert selector:(SEL)alertSelector 
{
	alertReturnStatus = -1;
	
	[alert setShowsHelp:NO];
	[alert setShowsSuppressionButton:NO];
	[alert beginSheetModalForWindow:self.window
					  modalDelegate:self
					 didEndSelector:alertSelector
						contextInfo:nil];
	
	NSModalSession session = [NSApp beginModalSessionForWindow:[alert window]];
	for (;;) {
		// alertReturnStatus will be set in alertDidEndSheet:returnCode:contextInfo:
		if(alertReturnStatus != -1)
			break;
		
		// Execute code on DefaultRunLoop
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode 
								 beforeDate:[NSDate distantFuture]];
		
		// Break the run loop if sheet was closed
		if ([NSApp runModalSession:session] != NSRunContinuesResponse 
			|| ![[alert window] isVisible]) 
			break;
		
		// Execute code on DefaultRunLoop
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode 
								 beforeDate:[NSDate distantFuture]];
		
	}
	[NSApp endModalSession:session];
	[NSApp endSheet:[alert window]];
}

- (void)closeAlert:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
	DBNSLog(@"clicked %d button\n", returnCode);
	if (returnCode == NSAlertSecondButtonReturn) {
	}
    // make the returnCode publicly available after closing the sheet
    alertReturnStatus = returnCode;
}

- (void)closeFirmwareInfo:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertSecondButtonReturn) {
	}
	alertReturnStatus = returnCode;
}

- (void)closDownloadAlert:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertFirstButtonReturn) {
		
	}
	else if (returnCode == NSAlertSecondButtonReturn) {
		[self.downloadsButton highlight:YES];
		[self performSelector:@selector(removeHighlight) withObject:self afterDelay:0.2];
		
		[m_DownloadsManager addDownloadFile:m_DownloadURL withSHA1:[self.firmwareSHA1 stringValue]];
	}
	else if (returnCode == NSAlertThirdButtonReturn) {
		[self showInFinder:m_Tempitem];
	}
	
	alertReturnStatus = returnCode;
}

- (void)closDownloadAlertWithResume:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertFirstButtonReturn) {
		
	}
	else if (returnCode == NSAlertSecondButtonReturn) {
		[self.downloadsButton highlight:YES];
		[self performSelector:@selector(removeHighlight) withObject:self afterDelay:0.2];
		
		[m_DownloadsManager addDownloadFile:m_DownloadURL withSHA1:[self.firmwareSHA1 stringValue]];
	}
	else if (returnCode == NSAlertThirdButtonReturn) {
		[self cancelButtonPressed:m_Tempitem];
	}
	
	alertReturnStatus = returnCode;
}

#pragma mark - System Functions

- (IBAction) goToURL:(id)sender
{	
	NSURL *url = [self getHiperLinkForTool:[sender title]];
	
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (void) setHiperLinkForTextField:(NSTextView*) textField
{
	[textField setLinkTextAttributes:nil];
	
	NSString *text = [[textField textStorage] string];
	NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:text];
	[attrString addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:13] range:[text rangeOfString:text]];
	
	NSArray *arr = [text componentsSeparatedByString:@", "];
	
	[attrString beginEditing];
	
	NSMutableParagraphStyle *truncateStyle = [[NSMutableParagraphStyle alloc] init];
	[truncateStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	
	for (int i = 0; i < [arr count]; ++i) {
		NSArray *arr2 = [arr[i] componentsSeparatedByString:@" "];
		NSURL *url = [self getHiperLinkForTool:arr2[0]];
		
		if (url == nil) {
			continue;
		}

		NSDictionary *dict = @{	NSLinkAttributeName: url,
								NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:0.058 green:0.385 blue:0.784 alpha:1.000],
								NSCursorAttributeName:[NSCursor pointingHandCursor],
								NSParagraphStyleAttributeName:truncateStyle
						  };
		NSRange range = [text rangeOfString:arr2[0]];
		[attrString addAttributes: dict range: range];
	}
	
	[attrString endEditing];
	
	[textField setEditable:NO];
	
	// do not display background
	[textField setDrawsBackground:NO];
	[[textField enclosingScrollView] setDrawsBackground:NO];
	
	// remove borders and scrollers
	[[textField enclosingScrollView] setAutohidesScrollers:YES];
	[[textField enclosingScrollView] setBorderType:NSNoBorder];
	
	// and finally set attributed string
	[[textField textStorage] setAttributedString:attrString];
}

- (NSURL*) getHiperLinkForTool:(NSString*)tool
{
	tool = [tool lowercaseString];
	
	NSEnumerator *enumerator = [m_LinksDict keyEnumerator];
	
	for(NSString *aKey in enumerator){
		NSMutableDictionary *jbMenu = m_LinksDict[aKey];
		for (NSString *name in jbMenu) {
			if ([tool isEqualToString:[name lowercaseString]])
			{
				return [NSURL URLWithString:jbMenu[name]];
			}
		}
    }
	
	return nil;
}

- (void) setControlsEnabled:(BOOL) yesno
{
	[self.device setEnabled: yesno ];
	[self.firmware setEnabled: yesno ];
	[self.downloadButton setEnabled: yesno ];
	[self.infoButton setEnabled: yesno ];
}

- (BOOL) internetEnabledWithAlert:(bool)showAlert
{
	if (!m_bInternet && showAlert) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK")];
		[alert setMessageText:NSLocalizedString(@"No Internet Connection", @"No Internet Connection")];
		[alert setInformativeText:NSLocalizedString(@"Please check your Internet connection", @"Please check your Internet connection")];
		
		[self startAlert:alert selector:@selector(closeAlert:returnCode:contextInfo:)];
	}
	return m_bInternet;
}

-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
	if (!m_PlistDict && [m_PlistDict count] == 0) {
		NSMutableDictionary* dict = [m_plistParser loadListWithInterval:m_dbUpdateInterval];
		m_PlistDict = [[NSMutableDictionary alloc] initWithDictionary:dict[@"firmware"]];
		m_LinksDict = [[NSMutableDictionary alloc] initWithDictionary:dict[@"links"]];
		m_DevicesDict = [[NSMutableDictionary alloc] initWithDictionary:dict[@"devices"]];
	}
	
	if (m_PlistDict) {
		[self setControlsEnabled: YES];
		
		[self addItemsToDevice];
	}
	if (m_LinksDict) {
		[self createMenus];
	}
	
    if([reach isReachable])
    {
		
    }
    else
    {
        [self internetEnabledWithAlert:true];
    }
}

- (IBAction) openPreference:(id) sender
{
	if (!m_Preference)
	{
		m_Preference = [[PreferenceController alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(windowPreferenceWillClose:)
													 name:NSWindowWillCloseNotification
												   object:nil];
	}
	
	[m_Preference showWindow:self];
}

- (IBAction) openDeviceInfo:(id) sender
{
	if (!m_DeviceInfo)
	{
		m_DeviceInfo = [[DeviceInfo alloc] initWithMobileDeviceServer:m_MobileDeviceServer withPlist:m_DevicesDict];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(windowDeviceInfoWillClose:)
													 name:NSWindowWillCloseNotification
												   object:nil];
	}
	
	[m_DeviceInfo showWindow:self];
}

- (void)windowPreferenceWillClose:(NSNotification *)notification;
{	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowWillCloseNotification
												  object:nil];
	
	m_Preference = nil;
	
	NSUserDefaults* appPrefs = [NSUserDefaults standardUserDefaults];
	
	m_dbUpdateInterval = [appPrefs integerForKey:defaultsDBUpdateKey];
}

- (void)windowDeviceInfoWillClose:(NSNotification *)notification;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowWillCloseNotification
												  object:nil];
	
	m_DeviceInfo = nil;
}

- (IBAction) simpleMode:(id) sender
{
	if (m_bSimpleMode) {
		[self.simpleModeMenu setState:NSOnState];
		
		[self.detailsBox setHidden:YES];
		NSRect rect = self.window.frame;
		rect.size.height = 120.0;
		[self.window setFrame:rect display:YES animate:YES];
	}
	else {
		[self.simpleModeMenu setState:NSOffState];

		[self.detailsBox setHidden:NO];
		NSRect rect = self.window.frame;
		rect.size.height = 364.0;
		[self.window setFrame:rect display:YES animate:YES];
	}
	
	NSUserDefaults* appPrefs = [NSUserDefaults standardUserDefaults];
	
	[appPrefs setObject:@(m_bSimpleMode)
                      forKey:defaultsSimpleModeKey];
	[appPrefs synchronize];
	
	m_bSimpleMode = !m_bSimpleMode;
}

- (IBAction) reloadDB:(id) sender
{
	if ([self internetEnabledWithAlert:true])
	{
		[self deviceRemoved];
		
		NSMutableDictionary* dict = [m_plistParser loadListWithInterval:UPDATE_AT_APP_START];
        m_PlistDict = [[NSMutableDictionary alloc] initWithDictionary:dict[@"firmware"]];
		m_LinksDict = [[NSMutableDictionary alloc] initWithDictionary:dict[@"links"]];
		m_DevicesDict = [[NSMutableDictionary alloc] initWithDictionary:dict[@"devices"]];
		
		if (m_PlistDict) {
			[self setControlsEnabled: YES];
			
			[self addItemsToDevice];
		}
		if (m_LinksDict) {
			[self createMenus];
		}
		
		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
		dispatch_async(queue, ^{
			[m_MobileDeviceServer scanForDevice];
		});
	}
	else {
		[self setControlsEnabled: NO];
	}
}

#pragma mark - Preference
+ (void)initialize
{
    // Create a dictionary
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
    // Put defaults in the dictionary
	/*[defaultValues setObject:[NSString stringWithString:@"English"]
                      forKey:defaultsLanguageKey];*/
	defaultValues[defaultsDBUpdateKey] = @(UPDATE_EVERY_DAY);
    defaultValues[defaultsUseSoundKey] = @YES;
	defaultValues[defaultsSimpleModeKey] = @NO;
	defaultValues[defaultsCheckSHA1Key] = @YES;
	defaultValues[defaultsUseNotificationKey] = @YES;
	
	
    // Register the dictionary of defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];

    DBNSLog(@"registered defaults: %@", defaultValues);
}
#pragma mark - window delegates

// ask to save changes if dirty
- (BOOL)windowShouldClose:(id)sender
{
#pragma unused(sender)
	
    return YES;
}

#pragma mark - application delegates

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
#pragma unused(sender)
	
    return NSTerminateNow;
}

// split when window is closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
#pragma unused(sender)
	
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification { }

- (void) awakeFromNib {	}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)newFrame {
	
	[self simpleMode:nil];
	return NO;
}

- (void)createMenus
{
	[self.toolsMenu removeAllItems];
	[self.supportMenu removeAllItems];
	
	NSMutableDictionary *jbMenu = m_LinksDict[@"Jailbreake"];
	
	NSArray* arrayKey = [NSArray arrayWithArray:[jbMenu allKeys]];
	NSArray* sortedKeys = [arrayKey sortedArrayUsingSelector:@selector(localizedCompare:)];
	
	int i = 0;
	
	for (NSString *menuName in sortedKeys) {
		
		NSMenuItem *menuInem = [[NSMenuItem alloc] initWithTitle:menuName action:@selector(goToURL:) keyEquivalent:@""];
		NSImage *img = [NSImage imageNamed:menuName];
		if (img) {
			[menuInem setImage:img];
		}
		[self.toolsMenu insertItem:menuInem atIndex:i++];
	}
	[self.toolsMenu insertItem:[NSMenuItem separatorItem] atIndex:i++];
	
	jbMenu = m_LinksDict[@"Unlock"];
	
	arrayKey = [NSArray arrayWithArray:[jbMenu allKeys]];
	sortedKeys = [arrayKey sortedArrayUsingSelector:@selector(localizedCompare:)];
	
	for (NSString *menuName in sortedKeys) {
		NSMenuItem *menuInem = [[NSMenuItem alloc] initWithTitle:menuName action:@selector(goToURL:) keyEquivalent:@""];
		NSImage *img = [NSImage imageNamed:menuName];
		if (img) {
			[menuInem setImage:img];
		}
		[self.toolsMenu insertItem:menuInem atIndex:i++];
	}
	[self.toolsMenu insertItem:[NSMenuItem separatorItem] atIndex:i++];
	
	jbMenu = m_LinksDict[@"Tools"];
	
	arrayKey = [NSArray arrayWithArray:[jbMenu allKeys]];
	sortedKeys = [arrayKey sortedArrayUsingSelector:@selector(localizedCompare:)];
	
	for (NSString *menuName in sortedKeys) {
		NSMenuItem *menuInem = [[NSMenuItem alloc] initWithTitle:menuName action:@selector(goToURL:) keyEquivalent:@""];
		NSImage *img = [NSImage imageNamed:menuName];
		if (img) {
			[menuInem setImage:img];
		}
		[self.toolsMenu insertItem:menuInem atIndex:i++];
	}
	
	i = 0;
	jbMenu = m_LinksDict[@"Support"];
	
	arrayKey = [NSArray arrayWithArray:[jbMenu allKeys]];
	sortedKeys = [arrayKey sortedArrayUsingSelector:@selector(localizedCompare:)];
	
	for (NSString *menuName in sortedKeys) {
		NSMenuItem *menuInem = [[NSMenuItem alloc] initWithTitle:menuName action:@selector(goToURL:) keyEquivalent:@""];
		NSImage *img = [NSImage imageNamed:menuName];
		if (img) {
			[menuInem setImage:img];
		}
		[self.supportMenu insertItem:menuInem atIndex:i++];
	}
}

- (BOOL)buttonIsPressed
{
    return self.downloadsButton.intValue == 1;
}

- (IBAction) togglePopover:(id)sender
{
	if (self.buttonIsPressed) {
        [self.popover showRelativeToRect:[self.downloadsButton bounds] ofView:self.downloadsButton preferredEdge:NSMinXEdge | NSMaxYEdge];
    } else {
        [self.popover close];
    }
}

- (void)updateDownloadInfo
{
	// reload the array with data first.
	[self.downloadsList reloadData];
}

- (void)newDeviceDetected:(NSString*)connectedDevice
{
	if (m_PlistDict && [m_PlistDict count] > 0)
	{
		NSDictionary *info = m_DevicesDict[connectedDevice];
		
		if (info) {
			NSString *val = info[@"device"];
			int index = [self.device indexOfItemWithObjectValue:val];
			if (index >= 0) {
				[self.device selectItemAtIndex:index];
				[self addItemsToFirmware:val];
			}
		}
	
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:1.0];
		[self.device setFrame:NSMakeRect(55, 295, 182, 26)];
		[NSAnimationContext endGrouping];
		
		[self.infoDeviceButton setHidden:NO];
	}
}

- (void)deviceRemoved
{
	[self.infoDeviceButton setHidden:YES];
	
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:1.0];
	[self.device setFrame:NSMakeRect(20, 295, 217, 26)];
	[NSAnimationContext endGrouping];
	
	[m_DeviceInfo close];
}

@end
