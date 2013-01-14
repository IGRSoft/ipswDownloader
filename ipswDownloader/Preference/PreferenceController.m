//
//  PreferenceController.m
//  ipswDownloader
//
//  Created by Vitaly Parovishnik on 22.05.11.
//  Copyright 2011 IGR Software. All rights reserved.
//

#import "PreferenceController.h"

//NSString * const defaultsLanguageKey = @"Language";
NSString * const defaultsDBUpdateKey = @"DBUpdateType";
NSString * const defaultsCheckSHA1Key = @"CheckSHA1";
NSString * const defaultsUseSoundKey = @"UseSound";
NSString * const defaultsUseNotificationKey = @"UseNotification";
NSString * const defaultsSimpleModeKey = @"SimpleMode";

@implementation PreferenceController

- (id)init
{
	if (!(self = [super initWithWindowNibName:@"Preference"]))
	{
		return nil;
	}
	
	return self;
}

-(void) windowDidLoad
{
	[self setPrefs];
}

- (IBAction) setDBUpdate:(id) sender
{
	[appPrefs setObject:@([updateDB indexOfSelectedItem])
                      forKey:defaultsDBUpdateKey];
	
	[appPrefs synchronize];
}

- (IBAction) setSound:(id) sender
{
	[appPrefs setObject:@([useSound state])
                      forKey:defaultsUseSoundKey];
	
	[appPrefs synchronize];
}

- (IBAction) setChecksum:(id) sender
{
	[appPrefs setObject:@([useChecksum state])
				 forKey:defaultsCheckSHA1Key];
	
	[appPrefs synchronize];
}

- (IBAction) setNotification:(id) sender
{
	[appPrefs setObject:@([useNotification state])
				 forKey:defaultsUseNotificationKey];
	
	[appPrefs synchronize];
}

- (void) setPrefs
{
	appPrefs = [NSUserDefaults standardUserDefaults];
	
	//[appLanguage setTitleWithMnemonic:[appPrefs stringForKey:defaultsLanguageKey]];
	[updateDB selectItemAtIndex:[appPrefs integerForKey:defaultsDBUpdateKey]];
	[useSound setState:[appPrefs boolForKey:defaultsUseSoundKey]];
	[useChecksum setState:[appPrefs boolForKey:defaultsCheckSHA1Key]];
	[useNotification setState:[appPrefs boolForKey:defaultsUseNotificationKey]];
	[appPrefs synchronize];
}

@end
