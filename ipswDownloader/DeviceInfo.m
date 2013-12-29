//
//  DeviceInfo.m
//  ipswDownloader
//
//  Created by Vitalii Parovishnyk on 12/27/12.
//
//

#import "DeviceInfo.h"
#import "MobileDeviceServer.h"
#import "ItemCellView.h"

NSString* const IMG_URL = @"http://igrsoft.com/wp-content/iPhone/devices";

@interface DeviceInfo ()

@end

@implementation DeviceInfo

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (id)initWithMobileDeviceServer:(MobileDeviceServer*)_mobileDeviceServer withPlist:(NSMutableDictionary*)plist
{
	self = [super initWithWindowNibName:@"DeviceInfo"];
    if (self) {
        mobileDeviceServer = _mobileDeviceServer;
		m_DevicesDict = [plist copy];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^{
		
		NSString *originalDeviceName = [mobileDeviceServer deviceClass];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_originalDeviceName setStringValue:originalDeviceName];
		});
		
		NSString *productType = [mobileDeviceServer deviceProductType];
		NSDictionary *info = m_DevicesDict[productType];
		NSString *color = [mobileDeviceServer deviceColor];
		
		NSImage *img = nil;
		if (info) {
			NSString *imgKey = @"img";
			if (![color isEqualToString:@"black"]) {
				imgKey = [imgKey stringByAppendingFormat:@"_%@", color];
			}
			NSString *sImg = info[imgKey];
			if (sImg)
			{
				NSString *val = [IMG_URL stringByAppendingString:[NSString stringWithFormat:@"/%@", sImg]];
				img = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:val]];
			}
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			if (img) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[_devicePic setImage:img];
				});
			}
		});
		
		NSString *deviceName = [mobileDeviceServer deviceName];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceName setStringValue:deviceName];
		});
		
		NSString *deviceProductVersion = [mobileDeviceServer deviceProductVersion];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceOSVersion setStringValue:deviceProductVersion];
		});
		
		NSString *deviceSerialNumber = [mobileDeviceServer deviceSerialNumber];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceSerialNumber setStringValue:deviceSerialNumber];
		});
		
		NSString *devicePhoneNumber = [mobileDeviceServer devicePhoneNumber];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_devicePhoneNumber setStringValue:devicePhoneNumber];
		});
		
		NSString *deviceBaseband = [mobileDeviceServer deviceBaseband];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceBaseband setStringValue:deviceBaseband];
		});
		
		NSString *deviceBootloader = [mobileDeviceServer deviceBootloader];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceBootloader setStringValue:deviceBootloader];
		});
		
		NSString *deviceHardwareModel = [mobileDeviceServer deviceHardwareModel];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceHardwareModel setStringValue:deviceHardwareModel];
		});
		
		NSString *deviceModelNumber = [mobileDeviceServer deviceModelNumber];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceModelNumber setStringValue:deviceModelNumber];
		});
		
		NSString *deviceUniqueDeviceID = [mobileDeviceServer deviceUniqueDeviceID];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceUDID setStringValue:deviceUniqueDeviceID];
		});
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceProdictType setStringValue:productType];
			[_deviceColor setStringValue:color];
		});
		
		NSString *deviceCPUArchitecture = [mobileDeviceServer deviceCPUArchitecture];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceCPU setStringValue:deviceCPUArchitecture];
		});
		
		NSString *deviceHardwarePlatform = [mobileDeviceServer deviceHardwarePlatform];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceHardwarePlatform setStringValue:deviceHardwarePlatform];
		});
		
		NSString *deviceBluetoothAddress = [mobileDeviceServer deviceBluetoothAddress];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceBluetoothAddress setStringValue:deviceBluetoothAddress];
		});
		
		NSString *deviceWiFiAddress = [mobileDeviceServer deviceWiFiAddress];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceWiFiAddress setStringValue:deviceWiFiAddress];
		});
		
		NSString *totalBytes = [mobileDeviceServer deviceAFSTotalBytes];
		NSString *freeBytes = [mobileDeviceServer deviceAFSFreeBytes];
		float total = [totalBytes floatValue] / BYTE_IN_GB;
		float free = [freeBytes floatValue] / BYTE_IN_GB;
		float filled = total - free;
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceCapacity setStringValue:[NSString stringWithFormat:@"%.3f GB", total]];
			[_deviceFilledCapacity setStringValue:[NSString stringWithFormat:@"%.3f GB", filled]];
			[_deviceFreeCapacity setStringValue:[NSString stringWithFormat:@"%.3f GB", free]];
			
			[_progressIndicator setMinValue:0];
			[_progressIndicator setMaxValue:total];
			[_progressIndicator setDoubleValue:filled];
		});
		
		m_AppsList = [[NSArray alloc] initWithArray:[mobileDeviceServer appsList]];
		dispatch_async(dispatch_get_main_queue(), ^{
			[_deviceInfo setString:[mobileDeviceServer deviceAllInfo]];
			if ([m_AppsList count] > 0) {
				[_appsList reloadData];
			}
		});
	});
}

- (IBAction)enterRecovery:(id)sender
{
	[mobileDeviceServer deviceEnterRecovery];
}

- (IBAction)exitRecovery:(id)sender
{
	[mobileDeviceServer deviceExitRecovery];
}

#pragma mark - NSTableViewDelegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [m_AppsList count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	ItemCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	
	NSDictionary *dic = m_AppsList[row];
	result.textField.stringValue = dic[@"app_name"];
	result.detailTextField.stringValue = dic[@"app_version"];
	
	NSString *iconPath = dic[@"app_icon"];
	if ([iconPath length] > 0) {
		NSImage *img = [[NSImage alloc] initWithContentsOfFile:iconPath];
		result.imageView.image = img;
	}
	
	return result;
}

@end
