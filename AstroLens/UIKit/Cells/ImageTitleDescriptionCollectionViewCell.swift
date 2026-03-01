import UIKit

class ImageTitleDescriptionCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var astroImageView: UIImageView!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var favouriteButton: FavouriteButton!
    
    public private(set) var isLoading: Bool = false
    
    private var hasSelectedCellAsFavourite: Bool = false
    
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
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .white
        dateLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontForContentSizeCategory = true
        addCornerRadiusWithShadow()
        restrictUserContentSizePreferenceToSpecifiedSizes()
        setHeightOfImageViewForSizeClasses()
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
            isLoading = true
            loadingIndicator.startAnimating()
            astroImageView.isHidden = true
            dateLabel.isHidden = true
            titleLabel.isHidden = true
            loadingView.isHidden = false
            favouriteButton.isHidden = true
        case .hasContent:
            isLoading = false
            loadingIndicator.stopAnimating()
            astroImageView.isHidden = false
            dateLabel.isHidden = false
            titleLabel.isHidden = false
            loadingView.isHidden = true
            favouriteButton.isHidden = false
        }
    }
    
    func configure(date: String, title: String, astroImage: UIImage, isFavourite: Bool?) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        self.astroImageView.image = astroImage
        self.dateLabel.text = date
        self.titleLabel.text = title
        if hasSelectedCellAsFavourite == false {
            hasSelectedCellAsFavourite = true
            guard let isFavourite = isFavourite, isFavourite else { return }
            flipLikedState()
        }
        setCellState(to: .hasContent)
    }
    
    func flipLikedState() {
        favouriteButton.flipLikedState()
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
        loadingView.layer.cornerRadius = 8
        dateLabel.layer.cornerRadius = 4
        titleLabel.layer.cornerRadius = 4
    }
}

// MARK: - Dynamic fonts
extension ImageTitleDescriptionCollectionViewCell {
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
extension ImageTitleDescriptionCollectionViewCell {
    func handleSizeClassChanges(using previousTraitCollection: UITraitCollection) {
        if traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass
            || traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass {
            setHeightOfImageViewForSizeClasses()
        }
    }
    
    func setHeightOfImageViewForSizeClasses() {
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            // Activate compact constraints
            // imageViewHeightConstraint.constant = 220
        } else {
            // Activate regular constraints
            // imageViewHeightConstraint.constant = 400
        }
    }
}
