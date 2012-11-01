//
//  BuildOnSavePlugin.m
//  BuildOnSave
//
//  Created by Eric Fernance on 28/10/12.
//	License: GPL please see license.txt
//

#import "BuildOnSavePlugIn.h"
#import "CodaPlugInsController.h"

@interface BuildOnSavePlugIn ()

- (id)initWithController:(CodaPlugInsController*)aController;
- (void)loadInterface;

@end

@implementation BuildOnSavePlugIn


@synthesize antPath;

#pragma mark Required Coda Plugin Methods


// Support for Coda 2.0 and lower

- (id)initWithPlugInController:(CodaPlugInsController*)aController bundle:(NSBundle*)yourBundle
{
    return [self initWithController:aController];
}

// Support for Coda 2.0.1 and higher
// NOTE: must set the CodaPlugInSupportedAPIVersion key to 6 or above to use this init method

- (id)initWithPlugInController:(CodaPlugInsController*)aController plugInBundle:(NSObject <CodaPlugInBundle> *)plugInBundle
{
	NSLog(@"initWithPlugInController");
	return [self initWithController:aController];
}


- (id)initWithController:(CodaPlugInsController*)aController
{
	NSLog(@"initWithController");
    if ( (self = [super init]) != nil )
    {
        //store controller pointer
        controller = aController;
		
        //add menu item in Coda
        [controller registerActionWithTitle:NSLocalizedString(@"Build On Save", @"") target:self selector:@selector(showDialog)];
    }
	
	//does the ds exist?
	NSString *dataFile = [@"~/Library/Application Support/com.purplebeanie.buildonsave/settings.xml" stringByExpandingTildeInPath];
	NSString *sitesFile = [@"~/Library/Application Support/com.purplebeanie.buildonsave/sites.xml" stringByExpandingTildeInPath];
	NSString *dataDir=[@"~/Library/Application Support/com.purplebeanie.buildonsave" stringByExpandingTildeInPath];
	NSLog(@"BuildOnSave: checking config file exists at %@",dataFile);
	NSFileManager *fs = [[NSFileManager alloc]init];
	if (![fs fileExistsAtPath:dataFile]) {
		NSLog(@"BuildOnSave: creating data file");
		//no data file... need to create.
		NSBundle *bosBundle = [NSBundle bundleForClass:[self class]];
		NSLog(@"BuildOnSave: settings.xml path = %@",[bosBundle pathForResource:@"settings" ofType:@"xml"]);
		
		NSError *error = nil;
		//assume the dir doesn't exist and create.  will just leave in place if it does exist....
		[fs createDirectoryAtPath:dataDir withIntermediateDirectories:NO attributes:nil error:NULL];
		[fs copyItemAtPath:[bosBundle pathForResource:@"settings" ofType:@"xml"] toPath:dataFile error:&error];
		[fs copyItemAtPath:[bosBundle pathForResource:@"sites" ofType:@"xml"] toPath:sitesFile error: NULL];
		if (error)
			NSLog(@"%@",error);
	} else {
		//setings file exists.....
		NSError *error = nil;
		NSXMLDocument *configData = [[NSXMLDocument alloc]initWithData:[NSData dataWithContentsOfFile:dataFile] options:NSXMLDocumentTidyXML error:&error];
		if (error) {
			NSLog(@"%@",error);
		} else {
			//got a valid config file I guess.... let's read out the path to ant!
			NSString *antLocation = [[[configData nodesForXPath:@"/configuration/ant/location" error:NULL]objectAtIndex:0]stringValue];
			NSLog(@"BuildOnSave: config for ant location is %@",antLocation);
			[self setAntPath:antLocation];
		}
		[configData release];
		[error release];
	}
	
	[fs release];
	
    return self;
}


- (NSString*)name
{
	return @"Build On Save";
}

- (void)loadInterface
{
    [NSBundle loadNibNamed:@"BuildOnSaveDialog" owner:self];
	
}

#pragma mark Show and Close Sheet

- (void)showDialog
{	
	NSLog(@"BuildOnSave: showDialog:");
	
	if ( buildOnSaveDialog == nil )
    {
        //lazy load nib to avoid making Coda slow to launch
        [self loadInterface];
    }
    
    CodaTextView	*textView = [controller focusedTextView:self];
	NSWindow		*window = [textView window];
	
	//set the controls (or rather control) up...
	[nicknameTextView setStringValue:[textView siteNickname]];
	NSLog(@"BuildOnSave: site nickname is %@",[textView siteNickname]);
	if ([self doBuildForNickname:[textView siteNickname]]) {
		NSLog(@"BuildOnSave: site %@ is in sites.xml",[textView siteNickname]);
		[enableCheckBox setIntValue:1];
	} else {
		[enableCheckBox setIntValue:0];
	}
	
		
	if ( window && ![window attachedSheet] )
		[NSApp beginSheet:buildOnSaveDialog modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];	
	else
		NSBeep();

}


- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	
	[sheet close];
	
	if (returnCode == NSOKButton) {
		NSLog(@"BuildOnSave: process dialog");
		
		//so I need to change something.... open the file
		NSString *dataFile = [@"~/Library/Application Support/com.purplebeanie.buildonsave/sites.xml" stringByExpandingTildeInPath];
		NSError *error = nil;
		NSXMLDocument *configData = [[NSXMLDocument alloc]initWithData:[NSData dataWithContentsOfFile:dataFile] options:NSXMLDocumentTidyXML error:&error];
		if (error)
			NSLog(@"BuildOnSave: enountered error %@ when opening sites.xml for read / write",error);
		
		CodaTextView *textView = [controller focusedTextView:self];
		if ([enableCheckBox intValue]==0) {
			//remove the current project from the sites.xml file
			NSLog(@"BuildOnSave: delete %@ from sites.xml",[textView siteNickname]);
			for (NSXMLNode *site in [configData nodesForXPath:@"/sites/site" error:NULL]) {
				if ([[[[site children] objectAtIndex:0]stringValue]compare:[textView siteNickname]] == NSOrderedSame) {
					NSLog(@"BuildOnSave: deleting %@ from sites.xml found match.",[textView siteNickname]);
					[site detach];
				}
			}
		} else if (![self doBuildForNickname:[textView siteNickname]]) {
			//add the current project to the sites.xml file it doesn't already exist....

			NSXMLNode *site = [NSXMLNode elementWithName:@"site" children:
							   [NSArray arrayWithObject:[NSXMLNode elementWithName:@"nickname" stringValue:[textView siteNickname]]] 
											  attributes:nil];
			[[configData rootElement] addChild:site];
		}
		
		//write back to the sites.xml and release
		NSData *xmlDoc = [configData XMLData];
		error = nil;
		[xmlDoc writeToFile:dataFile options:NSDataWritingAtomic error:&error];
		if (error)
			NSLog(@"BuildOnSave: returner error on write %@");
		[configData release];
	}
}


#pragma mark Actions

- (IBAction)cancelAction:(id)sender
{
	[NSApp endSheet:buildOnSaveDialog returnCode:NSCancelButton];

}

- (IBAction)saveAction:(id)sender
{
	[NSApp endSheet:buildOnSaveDialog returnCode:NSOKButton];

}





#pragma mark Menu Validation

- (BOOL)validateMenuItem:(NSMenuItem*)aMenuItem
{
	BOOL	result = YES;
	SEL		action = [aMenuItem action];
	
	if ( action == @selector(showDialog) )
	{
		//CodaTextView	*textView = [controller focusedTextView:self];
		
	}
	
	return result;
}

#pragma mark Optional Methods

- (void)textViewWillSave:(CodaTextView*)textView {
	NSLog(@"BuildOnSave: textViewWillSave:");
	NSLog(@"BuildOnSave: siteNickname = %@",[textView siteNickname]);
	
	//is site included in the sites.xml list?
	NSFileManager *fs = [[NSFileManager alloc]init];
	if ([fs fileExistsAtPath:[@"~/Library/Application Support/com.purplebeanie.buildonsave/sites.xml" stringByExpandingTildeInPath]]) {
		//we have a sites.xml so process....
		if ([self doBuildForNickname:[textView siteNickname]]) {
			if (buildOnSaveStatus == nil)
				[NSBundle loadNibNamed:@"BuildOnSaveStatus" owner:self];
			
			CodaTextView	*ctextView = [controller focusedTextView:self];
			NSWindow		*window = [ctextView window];
			
			[window addChildWindow:buildOnSaveStatus ordered:NSWindowAbove];
			[statusTextView setStringValue:@""];
			[statusTextView setStringValue:@"BuildOnSave:\nLooking for build.xml"]; 
			
			NSString *workingDir = [[NSString alloc] initWithString:[ctextView siteLocalPath]];
			
			NSTask *ant = [[NSTask alloc]init];
			NSPipe *pipe = [NSPipe pipe];
			NSFileHandle *handle = [pipe fileHandleForReading];
			NSData *data = nil;
			
			[ant setStandardOutput:pipe];
			[ant setLaunchPath:[self antPath]];
			[ant setCurrentDirectoryPath:workingDir];
			//[ant setArguments:[NSArray arrayWithObject:@"mynewtarget"]];
			[ant launch];
			
			//read the data from the task
			while ((data = [handle availableData]) && [data length]){
				NSString *string = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
				//NSLog(@"pipe said %@",string);
				[statusTextView setStringValue:[NSString stringWithFormat:@"%@\n%@",[statusTextView stringValue],string]];
				[string release];
			}
			
			[ant release];
			[workingDir release];
			
			//now remove the window
			[window removeChildWindow:buildOnSaveStatus];
		} else {
			NSLog(@"BuildOnSave: Site not in sites.xml");
		}
	} else {
		NSLog(@"BuildOnSave: No sites.xml found");
	}
	[fs release];
	
}

- (BOOL)doBuildForNickname:(NSString*)nickname
{
	NSLog(@"BuildOnSave: checking if nickname is in sites.xml");
	
	NSString *dataFile = [@"~/Library/Application Support/com.purplebeanie.buildonsave/sites.xml" stringByExpandingTildeInPath];
	NSError *error = nil;
	NSXMLDocument *configData = [[NSXMLDocument alloc]initWithData:[NSData dataWithContentsOfFile:dataFile] options:NSXMLDocumentTidyXML error:&error];
	if (error) {
		NSLog(@"%@",error);
	} else {
		//got a valid sites file.  Let's read out the sites....
		NSArray *siteList = [configData nodesForXPath:@"/sites/site/nickname" error:NULL];
		NSLog(@"BuildOnSave: siteList is %@",siteList);
		for (NSXMLNode *site in siteList) {
			NSLog(@"BuildOnSave: site nickname from sites.xml = %@",[site stringValue]);
			if ([[site stringValue] caseInsensitiveCompare:nickname] == NSOrderedSame)
				return TRUE;
		}
	}
	
	[configData release];
	return FALSE;
}


#pragma mark Clean-up

- (void)dealloc
{
	[buildOnSaveDialog release];
	[buildOnSaveStatus release];
	
	[super dealloc];
}


@end
