/*
 * Name: OgreFindProgressSheet.h
 * Project: OgreKit
 *
 * Creation Date: Oct 01 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2020 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreTextFinder.h>
#import <OgreKit/OgreTextFindProgressDelegate.h>

@interface OgreTextFindProgressSheet : NSObject <OgreTextFindProgressDelegate>
{
    IBOutlet NSWindow				*progressWindow;        // Progress for sheet (経過表示用シート)
    IBOutlet NSTextField			*titleTextField;        // Title (タイトル)
    IBOutlet NSProgressIndicator	*progressBar;           // Bar (バー)
	IBOutlet NSTextField			*progressTextField;     // A string that represents the elapsed (経過を表す文字列)
    IBOutlet NSTextField			*donePerTotalTextField; // Processing item rate (処理項目率)
	IBOutlet NSButton				*button;                // Cancel / OK button (Cancel/OKボタン)
	
	BOOL	_shouldRelease;			// When the OK button is pressed whether the object to release (OKボタンが押されたらこのオブジェクトをreleaseするかどうか)
	
	NSWindow	*_parentWindow;		// Window to which to attach the sheet (シートを張るウィンドウ)
	NSString	*_title;			// Title (タイトル)
	
	/* Action when it is canceled (キャンセルされたときのaction) */
	SEL			_cancelSelector;
	id			_cancelTarget;
	id			_cancelArgument;	// does not retain in the case of == self (== selfの場合はretainしない)
	/* action when the sheet is closed (シートが閉じたときのaction) */
	SEL			_didEndSelector;
	id			_didEndTarget;
	id			_didEndArgument;	// does not retain in the case of == self (== selfの場合はretainしない)
    
    NSArray     *_progressSheetTopLevelObjects;
}

/* Initialization (初期化) */
- (instancetype)initWithWindow:(NSWindow *)parentWindow title:(NSString *)aTitle didEndSelector:(SEL)aSelector toTarget:(id)aTarget withObject:(id)anObject NS_DESIGNATED_INITIALIZER;

- (IBAction)cancel:(id)sender;

/* OgreTextFindProgressDelegate protocol */
/*
// show progress
- (void)setProgress:(double)progression message:(NSString *)message;
- (void)setDonePerTotalMessage:(NSString *)message;
// finish
- (void)done:(double)progression message:(NSString *)message;

// close sheet
- (void)close:(id)sender;
- (void)setReleaseWhenOKButtonClicked:(BOOL)shouldRelease;

// cancel
- (void)setCancelSelector:(SEL)aSelector toTarget:(id)aTarget withObject:(id)anObject;

// show error alert
- (void)showErrorAlert:(NSString *)title message:(NSString *)errorMessage;
*/

@end
