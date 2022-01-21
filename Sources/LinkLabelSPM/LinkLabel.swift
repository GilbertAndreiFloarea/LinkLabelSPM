//
//  LinkLabel.swift
//
//  Created by Gilbert Andrei Floarea on 21.01.2022.
//

import Foundation
import UIKit

public class LinkLabel: UILabel {

    public var customLinkAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.blue]

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    func setup() {
        isUserInteractionEnabled = true
    }

    // point inside will determine if the tap is inside a custom attributed string called customLink
    // and if it is, it will trigger the opening of the url
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {

        let attributeName = NSAttributedString.Key.customLink
        let returnValue = super.point(inside: point, with: event)

        let customTextContainer = NSTextContainer(size: bounds.size)
        customTextContainer.lineFragmentPadding = 0.0
        customTextContainer.lineBreakMode = lineBreakMode
        customTextContainer.maximumNumberOfLines = numberOfLines

        // Setup NSLayoutManager to prepare for the custom text container
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(customTextContainer)

        guard let attributedText = attributedText else {
            return false
        }

        // Setup NSTextStorage for the the layout manager
        let customTextStorage = NSTextStorage(attributedString: attributedText)
        customTextStorage.addAttribute(NSAttributedString.Key.font, value: font!, range: NSMakeRange(0, attributedText.length))
        customTextStorage.addLayoutManager(layoutManager)

        // detect the tapping point inside the text
        let locationOfTouchInLabel = point

        // take into consideration any offsets
        let textBounds = layoutManager.usedRect(for: customTextContainer)
        var textAlignmentOffset: CGFloat!
        switch textAlignment {
        case .left, .natural, .justified:
            textAlignmentOffset = 0.0
        case .center:
            textAlignmentOffset = 0.5
        case .right:
            textAlignmentOffset = 1.0
        @unknown default:
            fatalError()
        }

        let horizontalOffset = ((bounds.size.width - textBounds.size.width) * textAlignmentOffset) - textBounds.origin.x
        let verticalOffset = ((bounds.size.height - textBounds.size.height) * textAlignmentOffset) - textBounds.origin.y
        let touchLocationInTextContainer = CGPoint(x: locationOfTouchInLabel.x - horizontalOffset, y: locationOfTouchInLabel.y - verticalOffset)

        // determine tapped character
        let characterIndex = layoutManager.characterIndex(
            for: touchLocationInTextContainer,
            in: customTextContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        let attributeValue = self.attributedText?.attribute(attributeName, at: characterIndex, effectiveRange: nil)

        if let value = attributeValue {
            if let url = value as? URL {
                UIApplication.shared.open(url)
            }
        }

        return returnValue

    }

    public override var attributedText: NSAttributedString? {
        get {
            return super.attributedText
        }
        set {
            super.attributedText = {
                guard let newValue = newValue else {
                    return nil
                }
                // Add passed attributes to the new customLink NSAttributedStringKey
                let text = NSMutableAttributedString(attributedString: newValue)
                text.enumerateAttribute(
                    .customLink,
                    in: NSRange(location: 0, length: text.length),
                    options: .longestEffectiveRangeNotRequired) { (value, subrange, _) in
                        guard let value = value else {
                            return
                        }
                        assert(value is URL)
                        text.addAttributes(customLinkAttributes, range: subrange)
                    }
                return text
            }()
        }
    }
}

extension NSAttributedString.Key {
    public static let customLink = NSAttributedString.Key("customLink")
}


