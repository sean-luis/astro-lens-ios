//
//  PastelLabel.swift
//  Pastel
//
//  Created by Cruz on 21/05/2017.
//
//

import UIKit

public protocol PastelLabelable {
    var text: String? { get set }
    var font: UIFont? { get set }
    var textAlignment: NSTextAlignment { get set }
    var attributedText: NSAttributedString? { get set }
}

open class PastelLabel: PastelView, PastelLabelable {
    private let label = UILabel()
    
    //MARK: - PastelLabelable

    open var text: String? {
        didSet {
            label.text = text
        }
    }
    
    open var font: UIFont? {
        didSet {
            label.font = font
        }
    }
    
    open var attributedText: NSAttributedString? {
        didSet {
            label.attributedText = attributedText
        }
    }
    
    open var textAlignment: NSTextAlignment = .center {
        didSet {
            label.textAlignment = textAlignment
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    nonisolated open override func awakeFromNib() {
        // Code here is nonisolated
        super.awakeFromNib()
        Task { @MainActor in
            // Code here runs on the main actor
            setup()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }
    
    private func setup() {
        textAlignment = .center
        mask = label
    }
}

/*
 
 The error "'Main actor-isolated instance method 'awakeFromNib()' has different actor isolation from nonisolated overridden declaration'" occurs in Swift when you try to override the awakeFromNib() method with MainActor isolation in a class where the default setting or superclass declaration is nonisolated.

 Explanation
 
 awakeFromNib() source: The awakeFromNib() method is defined in Objective-C on NSObject. NSObject is not associated with any specific actor (it is nonisolated), meaning this method can potentially be called from any thread.
 Main Actor Isolation: In newer Swift versions (especially with Swift 6 and the "Default Actor Isolation" setting enabled for app targets), your class and its methods might implicitly default to being isolated to the @MainActor to ensure UI safety.
 The Conflict: The compiler flags an error because you are trying to override a nonisolated (can run on any thread) method with a MainActor-isolated (must run on the main thread) method. This violates the rules of method overriding, as an overridden method cannot have a different actor isolation than the original declaration.

 Resolution
 
 To resolve this, you need to ensure the overridden method has the same nonisolated status as the original declaration, and any Main Actor work within it is handled correctly.
 
 Here are the (3) primary ways to fix this:
 
 (1) Mark the overridden awakeFromNib() as nonisolated:
 Declare the method as nonisolated and then switch to the MainActor context inside the function if needed for UI-related tasks or accessing main-actor-isolated state.

 nonisolated override func awakeFromNib() {
     super.awakeFromNib()
     // Code here is nonisolated
     Task { @MainActor in
         // Code here runs on the main actor
         // Update UI elements, access @MainActor properties, etc.
     }
 }
 
 The first option is generally more robust for strict concurrency checking.
 
 (2) Explicitly declare a Main Actor helper method (Alternative):
 A common pattern is to keep the override nonisolated and use a separate, main-actor-isolated helper method for the main-thread-specific logic.
 swift
 
 override func awakeFromNib() {
     super.awakeFromNib()
     self.awakeFromNibOnMainThread()
 }

 @MainActor
 private func awakeFromNibOnMainThread() {
     // All UI setup code goes here
 }
 
 Note that this second option involves a synchronous call to an async context, which works when you know you are on the main thread but may be less clear to the compiler in certain Swift 6 configurations. The first option is generally more robust for strict concurrency checking.
 
 (3) Adjust Build Settings (Less recommended for targeted fix): You could change the "Default Actor Isolation" build setting in Xcode back to "nonisolated" for your target to match older Swift behavior, but this will disable main actor isolation by default for all your code, potentially introducing other data race issues. The first two solutions are better for adopting the new concurrency model safely.
 
 */
