import UIKit

class ExpandedImageTitleDescriptionCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var astroImageView: UIImageView!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionText: UITextView!
    
    enum CellState {
        case loadingContent
        case hasContent
    }
    
    nonisolated override func awakeFromNib() {
        super.awakeFromNib()
        Task { @MainActor in
            awakeFromNibOnMainThread()
        }
    }
    
    private func awakeFromNibOnMainThread() {
        dateLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontForContentSizeCategory = true
        addCornerRadiusWithShadow()
        restrictUserContentSizePreferenceToSpecifiedSizes()
        hideDescriptionTextForSizeClasses()
    }
     
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let previousTraitCollection = previousTraitCollection else { return }
        handleContentSizeCategoryChanges(using: previousTraitCollection.preferredContentSizeCategory)
        handleSizeClassChanges(using: previousTraitCollection)
    }
    
    func setCellState(to cellState: CellState) {
        switch cellState {
        case .loadingContent:
            astroImageView.isHidden = true
            dateLabel.isHidden = true
            titleLabel.isHidden = true
            isUserInteractionEnabled = false
        case .hasContent:
            astroImageView.isHidden = false
            dateLabel.isHidden = false
            titleLabel.isHidden = false
            isUserInteractionEnabled = true
        }
    }
    
    func configure(date: String, title: String, description: String, astroImage: UIImage) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        self.astroImageView.image = astroImage
        self.dateLabel.text = date
        self.titleLabel.text = title
        self.descriptionText.text = description
        setCellState(to: .hasContent)
    }
    
    func addCornerRadiusWithShadow() {
        backgroundColor = .clear
        layer.masksToBounds = false
        layer.shadowOpacity = 0.23
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowColor = UIColor.black.cgColor
        
        contentView.layer.cornerRadius = 8
        astroImageView.layer.cornerRadius = 8
        dateLabel.layer.cornerRadius = 4
        titleLabel.layer.cornerRadius = 4
        descriptionText.layer.cornerRadius = 4
    }
}

// MARK: - Dynamic fonts
extension ExpandedImageTitleDescriptionCollectionViewCell {
    func handleContentSizeCategoryChanges(using previousPreferredContentSizeCategory: UIContentSizeCategory) {
        let currentPreferredContentSizeCategory = traitCollection.preferredContentSizeCategory
        if currentPreferredContentSizeCategory != previousPreferredContentSizeCategory {
            restrictUserContentSizePreferenceToSpecifiedSizes()
        }
    }
    
    func restrictUserContentSizePreferenceToSpecifiedSizes() {
        let currentPreferredContentSizeCategory = traitCollection.preferredContentSizeCategory
        
        // Specified content size categories
        let specifiedContentSizesCategoriesForSmall: [UIContentSizeCategory] = [.extraSmall, .small]
        let specifiedContentSizesCategoriesForMedium: [UIContentSizeCategory] = [.medium, .large, .accessibilityMedium, .accessibilityLarge]
        let specifiedContentSizesCategoriesForLarge: [UIContentSizeCategory] = [.extraLarge, .extraExtraLarge, .extraExtraExtraLarge, .accessibilityExtraLarge, .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge]
        
        // Font descriptors
        let fontDescriptorForDate = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body, compatibleWith: traitCollection)
        let fontDescriptorForTitle = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title1, compatibleWith: traitCollection)
        
        if specifiedContentSizesCategoriesForSmall.contains(currentPreferredContentSizeCategory) {
            dateLabel.font = UIFont(descriptor: fontDescriptorForDate, size: 12)
            titleLabel.font = UIFont(descriptor: fontDescriptorForTitle, size: 12)
        } else if specifiedContentSizesCategoriesForMedium.contains(currentPreferredContentSizeCategory) {
            dateLabel.font = UIFont(descriptor: fontDescriptorForDate, size: 15)
            titleLabel.font = UIFont(descriptor: fontDescriptorForTitle, size: 15)
        } else if specifiedContentSizesCategoriesForLarge.contains(currentPreferredContentSizeCategory) {
            dateLabel.font = UIFont(descriptor: fontDescriptorForDate, size: 22)
            titleLabel.font = UIFont(descriptor: fontDescriptorForTitle, size: 22)
        }
    }
}

// MARK: - Size classes
extension ExpandedImageTitleDescriptionCollectionViewCell {
    func handleSizeClassChanges(using previousTraitCollection: UITraitCollection) {
        if traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass
            || traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass {
            hideDescriptionTextForSizeClasses()
        }
    }
    
    func hideDescriptionTextForSizeClasses() {
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            // Activate compact constraints
            descriptionText.isHidden = false
        } else {
            // Activate regular constraints
            descriptionText.isHidden = true
        }
    }
}
