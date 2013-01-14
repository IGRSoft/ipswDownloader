//
//  IPSWInfoHelper.m
//  ipswDownloader
//
//  Created by Vitaly Parovishnik on 17.08.12.
//
//

#import "IPSWInfoHelper.h"

@implementation IPSWInfoHelper

#define IPHONE_1G_NAMESTRING            @"iPhone"
#define IPHONE_3G_NAMESTRING            @"iPhone 3G"
#define IPHONE_3GS_NAMESTRING           @"iPhone 3GS"
#define IPHONE_4_NAMESTRING             @"iPhone 4"
#define IPHONE_4_CDMA_NAMESTRING        @"iPhone 4 CDMA"
#define IPHONE_4S_NAMESTRING            @"iPhone 4S"
#define IPHONE_5_NAMESTRING             @"iPhone 5"
#define IPHONE_UNKNOWN_NAMESTRING       @"iPhone Unknown"

#define IPOD_1G_NAMESTRING              @"iPod Touch 1G"
#define IPOD_2G_NAMESTRING              @"iPod Touch 2G"
#define IPOD_3G_NAMESTRING              @"iPod Touch 3G"
#define IPOD_4G_NAMESTRING              @"iPod Touch 4G"
#define IPOD_UNKNOWN_NAMESTRING         @"iPod Unknown"

#define IPAD_1G_NAMESTRING              @"iPad 1G"
#define IPAD_2G_WIFI_NAMESTRING         @"iPad 2G Wi-Fi"
#define IPAD_2G_CDMA_NAMESTRING         @"iPad 2G CDMA"
#define IPAD_2G_GSM_NAMESTRING          @"iPad 2G GSM"
#define IPAD_2G_R2_NAMESTRING           @"iPad 2G Wi-Fi R2"
#define IPAD_3G_WIFI_NAMESTRING         @"iPad 3G Wi-Fi"
#define IPAD_3G_CDMA_NAMESTRING         @"iPad 3G CDMA"
#define IPAD_3G_GLOBAL_NAMESTRING       @"iPad 3G Global"
#define IPAD_UNKNOWN_NAMESTRING         @"iPad Unknown"

#define APPLETV_2G_NAMESTRING           @"Apple TV 2G"
#define APPLETV_3G_NAMESTRING           @"Apple TV 3G"
#define APPLETV_UNKNOWN_NAMESTRING      @"Apple TV Unknown"

#define IOS_FAMILY_UNKNOWN_DEVICE       @"Unknown iOS device"

+ (NSString*)nameIPWS:(NSString*)fileName
{
	NSArray* devices = [fileName componentsSeparatedByString:@"_"];
	NSString *platform = devices[0];
	NSString *version = devices[1];
	NSString *code = devices[2];
	
	if (platform == nil || version == nil || code == nil) {
		return fileName;
	}
	
	NSString *name = IOS_FAMILY_UNKNOWN_DEVICE;
	
    // iPhone
    if ([platform isEqualToString:@"iPhone1,1"])		platform = IPHONE_1G_NAMESTRING;
    else if ([platform isEqualToString:@"iPhone1,2"])   platform = IPHONE_3G_NAMESTRING;
    else if ([platform isEqualToString:@"iPhone2,1"])   platform = IPHONE_3GS_NAMESTRING;
    else if ([platform isEqualToString:@"iPhone3,1"])   platform = IPHONE_4_NAMESTRING;
	else if ([platform isEqualToString:@"iPhone3,3"])   platform = IPHONE_4_CDMA_NAMESTRING;
    else if ([platform isEqualToString:@"iPhone4,1"])   platform = IPHONE_4S_NAMESTRING;
    
    // iPod
    else if ([platform hasPrefix:@"iPod1"])				platform = IPOD_1G_NAMESTRING;
    else if ([platform hasPrefix:@"iPod2"])				platform = IPOD_2G_NAMESTRING;
    else if ([platform hasPrefix:@"iPod3"])				platform = IPOD_3G_NAMESTRING;
    else if ([platform hasPrefix:@"iPod4"])				platform = IPOD_4G_NAMESTRING;
	
    // iPad
    else if ([platform isEqualToString:@"iPad1,1"])     platform = IPAD_1G_NAMESTRING;
    else if ([platform isEqualToString:@"iPad2,1"])     platform = IPAD_2G_WIFI_NAMESTRING;
	else if ([platform isEqualToString:@"iPad2,2"])     platform = IPAD_2G_GSM_NAMESTRING;
	else if ([platform isEqualToString:@"iPad2,3"])     platform = IPAD_2G_CDMA_NAMESTRING;
	else if ([platform isEqualToString:@"iPad2,4"])     platform = IPAD_2G_R2_NAMESTRING;
    else if ([platform isEqualToString:@"iPad3,1"])     platform = IPAD_3G_WIFI_NAMESTRING;
	else if ([platform isEqualToString:@"iPad3,2"])     platform = IPAD_3G_CDMA_NAMESTRING;
	else if ([platform isEqualToString:@"iPad3,3"])     platform = IPAD_3G_GLOBAL_NAMESTRING;
    
    // Apple TV
    else if ([platform isEqualToString:@"AppleTV2,1"])  platform = APPLETV_2G_NAMESTRING;
	else if ([platform isEqualToString:@"AppleTV3,1"])  platform = APPLETV_3G_NAMESTRING;
	
    else if ([platform hasPrefix:@"iPhone"])            platform = IPHONE_UNKNOWN_NAMESTRING;
    else if ([platform hasPrefix:@"iPod"])              platform = IPOD_UNKNOWN_NAMESTRING;
    else if ([platform hasPrefix:@"iPad"])              platform = IPAD_UNKNOWN_NAMESTRING;
	else if ([platform hasPrefix:@"AppleTV"])           platform = APPLETV_UNKNOWN_NAMESTRING;
	
	name = [NSString stringWithFormat:@"%@ %@(%@)", platform, version, code];
	
	return name;
}

@end
