//
//  MobileDeviceServer.h
//  ipswDownloader
//
//  Created by Vitalii Parovishnyk on 12/17/12.
//
//

#import <Foundation/Foundation.h>

@protocol MobileDeviceServerDelegate <NSObject>
@optional
- (void)newDeviceDetected:(NSString*)connectedDevice;
- (void)deviceRemoved;
@end

@interface MobileDeviceServer : NSObject
{
	NSMutableDictionary*			m_PlistDict;
	id <MobileDeviceServerDelegate>	_delegate;
}

@property (nonatomic, strong) id <MobileDeviceServerDelegate> delegate;

- (void) scanForDevice;
- (bool) isConnected;
- (NSString *) deviceName;
- (NSString *) deviceProductType;
- (NSString *) deviceProductVersion;
- (NSString *) deviceCapacity;
- (NSString *) deviceSerialNumber;
- (NSString *) devicePhoneNumber;
- (NSString *) deviceClass;
- (NSString *) deviceColor;
- (NSString *) deviceBaseband;
- (NSString *) deviceBootloader;
- (NSString *) deviceHardwareModel;
- (NSString *) deviceUniqueDeviceID;
- (NSString *) deviceCPUArchitecture;
- (NSString *) deviceHardwarePlatform;
- (NSString *) deviceBluetoothAddress;
- (NSString *) deviceWiFiAddress;
- (NSString *) deviceModelNumber;
- (NSString *) deviceAllInfo;
- (NSString *) deviceAFSTotalBytes;
- (NSString *) deviceAFSFreeBytes;
- (bool) deviceEnterRecovery;
- (bool) deviceExitRecovery;
- (NSArray*) appsList;

@end
