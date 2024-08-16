// This guard prevent this file to be compiled in the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
#import <React/RCTViewComponentView.h>
#import <React/RCTComponent.h>
#import <UIKit/UIKit.h>

#ifndef RNUITextViewChildNativeComponent_h
#define RNUITextViewChildNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface RNUITextViewChild : RCTViewComponentView

@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, copy, nullable) RCTBubblingEventBlock onPress;
@property (nonatomic, copy, nullable) RCTBubblingEventBlock onLongPress;

@end

NS_ASSUME_NONNULL_END

#endif /* UitextviewViewNativeComponent_h */
#endif /* RCT_NEW_ARCH_ENABLED */
