//
//  BuildOnSavePlugin.h
//  BuildOnSave
//
//  Created by Eric Fernance on 28/10/12.
//	License: GPL please see license.txt
//

#import <Cocoa/Cocoa.h>
#import "CodaPluginsController.h"

@class CodaPlugInsController;

@interface BuildOnSavePlugIn : NSObject <CodaPlugIn>
{
	CodaPlugInsController	*controller;
	
	IBOutlet NSWindow *buildOnSaveDialog;
	IBOutlet NSPanel *buildOnSaveStatus;
	
	IBOutlet NSTextField *statusTextView;
	IBOutlet NSButton *enableCheckBox;
	IBOutlet NSTextField *nicknameTextView;
}

@property (nonatomic,retain) NSString *antPath;


/* required coda plugin methods */

//for Coda 2.0.1 and higher
- (id)initWithPlugInController:(CodaPlugInsController *)aController plugInBundle:(NSObject <CodaPlugInBundle> *)plugInBundle;

//for Coda 2.0 and lower
- (id)initWithPlugInController:(CodaPlugInsController*)aController bundle:(NSBundle*)yourBundle;

- (NSString*)name;

- (BOOL)doBuildForNickname:(NSString*)nickname;

/* actions */
- (IBAction)cancelAction:(id)sender;
-(IBAction)saveAction:(id)sender;

/* optional coda plugin methods */
- (void)textViewWillSave:(CodaTextView*)textView;

@end

