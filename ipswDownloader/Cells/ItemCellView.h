//
//  ItemCellView.h
//  ipswDownloader
//
//  Created by Vitaly Parovishnik on 12/29/11.
//  Copyright 2011 IGR Software. All rights reserved.
//

@interface ItemCellView : NSTableCellView {
	NSTextField *_detailTextField;
	
	NSButton	*_detailPauseResumeButton;
	NSButton	*_detailShowInFinderButton;
}

@property (nonatomic, strong) IBOutlet NSTextField *detailTextField;
@property (nonatomic, strong) IBOutlet NSButton	*detailPauseResumeButton;
@property (nonatomic, strong) IBOutlet NSButton	*detailShowInFinderButton;

@end
