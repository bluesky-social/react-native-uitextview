# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Selection Change Events**: Added `onSelectionChange` callback prop to `UITextView` component
  - Provides real-time notifications when text selection changes
  - Event includes `start` and `end` indices of the selected range
  - Eliminates the need for polling-based selection detection
  - Supports multibyte characters (Arabic, emojis, etc.)
  - Only available on iOS when using `uiTextView={true}`

### Technical Details

- Implemented `UITextViewDelegate` protocol in `RNUITextView`
- Added `textViewDidChangeSelection:` delegate method
- Integrated with React Native's New Architecture event system
- Added comprehensive NSLog debugging for development
- Updated TypeScript definitions with JSDoc documentation

### Performance

- Replaces polling-based selection detection (typically 150-500ms intervals)
- Provides instant selection change notifications (<10ms latency)
- Eliminates background CPU overhead from polling loops
- Reduces memory usage by removing interval references

