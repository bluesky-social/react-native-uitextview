#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(RNUITextViewManager, RCTViewManager)
RCT_REMAP_SHADOW_PROPERTY(numberOfLines, numberOfLines, NSInteger)
RCT_REMAP_SHADOW_PROPERTY(allowsFontScaling, allowsFontScaling, BOOL)

RCT_EXPORT_VIEW_PROPERTY(numberOfLines, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(onTextLayout, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(ellipsizeMode, NSString)
RCT_EXPORT_VIEW_PROPERTY(selectable, BOOL)
RCT_EXPORT_VIEW_PROPERTY(autoSelect, BOOL)

@end

@interface RCT_EXTERN_MODULE(RNUITextViewChildManager, RCTViewManager)
RCT_REMAP_SHADOW_PROPERTY(text, text, NSString)
RCT_REMAP_SHADOW_PROPERTY(color, color, UIColor)
RCT_REMAP_SHADOW_PROPERTY(fontSize, fontSize, CGFloat)
RCT_REMAP_SHADOW_PROPERTY(fontStyle, fontStyle, NSString)
RCT_REMAP_SHADOW_PROPERTY(fontWeight, fontWeight, NSString)
RCT_REMAP_SHADOW_PROPERTY(fontFamily, fontFamily, NSString)
RCT_REMAP_SHADOW_PROPERTY(letterSpacing, letterSpacing, CGFloat)
RCT_REMAP_SHADOW_PROPERTY(lineHeight, lineHeight, CGFloat)
RCT_REMAP_SHADOW_PROPERTY(pointerEvents, pointerEvents, NSString)
RCT_REMAP_SHADOW_PROPERTY(textDecorationLine, textDecorationLine, RCTTextDecorationLineType)
RCT_REMAP_SHADOW_PROPERTY(textDecorationStyle, textDecorationStyle, NSString)
RCT_REMAP_SHADOW_PROPERTY(textDecorationColor, textDecorationColor, UIColor)
RCT_REMAP_SHADOW_PROPERTY(backgroundColor, backgroundColor, UIColor)

RCT_EXPORT_VIEW_PROPERTY(text, NSString)
RCT_EXPORT_VIEW_PROPERTY(onPress, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLongPress, RCTBubblingEventBlock)
@end
