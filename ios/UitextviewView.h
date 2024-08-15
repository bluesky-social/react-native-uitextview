// This guard prevent this file to be compiled in the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef UitextviewViewNativeComponent_h
#define UitextviewViewNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface UitextviewView : RCTViewComponentView
@end

NS_ASSUME_NONNULL_END

#endif /* UitextviewViewNativeComponent_h */
#endif /* RCT_NEW_ARCH_ENABLED */
