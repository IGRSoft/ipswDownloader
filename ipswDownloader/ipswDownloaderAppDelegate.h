//
//  ipswDownloaderAppDelegate.h
//  ipswDownloader
//
//  Created by Vitaly Parovishnik on 31.01.11.
//  Copyright 2011 IGR Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MobileDeviceServer.h"

extern bool needWaitProcess;

@class Item;
@class PreferenceController;
@class plistParser;
@class DownloadsManager;
@class DeviceInfo;

@interface ipswDownloaderAppDelegate : NSObject <NSApplicationDelegate, NSPopoverDelegate, NSTableViewDelegate, NSControlTextEditingDelegate, MobileDeviceServerDelegate> {
	
	DownloadsManager*				m_DownloadsManager;
	//windows
	PreferenceController*			m_Preference;
	DeviceInfo*						m_DeviceInfo;
	
	//ipsw data
	plistParser*					m_plistParser;
	
	NSURL*							m_DownloadURL;
	NSURL*							m_DocsURL;
	NSMutableDictionary*			m_PlistDict;
	NSMutableDictionary*			m_LinksDict;
	NSMutableDictionary*			m_DevicesDict;
	NSMutableDictionary*			m_FirmwareList;
	
	//alert
	NSInteger						alertReturnStatus;
	
	//user prefs
	int								m_dbUpdateInterval;
	bool							m_bSimpleMode;
	bool							m_bInternet;
	
	//downloads view
	NSTimer							*DownloadUpdateTimer;

	//temp items
	Item							*m_Tempitem;
	
	MobileDeviceServer				*m_MobileDeviceServer;
}

- (id) init;
- (void) dealloc;

@property (nonatomic, strong) IBOutlet NSWindow				*window;
@property (nonatomic, strong) IBOutlet NSBox*				detailsBox;

@property (nonatomic, strong) IBOutlet NSMenuItem*			simpleModeMenu;
@property (nonatomic, strong) IBOutlet NSMenu*				toolsMenu;
@property (nonatomic, strong) IBOutlet NSMenu*				supportMenu;

@property (nonatomic, strong) IBOutlet NSTableView			*downloadsList;
@property (nonatomic, strong) IBOutlet NSPopover			*popover;

@property (nonatomic, strong) IBOutlet NSTextField*			firmwareBaseband;
@property (nonatomic, strong) IBOutlet NSImageView			*firmwareJailbreak;
@property (nonatomic, strong) IBOutlet NSImageView			*firmwareUnlock;
@property (nonatomic, strong) IBOutlet NSTextField			*firmwareSize;
@property (nonatomic, strong) IBOutlet NSTextField			*firmwareInfo;
@property (nonatomic, strong) IBOutlet NSTextView			*firmwareJBTools;
@property (nonatomic, strong) IBOutlet NSTextView			*firmwareUTools;
@property (nonatomic, strong) IBOutlet NSTextField			*firmwareSHA1;
@property (nonatomic, strong) IBOutlet NSTextField			*firmwareBuild;
@property (nonatomic, strong) IBOutlet NSScrollView			*tfJailbreak;
@property (nonatomic, strong) IBOutlet NSScrollView			*tfUnlock;
@property (nonatomic, strong) IBOutlet NSTextField			*firmwareReleaseDate;

@property (nonatomic, strong) IBOutlet NSProgressIndicator	*animation;
@property (nonatomic, strong) IBOutlet NSComboBox			*device;
@property (nonatomic, strong) IBOutlet NSComboBox			*firmware;
@property (nonatomic, strong) IBOutlet NSButton				*downloadButton;
@property (nonatomic, strong) IBOutlet NSButton				*infoButton;
@property (nonatomic, strong) IBOutlet NSButton				*infoDeviceButton;
@property (nonatomic, strong) IBOutlet NSButton				*downloadsButton;

- (IBAction) downloadIPSW:(id) sender;
- (IBAction) selectDevice:(id) sender;
- (IBAction) selectFirmware:(id) sender;
- (IBAction) goToURL:(id) sender;
- (IBAction) appleInfo:(id) sender;
- (IBAction) openPreference:(id) sender;
- (IBAction) simpleMode:(id) sender;
- (IBAction) reloadDB:(id) sender;
- (IBAction) togglePopover:(id)sender;

- (void) addItemsToDevice;
- (void) addItemsToFirmware: (NSString*)device;
- (void) updateInfo: (NSString*)firmware;
- (void) openImageFor:(NSImageView*)_imageView withImageName:(NSString*)name;

- (BOOL) internetEnabledWithAlert:(bool)showAlert;
- (void) startAlert:(NSAlert*) alert selector:(SEL)alertSelector;

- (void) setHiperLinkForTextField:(NSTextView*) textField;
- (void) setControlsEnabled:(BOOL) yesno;

- (IBAction) showInFinder:(id)sender;
- (IBAction) cancelButtonPressed:(id) sender;

- (void) createMenus;

@end
