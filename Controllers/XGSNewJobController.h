//
//  XGSNewJobController.h
//  GridStuffer
//
//  Created by Charles Parnot on 5/13/05.
//  Copyright 2005 Charles Parnot. All rights reserved.
//




@interface XGSNewJobController : NSWindowController
{
	IBOutlet NSTextField *jobNameTextField;
	IBOutlet NSTextField *inputFileTextField;
	IBOutlet NSTextField *outputFolderTextField;
	IBOutlet NSPopUpButton *loadDemoPopUpButton;
	//IBOutlet NSButton *addButton;
	//IBOutlet NSButton *startButton;
}

- (IBAction)browse:(id)sender;
- (IBAction)openWithFinder:(id)sender;

- (IBAction)cancel:(id)sender;
- (IBAction)loadDemo:(id)sender;

- (IBAction)addMetaJob:(id)sender;
- (IBAction)addAndStartMetaJob:(id)sender;

//used for bindings to notify KVO of changes
- (IBAction)updateObservedKeys:(id)sender;


@end
