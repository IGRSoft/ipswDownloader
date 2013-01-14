//
//  sha1.h
//  ipswDownloader
//
//  Created by Vitalii Parovishnyk on 07.03.12.
//  Copyright (c) 2012 IGR Spftware. All rights reserved.
//

#ifndef ipswDownloader_sha1_h
#define ipswDownloader_sha1_h

// Cryptography
#import <CommonCrypto/CommonDigest.h>

// In bytes
#define FileHashDefaultChunkSizeForReadingData 4096

CFStringRef FileSHA1HashCreateWithPath(CFStringRef filePath, size_t chunkSizeForReadingData) 
{
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    
    // Get the file URL
    CFURLRef fileURL = 
	CFURLCreateWithFileSystemPath(kCFAllocatorDefault, 
								  (CFStringRef)filePath, 
								  kCFURLPOSIXPathStyle, 
								  (Boolean)false);
	bool didSucceed = false;
	unsigned char digest[CC_SHA1_DIGEST_LENGTH];
	
    if (fileURL)
	{
		// Create and open the read stream
		readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault, 
												(CFURLRef)fileURL);
		if (readStream)
			didSucceed = (bool)CFReadStreamOpen(readStream);
		if (didSucceed)
		{
			// Initialize the hash object
			CC_SHA1_CTX hashObject;
			CC_SHA1_Init(&hashObject);
			
			// Make sure chunkSizeForReadingData is valid
			if (!chunkSizeForReadingData) {
				chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
			}
			
			// Feed the data to the hash object
			bool hasMoreData = true;
			while (hasMoreData) {
				uint8_t buffer[chunkSizeForReadingData];
				CFIndex readBytesCount = CFReadStreamRead(readStream, 
														  (UInt8 *)buffer, 
														  (CFIndex)sizeof(buffer));
				if (readBytesCount == -1) break;
				if (readBytesCount == 0) {
					hasMoreData = false;
					continue;
				}
				CC_SHA1_Update(&hashObject, 
							   (const void *)buffer, 
							   (CC_LONG)readBytesCount);
			}
			
			// Check if the read operation succeeded
			didSucceed = !hasMoreData;
			
			// Compute the hash digest
			
			CC_SHA1_Final(digest, &hashObject);
		}
	}
    
    // Abort if the read operation failed
    if (didSucceed)
	{
		// Compute the string result
		char hash[2 * sizeof(digest) + 1];
		for (size_t i = 0; i < sizeof(digest); ++i) {
			snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
		}
		result = CFStringCreateWithCString(kCFAllocatorDefault, 
										   (const char *)hash, 
										   kCFStringEncodingUTF8);
	}
    
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}

#endif
