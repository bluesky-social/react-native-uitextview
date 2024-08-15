package com.uitextview

import android.graphics.Color
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp

@ReactModule(name = UitextviewViewManager.NAME)
class UitextviewViewManager :
  UitextviewViewManagerSpec<UitextviewView>() {
  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): UitextviewView {
    return UitextviewView(context)
  }

  @ReactProp(name = "color")
  override fun setColor(view: UitextviewView?, color: String?) {
    view?.setBackgroundColor(Color.parseColor(color))
  }

  companion object {
    const val NAME = "UitextviewView"
  }
}
