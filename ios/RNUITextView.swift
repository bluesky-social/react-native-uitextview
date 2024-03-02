class RNUITextView: UIView, UIGestureRecognizerDelegate {
  let bridge: RCTBridge
  let textView: UITextView

  @objc var numberOfLines: Int = 0 {
    didSet {
      textView.textContainer.maximumNumberOfLines = numberOfLines
    }
  }
  @objc var selectable: Bool = true {
    didSet {
      textView.isSelectable = selectable
    }
  }
  @objc var ellipsizeMode: String = "tail" {
    didSet {
      textView.textContainer.lineBreakMode = self.getLineBreakMode()
    }
  }
  @objc var onTextLayout: RCTDirectEventBlock?

  init(bridge: RCTBridge) {
    self.bridge = bridge
    
    if #available(iOS 16.0, *) {
      textView = UITextView(usingTextLayoutManager: false)
    } else {
      textView = UITextView()
    }
    
    // Disable scrolling
    textView.isScrollEnabled = false
    // Remove all the padding
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
    
    // Remove other properties
    textView.isEditable = false
    textView.backgroundColor = .clear
    
    // Init
    super.init(frame: .zero)
    self.clipsToBounds = true
    
    // Add the view
    addSubview(textView)
        
    let longPressGestureRecognizer = UILongPressGestureRecognizer(
      target: self,
      action: #selector(callOnLongPress(_:))
    )
    longPressGestureRecognizer.delegate = self
    textView.addGestureRecognizer(longPressGestureRecognizer)
        
    let pressGestureRecognzier = UITapGestureRecognizer(
      target: self,
      action: #selector(callOnPress(_:))
    )
    pressGestureRecognzier.require(toFail: longPressGestureRecognizer)
    pressGestureRecognzier.delegate = self
    textView.addGestureRecognizer(pressGestureRecognzier)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // Resolves some animation issues
  override func reactSetFrame(_ frame: CGRect) {
    UIView.performWithoutAnimation {
      super.reactSetFrame(frame)
    }
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
  @IBAction func callOnPress(_ sender: UITapGestureRecognizer) -> Void {
    self.handlePressIfNecessary(sender)
  }
  
  @IBAction func callOnLongPress(_ sender: UILongPressGestureRecognizer) -> Void {
    if sender.state == .ended {
      self.handleLongPressIfNecessary(sender)
    }
  }

  func setText(string: NSAttributedString, size: CGSize, numberOfLines: Int) -> Void {
    self.textView.frame.size = size
    self.textView.textContainer.maximumNumberOfLines = numberOfLines
    self.textView.attributedText = string
    self.textView.selectedTextRange = nil

    if let onTextLayout = self.onTextLayout {
      var lines: [String] = []
      self.textView.layoutManager.enumerateLineFragments(
        forGlyphRange: NSRange(location: 0, length: self.textView.attributedText.length))
      { (rect, usedRect, textContainer, glyphRange, stop) in
        let characterRange = self.textView.layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        let line = (self.textView.text as NSString).substring(with: characterRange)
        lines.append(line)
      }

      onTextLayout([
        "lines": lines
      ])
    }
  }
  
  func getLocationOfPress(_ sender: UIGestureRecognizer) -> CGPoint {
    return sender.location(in: self.textView)
  }
  
  /*
   
   func handleTap(_ sender: UIGestureRecognizer) {
       guard let textView = sender.view as? UITextView else { return }

       guard let plaintext = textView.attributedText?.string else { return }
       //guard let plaintext = textView.text else { return }

       let location = sender.location(in: textView)
       let charIndex = textView.layoutManager.characterIndex(for: location, in: textView.textContainer,
                                                         fractionOfDistanceBetweenInsertionPoints: nil)

       if let strIndex = plaintext.utf16.index(plaintext.utf16.startIndex, offsetBy: charIndex, limitedBy: plaintext.utf16.endIndex) {
           let char = plaintext[strIndex]
           print("Character tapped was \(char)")
       }
   }
   
   */
  func getTouchChild(_ location: CGPoint) -> RNUITextViewChild? {
    let fullText = self.textView.attributedText.string
    
    // Get the index of the char
    let charIndex = self.textView.layoutManager.characterIndex(
      for: location,
      in: textView.textContainer,
      fractionOfDistanceBetweenInsertionPoints: nil
    )
    
    var currIndex = -1
    for child in self.reactSubviews() {
      guard let child = child as? RNUITextViewChild,
            let childText = child.text
      else {
        continue
      }
      
      // We need to account for grapheme length here, so use utf16.count
      currIndex += childText.utf16.count
      
      if charIndex <= currIndex {
        print(charIndex)
        print(currIndex)
        return child
      }
    }
    
    return nil
  }
  
  func handlePressIfNecessary(_ sender: UITapGestureRecognizer) -> Void {
    let location = getLocationOfPress(sender)
    guard let child = getTouchChild(location),
          let onPress = child.onPress
    else {
      return
    }
    onPress([:])
  }
  
  func handleLongPressIfNecessary(_ sender: UILongPressGestureRecognizer) -> Void {
    let location = getLocationOfPress(sender)
    guard let child = getTouchChild(location),
          let onLongPress = child.onLongPress
    else {
      return
    }
    onLongPress([:])
  }
  
  func getLineBreakMode() -> NSLineBreakMode {
    switch self.ellipsizeMode {
    case "head":
      return .byTruncatingHead
    case "middle":
      return .byTruncatingMiddle
    case "tail":
      return .byTruncatingTail
    case "clip":
      return .byClipping
    default:
      return .byTruncatingTail
    }
  }
}
