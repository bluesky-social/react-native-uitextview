#import <React/RCTViewComponentView.h>
#import <React/RCTComponent.h>
#import <UIKit/UIKit.h>

#ifndef RNUITextViewChildNativeComponent_h
#define RNUITextViewChildNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface RNUITextViewChild : RCTViewComponentView

@property (nonatomic, copy, nullable) NSString *text;

- (void)onPress;
- (void)onLongPress;

@end

NS_ASSUME_NONNULL_END

#endif /* RNUITextViewChildNativeComponent_h */
