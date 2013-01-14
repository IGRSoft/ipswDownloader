//
//  DeviceInfo.h
//  ipswDownloader
//
//  Created by Vitalii Parovishnyk on 12/27/12.
//
//

#import <Cocoa/Cocoa.h>

@class MobileDeviceServer;
@class NSColoredView;

@interface DeviceInfo : NSWindowController <NSTableViewDelegate> {
	
	NSMutableDictionary*	m_DevicesDict;
	MobileDeviceServer*		mobileDeviceServer;
	NSArray*				m_AppsList;
}

- (id)initWithMobileDeviceServer:(MobileDeviceServer*) mobileDeviceServer withPlist:(NSMutableDictionary*)plist;

///////////////////////////////Summary///////////////////////////////
//Basic
@property (nonatomic, strong) IBOutlet NSImageView *devicePic;
@property (nonatomic, assign) IBOutlet NSTextField *originalDeviceName;
@property (nonatomic, assign) IBOutlet NSTextField *deviceName;
@property (nonatomic, assign) IBOutlet NSTextField *deviceOSVersion;
@property (nonatomic, assign) IBOutlet NSTextField *deviceSerialNumber;
@property (nonatomic, assign) IBOutlet NSTextField *devicePhoneNumber;

//Advanced
@property (nonatomic, assign) IBOutlet NSTextField *deviceBaseband;
@property (nonatomic, assign) IBOutlet NSTextField *deviceBootloader;
@property (nonatomic, assign) IBOutlet NSTextField *deviceHardwareModel;
@property (nonatomic, assign) IBOutlet NSTextField *deviceModelNumber;
@property (nonatomic, assign) IBOutlet NSTextField *deviceUDID;
@property (nonatomic, assign) IBOutlet NSTextField *deviceColor;
@property (nonatomic, assign) IBOutlet NSTextField *deviceProdictType;
@property (nonatomic, assign) IBOutlet NSTextField *deviceCPU;
@property (nonatomic, assign) IBOutlet NSTextField *deviceHardwarePlatform;
@property (nonatomic, assign) IBOutlet NSTextField *deviceBluetoothAddress;
@property (nonatomic, assign) IBOutlet NSTextField *deviceWiFiAddress;

//Capacity
@property (nonatomic, assign) IBOutlet NSColoredView *coloredView;
@property (nonatomic, assign) IBOutlet NSTextField *deviceCapacity;
@property (nonatomic, assign) IBOutlet NSTextField *deviceFilledCapacity;
@property (nonatomic, assign) IBOutlet NSTextField *deviceFreeCapacity;
@property (nonatomic, assign) IBOutlet NSProgressIndicator *progressIndicator;

///////////////////////////////Info///////////////////////////////
@property (nonatomic, assign) IBOutlet NSTextView *deviceInfo;

///////////////////////////////Apps///////////////////////////////
@property (nonatomic, strong) IBOutlet NSTableView *appsList;

///////////////////////////////Utils///////////////////////////////
- (IBAction)enterRecovery:(id)sender;
- (IBAction)exitRecovery:(id)sender;

@end
