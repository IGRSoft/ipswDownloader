//
//  IPSWInfoHelper.m
//  ipswDownloader
//
//  Created by Vitaly Parovishnik on 17.08.12.
//
//

#import "IPSWInfoHelper.h"

@implementation IPSWInfoHelper

+ (NSString*)nameIPWS:(NSString*)fileName
{
	NSArray* devices = [fileName componentsSeparatedByString:@"_"];
	NSString *platform = devices[0];
	NSString *version = devices[1];
	NSString *code = devices[2];
	
	if (platform == nil || version == nil || code == nil) {
		return fileName;
	}
	
	NSString *name = @"Unknown";
	
    // iPhone
	if ([platform isEqualToString:@"iPhone1,1"])		 platform = @"iPhone 2G";
    else if ([platform isEqualToString:@"iPhone1,2"])    platform = @"iPhone 3G";
    else if ([platform isEqualToString:@"iPhone2,1"])    platform = @"iPhone 3GS";
    else if ([platform isEqualToString:@"iPhone3,1"])    platform = @"iPhone 4 (GSM)";
    else if ([platform isEqualToString:@"iPhone3,2"])    platform = @"iPhone 4 (GSM Rev. A)";
    else if ([platform isEqualToString:@"iPhone3,3"])    platform = @"iPhone 4 (CDMA)";
    else if ([platform isEqualToString:@"iPhone4,1"])    platform = @"iPhone 4S";
    else if ([platform isEqualToString:@"iPhone5,1"])    platform = @"iPhone 5 (GSM)";
    else if ([platform isEqualToString:@"iPhone5,2"])    platform = @"iPhone 5 (Global)";
    else if ([platform isEqualToString:@"iPhone5,3"])    platform = @"iPhone 5C (GSM)";
    else if ([platform isEqualToString:@"iPhone5,4"])    platform = @"iPhone 5C (Global)";
    else if ([platform isEqualToString:@"iPhone6,1"])    platform = @"iPhone 5S (GSM)";
    else if ([platform isEqualToString:@"iPhone6,2"])    platform = @"iPhone 5S (Global)";
    
	//ipod
    else if ([platform isEqualToString:@"iPod1,1"])      platform = @"iPod Touch (1 Gen)";
    else if ([platform isEqualToString:@"iPod2,1"])      platform = @"iPod Touch (2 Gen)";
    else if ([platform isEqualToString:@"iPod3,1"])      platform = @"iPod Touch (3 Gen)";
    else if ([platform isEqualToString:@"iPod4,1"])      platform = @"iPod Touch (4 Gen)";
    else if ([platform isEqualToString:@"iPod5,1"])      platform = @"iPod Touch (5 Gen)";
    
	//ipad
    else if ([platform isEqualToString:@"iPad1,1"])      platform = @"iPad (WiFi)";
    else if ([platform isEqualToString:@"iPad1,2"])      platform = @"iPad 3G";
    else if ([platform isEqualToString:@"iPad2,1"])      platform = @"iPad 2 (WiFi)";
    else if ([platform isEqualToString:@"iPad2,2"])      platform = @"iPad 2 (GSM)";
    else if ([platform isEqualToString:@"iPad2,3"])      platform = @"iPad 2 (CDMA)";
    else if ([platform isEqualToString:@"iPad2,4"])      platform = @"iPad 2 (WiFi Rev. A)";
    else if ([platform isEqualToString:@"iPad2,5"])      platform = @"iPad Mini (WiFi)";
    else if ([platform isEqualToString:@"iPad2,6"])      platform = @"iPad Mini (GSM)";
    else if ([platform isEqualToString:@"iPad2,7"])      platform = @"iPad Mini (CDMA)";
    else if ([platform isEqualToString:@"iPad3,1"])      platform = @"iPad 3 (WiFi)";
    else if ([platform isEqualToString:@"iPad3,2"])      platform = @"iPad 3 (CDMA)";
    else if ([platform isEqualToString:@"iPad3,3"])      platform = @"iPad 3 (Global)";
    else if ([platform isEqualToString:@"iPad3,4"])      platform = @"iPad 4 (WiFi)";
    else if ([platform isEqualToString:@"iPad3,5"])      platform = @"iPad 4 (CDMA)";
    else if ([platform isEqualToString:@"iPad3,6"])      platform = @"iPad 4 (Global)";
    else if ([platform isEqualToString:@"iPad4,1"])      platform = @"iPad Air (WiFi)";
    else if ([platform isEqualToString:@"iPad4,2"])      platform = @"iPad Air (WiFi+GSM)";
    else if ([platform isEqualToString:@"iPad4,3"])      platform = @"iPad Air (WiFi+CDMA)";
    else if ([platform isEqualToString:@"iPad4,4"])      platform = @"iPad Mini Retina (WiFi)";
    else if ([platform isEqualToString:@"iPad4,5"])      platform = @"iPad Mini Retina (WiFi+CDMA)";
	
	else if ([platform hasPrefix:@"iPhone"])             platform = @"Unknown iPhone";
    else if ([platform hasPrefix:@"iPod"])               platform = @"Unknown iPod";
    else if ([platform hasPrefix:@"iPad"])               platform = @"Unknown iPad";
	else if ([platform hasPrefix:@"AppleTV"])            platform = @"Unknown AppleTV";
	
	
	name = [NSString stringWithFormat:@"%@ %@(%@)", platform, version, code];
	
	return name;
}

@end
