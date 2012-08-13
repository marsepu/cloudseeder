//
//  KeyboardTextField.h
//  CloudSeeder
//
//  Created by David Shu on 6/17/11.
//  Copyright 2011 Retronyms. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CSKeyboardTextField;
@protocol CSKeyboardTextFieldDelegate <NSObject>
- (void)keyboardTextFieldWillDismiss:(CSKeyboardTextField *)kbTextField;
- (void)keyboardTextFieldDidFinishDismiss:(CSKeyboardTextField *)kbTextField;
@optional
- (BOOL)keyboardTextFieldShouldDismiss:(CSKeyboardTextField *)kbTextField;
@end

@interface CSKeyboardTextField : UIView <UITextFieldDelegate> {
	id <CSKeyboardTextFieldDelegate> mDelegate;
    NSDictionary *mUserInfo;
    BOOL mDidConfirmInput;
	
	// UI
    UITextField *mDummyTextField;
	IBOutlet UITextField *mTextField;
	UIButton *mDismissButton;
	UIView *mParentView;
}
@property (nonatomic, assign) id <CSKeyboardTextFieldDelegate> delegate;
@property (nonatomic, assign) UIView *parentView;
@property (nonatomic, readonly) UITextField *textField;
@property (nonatomic, retain) NSDictionary *userInfo;
@property (nonatomic, readonly) BOOL didConfirmInput;

+ (CSKeyboardTextField *)create;
- (IBAction)clearPressed;
- (void)showWithKeyboard;

@end
