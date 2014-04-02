//
//  URLHelper.m
//  ipswDownloader
//
//  Created by Vitalii Parovishnyk on 28.04.12.
//  Copyright (c) 2012 IGR Spftware. All rights reserved.
//

#import "URLHelper.h"

@implementation URLHelper

+ (NSArray* )splitURL:(NSURL*)url
{	
	NSString* secondPart = [[NSString alloc] initWithString:[url lastPathComponent]];
	NSString* temp = [[NSString alloc] initWithString:[url relativeString]];
	NSUInteger i = [temp length];
	NSUInteger j = [secondPart length];
	NSString* firstPart = [[NSString alloc] initWithString:[temp substringToIndex:( i-j )]];
	
	NSArray* arr = @[firstPart, secondPart];
	
	return arr;
}

@end
