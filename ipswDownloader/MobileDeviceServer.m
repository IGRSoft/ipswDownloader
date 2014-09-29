//
//  MobileDeviceServer.m
//  ipswDownloader
//
//  Created by Vitalii Parovishnyk on 12/17/12.
//
//

#import "MobileDeviceServer.h"

#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/installation_proxy.h>
#include <libimobiledevice/lockdown.h>
#include <libimobiledevice/afc.h>
#include <libimobiledevice/sbservices.h>

#include <plist/plist.h>

typedef NS_ENUM(NSUInteger, deviceInfoType)
{
	deviceInfoTypeName = 0,
	deviceInfoTypeProductType,
	deviceInfoTypeCapacity,
	deviceInfoTypeProductVersion,
	deviceInfoTypeSerialNumber,
	deviceInfoTypePhoneNumber,
	deviceInfoTypeDeviceClass,
	deviceInfoTypeDeviceColor,
	deviceInfoTypeBasebandVersion,
	deviceInfoTypeFirmwareVersion,
	deviceInfoTypeHardwareModel,
	deviceInfoTypeUniqueDeviceID,
	deviceInfoTypeCPUArchitecture,
	deviceInfoTypeHardwarePlatform,
	deviceInfoTypeBluetoothAddress,
	deviceInfoTypeWiFiAddress,
	deviceInfoTypeModelNumber,
	
	deviceInfoTypeAll,
	
	deviceInfoTypeCount
};

typedef NS_ENUM(NSUInteger, deviceAFCInfoType)
{
	deviceAFSTotalBytes = 0,
	deviceAFSFreeBytes,
	
	deviceAFSInfoTypeCount	
};

static MobileDeviceServer* tmpSelf = nil;

@interface MobileDeviceServer ()
{
	idevice_t device;
	//lockdownd_client_t lockdownd;
	afc_client_t afc;
}

void device_event_cb(const idevice_event_t* event, void* userdata);
- (NSString *) deviceInfoFor:(deviceInfoType)deviceInfoType;
- (NSString *) deviceAFCInfoFor:(deviceAFCInfoType)deviceAFCInfoType;
- (void) checkNewDeviceEvent:(const idevice_event_t*)event withUserData:(void*)userdata;
- (lockdownd_client_t) getInfoForDevice:(idevice_t)_device;
NSString* load_icon (sbservices_client_t sbs, const char *_id);

@end

@implementation MobileDeviceServer

- (id)init
{
	if (!(self = [super init]))
	{
		return nil;
	}
	
	tmpSelf = self;
	
    return self;
}

- (void)setDelegate:(id<MobileDeviceServerDelegate>)delegate
{
    _delegate = delegate;
    idevice_event_subscribe(&device_event_cb, NULL);
}

- (id)copyWithZone:(NSZone *)zone
{
	MobileDeviceServer *mds = [[MobileDeviceServer alloc] init];
	mds->device = self->device;
	//mds->lockdownd = self->lockdownd;
	mds->afc = self->afc;
	
	return mds;
}

- (void)scanForDevice
{
	@synchronized(self)
    {
		device = [self findDevices];
		
		if (!device) {
			return;
		}
		
		afc = [self getAFCInfoForDevice:device];
		
		if (device && [self.delegate respondsToSelector:@selector(newDeviceDetected:)]) {
			[self.delegate newDeviceDetected:[self deviceProductType]];
		}
	}
}

- (idevice_t)findDevices
{
	idevice_t _device;
	
    char uuid[41];
    int count = 0;
    char **list = NULL;
    idevice_error_t device_status = 0;
	
	DBNSLog(@"INFO: Retrieving device list");

    if (idevice_get_device_list(&list, &count) < 0 || count == 0)
	{
		DBNSLog(@"ERROR: Cannot retrieve device list");
		return nil;
    }
	
    memset(uuid, '\0', 41);
    memcpy(uuid, list[0], 40);
    idevice_device_list_free(list);
    
	DBNSLog(@"INFO: Opening device");
    device_status = idevice_new(&_device, uuid);
    if (device_status != IDEVICE_E_SUCCESS)
	{
        if (device_status == IDEVICE_E_NO_DEVICE)
		{
			DBNSLog(@"ERROR: No device found");
        }
		else
		{
			DBNSLog(@"ERROR: Unable to open device, %d", device_status);
        }
		return nil;
    }
	
	return _device;
}

- (lockdownd_client_t)getInfoForDevice:(idevice_t)aDevice
{
    static lockdownd_client_t _lockdownd = NULL;
    
    if (!_lockdownd && aDevice)
    {
        lockdownd_error_t lockdownd_error = 0;
        DBNSLog(@"INFO: Creating lockdownd client");
        lockdownd_error = lockdownd_client_new_with_handshake(aDevice, &_lockdownd, "ipswDownloader");
        if(lockdownd_error != LOCKDOWN_E_SUCCESS) {
            DBNSLog(@"ERROR: Cannot create lockdownd client");
        }
    }
    else if (!aDevice)
    {
        _lockdownd = NULL;
    }
    
	return _lockdownd;
}

- (afc_client_t)getAFCInfoForDevice:(idevice_t)aDevice
{
	lockdownd_client_t client = [self getInfoForDevice:aDevice];
	
	afc_client_t _afc = NULL;
	
	lockdownd_service_descriptor_t descriptor = 0;
	
	if (!client)
	{
		return _afc;
	}
	
	if ((lockdownd_start_service(client, "com.apple.afc", &descriptor) != LOCKDOWN_E_SUCCESS) || !descriptor)
	{
		return _afc;
	}
	
	afc_client_new(aDevice, descriptor, &_afc);
	
	return _afc;
}

- (bool)isConnected
{
	return device != NULL;
}

- (void)dealloc
{
    [self getInfoForDevice:nil];
    
	if (device) idevice_free(device);
}

- (NSString *)deviceName
{	
	return [self deviceInfoFor:deviceInfoTypeName];
}

- (NSString *)deviceProductType
{
	return [self deviceInfoFor:deviceInfoTypeProductType];
}

- (NSString *)deviceProductVersion
{
	return [self deviceInfoFor:deviceInfoTypeProductVersion];
}

- (NSString *)deviceCapacity
{
	return [self deviceInfoFor:deviceInfoTypeCapacity];
}

- (NSString *)deviceSerialNumber
{
	return [self deviceInfoFor:deviceInfoTypeSerialNumber];
}

- (NSString *)devicePhoneNumber
{
	return [self deviceInfoFor:deviceInfoTypePhoneNumber];
}

- (NSString *)deviceClass
{
	return [self deviceInfoFor:deviceInfoTypeDeviceClass];
}

- (NSString *)deviceColor
{
	return [self deviceInfoFor:deviceInfoTypeDeviceColor];
}

- (NSString *)deviceBaseband
{
	return [self deviceInfoFor:deviceInfoTypeBasebandVersion];
}

- (NSString *)deviceBootloader
{
	return [self deviceInfoFor:deviceInfoTypeFirmwareVersion];
}

- (NSString *)deviceHardwareModel
{
	return [self deviceInfoFor:deviceInfoTypeHardwareModel];
}

- (NSString *)deviceUniqueDeviceID
{
	return [self deviceInfoFor:deviceInfoTypeUniqueDeviceID];
}

- (NSString *)deviceCPUArchitecture
{
	return [self deviceInfoFor:deviceInfoTypeCPUArchitecture];
}

- (NSString *)deviceHardwarePlatform
{
	return [self deviceInfoFor:deviceInfoTypeHardwarePlatform];
}

- (NSString *)deviceBluetoothAddress
{
	return [self deviceInfoFor:deviceInfoTypeBluetoothAddress];
}

- (NSString *)deviceWiFiAddress
{
	return [self deviceInfoFor:deviceInfoTypeWiFiAddress];
}

- (NSString *)deviceModelNumber
{
	return [self deviceInfoFor:deviceInfoTypeModelNumber];
}

- (NSString *)deviceAllInfo
{
	return [self deviceInfoFor:deviceInfoTypeAll];
}

- (NSString *)deviceAFSTotalBytes
{
	return [self deviceAFCInfoFor:deviceAFSTotalBytes];
}

- (NSString *)deviceAFSFreeBytes
{
	return [self deviceAFCInfoFor:deviceAFSFreeBytes];
}

- (NSString *)deviceInfoFor:(deviceInfoType)deviceInfoType
{
	const char *key = NULL;
	
	switch (deviceInfoType)
	{
		case deviceInfoTypeName:
			key = "DeviceName";
			break;
		case deviceInfoTypeProductType:
			key = "ProductType";
			break;
		case deviceInfoTypeCapacity:
			key = "ProductType";
			break;
		case deviceInfoTypeProductVersion:
			key = "ProductVersion";
			break;
		case deviceInfoTypeSerialNumber:
			key = "SerialNumber";
			break;
		case deviceInfoTypePhoneNumber:
			key = "PhoneNumber";
			break;
		case deviceInfoTypeDeviceClass:
			key = "DeviceClass";
			break;
		case deviceInfoTypeDeviceColor:
			key = "DeviceColor";
			break;
		case deviceInfoTypeBasebandVersion:
			key = "BasebandVersion";
			break;
		case deviceInfoTypeFirmwareVersion:
			key = "FirmwareVersion";
			break;
		case deviceInfoTypeHardwareModel:
			key = "HardwareModel";
			break;
		case deviceInfoTypeUniqueDeviceID:
			key = "UniqueDeviceID";
			break;
		case deviceInfoTypeCPUArchitecture:
			key = "CPUArchitecture";
			break;
		case deviceInfoTypeHardwarePlatform:
			key = "HardwarePlatform";
			break;
		case deviceInfoTypeBluetoothAddress:
			key = "BluetoothAddress";
			break;
		case deviceInfoTypeWiFiAddress:
			key = "WiFiAddress";
			break;
		case deviceInfoTypeModelNumber:
			key = "ModelNumber";
			break;
		case deviceInfoTypeAll:
			key = NULL;
			break;
		
		default:
			break;
	}
	plist_t value_node = NULL;

	lockdownd_client_t lockdownd = [self getInfoForDevice:device];
	lockdownd_get_value(lockdownd, NULL, key, &value_node);
	
	char *val = NULL;
	if (value_node)
	{
		if (key)
		{
			plist_get_string_val(value_node, &val);
		}
		else
		{
			uint32_t xml_length;
			plist_to_xml(value_node, &val, &xml_length);
		}
	}
	
	return val != NULL ? [NSString stringWithUTF8String:val] : @"";
}

- (NSString *)deviceAFCInfoFor:(deviceAFCInfoType)deviceAFCInfoType
{
	const char *key = NULL;
	
	switch (deviceAFCInfoType)
	{
		case deviceAFSTotalBytes:
			key = "FSTotalBytes";
			break;
		case deviceAFSFreeBytes:
			key = "FSFreeBytes";
			break;
		
		default:
			key = "Model";
			break;
	}
	
	char* val = NULL;
	afc_get_device_info_key (afc, key, &val );
	
	return val != NULL ? [NSString stringWithUTF8String:val] : @"";
}

void device_event_cb(const idevice_event_t* event, void* userdata)
{
	if (tmpSelf)
	{
		[tmpSelf checkNewDeviceEvent:event withUserData:userdata];
	}
}

- (void)checkNewDeviceEvent:(const idevice_event_t*)event withUserData:(void*)userdata
{
	if (event->event == IDEVICE_DEVICE_ADD)
	{
		[self scanForDevice];
	}
	else if (event->event == IDEVICE_DEVICE_REMOVE)
	{
        [self getInfoForDevice:nil];
		if (device) idevice_free(device);
		if ([self.delegate respondsToSelector:@selector(deviceRemoved)])
		{
			[self.delegate deviceRemoved];
		}
	}
}

- (bool)deviceEnterRecovery
{
	lockdownd_client_t lockdownd = [self getInfoForDevice:device];
	lockdownd_error_t isSuccessful = lockdownd_enter_recovery(lockdownd);
	
	return isSuccessful == LOCKDOWN_E_SUCCESS;
}

- (bool)deviceExitRecovery
{
	lockdownd_client_t lockdownd = [self getInfoForDevice:device];
	lockdownd_error_t isSuccessful = lockdownd_goodbye(lockdownd);
	
	return isSuccessful == LOCKDOWN_E_SUCCESS;
}

- (NSArray*)appsList
{
	lockdownd_service_descriptor_t descriptor = 0;
	instproxy_client_t ipc = NULL;
	lockdownd_client_t client = [self getInfoForDevice:device];
	sbservices_client_t sbs = NULL;
	if ((lockdownd_start_service
		 (client, "com.apple.mobile.installation_proxy",
		  &descriptor) != LOCKDOWN_E_SUCCESS) || !descriptor)
	{
			 DBNSLog(@"ERROR: Could not start com.apple.mobile.installation_proxy!");
			 return nil;
	}
	
	if (instproxy_client_new(device, descriptor, &ipc) != INSTPROXY_E_SUCCESS)
	{
		DBNSLog(@"ERROR: Could not connect to installation_proxy");
		return nil;
	}
	
	if ((lockdownd_start_service (client, "com.apple.springboardservices", &descriptor) != LOCKDOWN_E_SUCCESS) || !descriptor)
	{
		DBNSLog(@"INFO: Could not start com.apple.springboardservices!");
	}
	else
	{
		if (sbservices_client_new(device, descriptor, &sbs) != INSTPROXY_E_SUCCESS)
		{
			DBNSLog(@"INFO: Could not connect to springboard");
		}
	}
	
	int xml_mode = 0;
	plist_t client_opts = instproxy_client_options_new();
	instproxy_client_options_add(client_opts, "ApplicationType", "User", NULL);
	instproxy_error_t err;
	plist_t apps = NULL;
	
	err = instproxy_browse(ipc, client_opts, &apps);
	instproxy_client_options_free(client_opts);
	if (err != INSTPROXY_E_SUCCESS)
	{
		DBNSLog(@"ERROR: instproxy_browse returned %d", err);
		instproxy_client_free(ipc);
		if (sbs) sbservices_client_free(sbs);
		
		return nil;
	}
	if (!apps || (plist_get_node_type(apps) != PLIST_ARRAY))
	{
		DBNSLog(@"ERROR: instproxy_browse returnd an invalid plist!");
		instproxy_client_free(ipc);
		if (sbs) sbservices_client_free(sbs);
		
		return nil;
	}
	if (xml_mode)
	{
		char *xml = NULL;
		uint32_t len = 0;
		
		plist_to_xml(apps, &xml, &len);
		if (xml) {
			puts(xml);
			free(xml);
		}
		plist_free(apps);
		instproxy_client_free(ipc);
		if (sbs) sbservices_client_free(sbs);
	
		return nil;
	}
	//printf("Total: %d apps\n", plist_array_get_size(apps));
	NSMutableArray *arr = [NSMutableArray array];
	uint32_t i = 0;
	for (i = 0; i < plist_array_get_size(apps); ++i)
	{
		plist_t app = plist_array_get_item(apps, i);
		plist_t p_appid =
		plist_dict_get_item(app, "CFBundleIdentifier");
		char *s_appid = NULL;
		char *s_dispName = NULL;
		char *s_version = NULL;

		plist_t dispName = plist_dict_get_item(app, "CFBundleDisplayName");
		plist_t version = plist_dict_get_item(app, "CFBundleVersion");
		
		if (p_appid)
		{
			plist_get_string_val(p_appid, &s_appid);
		}
		if (!s_appid)
		{
			DBNSLog(@"ERROR: Failed to get APPID!");
			continue;
		}
		
		if (dispName)
		{
			plist_get_string_val(dispName, &s_dispName);
		}
		if (version)
		{
			plist_get_string_val(version, &s_version);
		}
		
		if (!s_dispName)
		{
			s_dispName = strdup(s_appid);
		}

		NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:s_dispName], @"app_name",
									@"", @"app_version",
									@"", @"app_icon",
									nil];
		if (s_version)
		{
			dic[@"app_version"] = [NSString stringWithUTF8String:s_version];
			free(s_version);
		}
		
		if (sbs)
		{
			NSString *s_icon = NULL;
			s_icon = load_icon(sbs, s_appid);
			if (s_icon)
			{
				dic[@"app_icon"] = s_icon;
			}
		}
		
		[arr addObject:dic];
		free(s_dispName);
		free(s_appid);
	}
	plist_free(apps);
	instproxy_client_free(ipc);
	if (sbs) sbservices_client_free(sbs);
	
	return arr;
}

NSString* load_icon(sbservices_client_t sbs, const char *_id)
{
	NSString *path;
	NSString *filename;
	char *data;
	uint64_t len;
	
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	NSError *error = nil;
	
	NSString *cache = [cachesPath stringByAppendingPathComponent:@"ipswDownloader"];
	if ([fm fileExistsAtPath:cache isDirectory:&isDir] && isDir)
	{
	}
	else
	{
		[fm createDirectoryAtPath:cache
	  withIntermediateDirectories:YES
					   attributes:nil
							error:&error];
		if (error)
		{
			DBNSLog(@"ERROR: Can't write a folder: %@!", cache);
			return nil;
		}
		
	}
	
	cache = [cache stringByAppendingPathComponent:@"icons"];
	if ([fm fileExistsAtPath:cache isDirectory:&isDir] && isDir)
	{
	}
	else
	{
		[fm createDirectoryAtPath:cache
	  withIntermediateDirectories:YES
					   attributes:nil
							error:&error];
		if (error)
		{
			DBNSLog(@"ERROR: Can't write a folder: %@!", cache);
			return nil;
		}
		
	}
	
	filename = [NSString stringWithFormat:@"%s.png", _id];
	path = [NSString stringWithFormat:@"%@/%@", cache, filename];
	
	if ([fm fileExistsAtPath:path])
		return path;
	
	data = NULL;
	len = 0;
	if (sbservices_get_icon_pngdata (sbs, _id, &data, &len) != SBSERVICES_E_SUCCESS ||
		data == NULL || len == 0)
    {
		if (data != NULL)
			free (data);
		return nil;
    }
	
	if (![fm createFileAtPath:path
					contents:[NSData dataWithBytes:data length:len]
				  attributes:nil])
	{
		DBNSLog(@"ERROR: Can't write a file: %@!", filename);
		free (data);
		return nil;
	}

	free (data);
	
	return path;
}

@end
