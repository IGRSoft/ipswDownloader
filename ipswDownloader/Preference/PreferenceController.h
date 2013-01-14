//
//  PreferenceController.h
//  ipswDownloader
//
//  Created by Vitaly Parovishnik on 22.05.11.
//  Copyright 2011 IGR Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

//extern NSString * const defaultsLanguageKey;
extern NSString * const defaultsDBUpdateKey;
extern NSString * const defaultsUseSoundKey;
extern NSString * const defaultsSimpleModeKey;
extern NSString * const defaultsCheckSHA1Key;
extern NSString * const defaultsUseNotificationKey;

@interface PreferenceController : NSWindowController {

	//    IBOutlet NSComboBox	*appLanguage;
	IBOutlet NSComboBox	*updateDB;
	IBOutlet NSButton	*useSound;
	IBOutlet NSButton	*useChecksum;
	IBOutlet NSButton	*useNotification;
	
	NSUserDefaults		*appPrefs;
}
//- (IBAction) setLanguage:(id) sender;
- (IBAction) setDBUpdate:(id) sender;
- (IBAction) setSound:(id) sender;
- (IBAction) setChecksum:(id) sender;
- (IBAction) setNotification:(id) sender;
- (void) setPrefs;
@end
