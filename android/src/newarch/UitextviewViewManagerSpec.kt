package com.uitextview

import android.view.View

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.UitextviewViewManagerDelegate
import com.facebook.react.viewmanagers.UitextviewViewManagerInterface

abstract class UitextviewViewManagerSpec<T : View> : SimpleViewManager<T>(), UitextviewViewManagerInterface<T> {
  private val mDelegate: ViewManagerDelegate<T>

  init {
    mDelegate = UitextviewViewManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<T>? {
    return mDelegate
  }
}
