import Foundation
import UIKit
import NASAApi
import DataStore

final class PhotoOfTheDayCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    private let kCellIdentifier = "ImageTitleDescriptionCollectionViewCell"
    private let landingScreenViewModel = LandingScreenViewModel(service: NASAServiceImplementation())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewController()
        addGradientViewOnBackground()
        addDoubleTapGesture()
    }
    
    private func setupViewController() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "ImageTitleDescriptionCollectionViewCell", bundle: bundle)
        collectionView.register(nib, forCellWithReuseIdentifier: kCellIdentifier)
        collectionView.isPrefetchingEnabled = true
        collectionView?.prefetchDataSource = self
    }
    
    private func addGradientViewOnBackground() {
        let pastelView = PastelView(frame: view.bounds)
        pastelView.startPastelPoint = .bottomLeft
        pastelView.endPastelPoint = .topRight
        pastelView.animationDuration = 2.0
        pastelView.setColors([UIColor.spaceBlack,
                              UIColor.darkGray,
                              UIColor.black,
                              UIColor.shipsOfficer])
        pastelView.startAnimation()
        
        collectionView.backgroundView = pastelView
    }
    
    private func addDoubleTapGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapAction))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.numberOfTouchesRequired = 1
        doubleTapGesture.delaysTouchesBegan = true
        doubleTapGesture.cancelsTouchesInView = true
        view.addGestureRecognizer(doubleTapGesture)
    }
    
    @objc private func doubleTapAction(sender: UITapGestureRecognizer) async {
        let doubleTapPoint = sender.location(in: collectionView)
        guard let selectedIndexPath = collectionView.indexPathForItem(at: doubleTapPoint), let cell = collectionView.cellForItem(at: selectedIndexPath) as? ImageTitleDescriptionCollectionViewCell, cell.isLoading == false else {
            return
        }
        guard await landingScreenViewModel.savedPhotos.indices.contains(selectedIndexPath.section) else {
            print("Saved photos does not contain selectedIndexPath: \((selectedIndexPath.section))")
            return
        }
        let photoContent = await landingScreenViewModel.savedPhotos[selectedIndexPath.section]
        guard let _ = DataStoreImplementation.shared.retrieveObject(forKey: photoContent.date) else {
            DataStoreImplementation.shared.storeObject(forKey: photoContent.date, value: photoContent.date)
            cell.flipLikedState()
            return
        }
        DataStoreImplementation.shared.removeObject(forKey: photoContent.date)
        cell.flipLikedState()
    }
    
    // MARK: - CollectionView delegate methods
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellIdentifier, for: indexPath) as? ImageTitleDescriptionCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.setCellState(to: .loadingContent)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let radius = cell.contentView.layer.cornerRadius
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: radius).cgPath
        cell.contentView.layer.masksToBounds = true
        
        guard let cell = cell as? ImageTitleDescriptionCollectionViewCell else { return }
        
        Task { @MainActor in
            let response = await landingScreenViewModel.fetchPhotoOfTheDay(at: indexPath)
            await handleCellConfiguration(response: response,
                                          image: response.image,
                                          cell: cell,
                                          indexPath: indexPath)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Do something here
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .top)
        Task { await showShareSheetForPhoto(at: indexPath) }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return sizeForItem()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return landingScreenViewModel.numberOfPhotosToRetrieve
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func sizeForItem() -> CGSize {
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            // Activate compact constraints
            return CGSize(width: view.frame.width, height: 220)
        } else {
            // Activate regular constraints
            return CGSize(width: view.frame.width, height: 400)
        }
    }
    
    // MARK: - Cell configuration methods
    private func handleCellConfiguration(response: PhotoOfTheDay, image: UIImage?, cell: ImageTitleDescriptionCollectionViewCell, indexPath: IndexPath) async {
        let isFavourite = await landingScreenViewModel.previousDates[indexPath.section] == DataStoreImplementation.shared.retrieveObject(forKey: response.date)
        animateCellConfiguration(cell: cell, date: response.date, title: response.title, image: image ?? landingScreenViewModel.defaultImage, isFavourite: isFavourite)
    }
    
    private func animateCellConfiguration(cell: ImageTitleDescriptionCollectionViewCell, date: String, title: String, image: UIImage, isFavourite: Bool = false) {
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .allowAnimatedContent, animations: {
            cell.setCellState(to: .hasContent)
            cell.configure(date: date, title: title, astroImage: image, isFavourite: isFavourite)
            cell.setNeedsLayout()
            cell.setNeedsDisplay()
        }, completion: nil)
    }
}

// MARK: - Collection view prefetching
extension PhotoOfTheDayCollectionViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        Task { await landingScreenViewModel.fetchAllPhotos(indexPaths: indexPaths) }
    }
}

// MARK: - Share sheet configuration
extension PhotoOfTheDayCollectionViewController {
    func showShareSheetForPhoto(at indexPath: IndexPath) async {
        guard await landingScreenViewModel.savedPhotos.indices.contains(indexPath.section) else {
            print("Saved photos does not contain selectedIndexPath: \((indexPath.section))")
            return
        }
        guard let photoAtIndex = await landingScreenViewModel.savedPhotos[indexPath.section].image else { return }
        let activityViewController = UIActivityViewController(activityItems: [photoAtIndex], applicationActivities: nil)
        present(activityViewController, animated: true)
    }
}

/*
 // MARK: - Network operations
 func handleNetworkOperation(forCell cell: ImageTitleDescriptionCollectionViewCell, atIndexPath indexPath: IndexPath) {
     let updateCellClosure: (PhotoOfTheDay?) -> Void = { [weak self] response in
         DispatchQueue.main.async { [weak self] in
             guard let self = self, let response = response else { return }
             self.handleCellConfiguration(response: response, image: response.image, cell: cell, indexPath: indexPath)
             self.landingScreenViewModel.loadingOperations.removeValue(forKey: indexPath)
         }
     }
     
     if let existingDataLoader = landingScreenViewModel.loadingOperations[indexPath] {
         if let response = existingDataLoader.response {
             DispatchQueue.main.async { [weak self] in
                 guard let self = self else { return }
                 self.handleCellConfiguration(response: response, image: response.image, cell: cell, indexPath: indexPath)
                 self.landingScreenViewModel.loadingOperations.removeValue(forKey: indexPath)
             }
         } else {
             // No response yet. Updating the completion handler fixes cell waiting to load issue
             existingDataLoader.updateCompletionHandler(with: updateCellClosure)
         }
     } else {
         let dataLoader = landingScreenViewModel.makeDataLoadOperation(atIndex: indexPath.section) { [weak self] response in
             DispatchQueue.main.async { [weak self] in
                 guard let self = self else { return }
                 self.handleCellConfiguration(response: response, image: response.image, cell: cell, indexPath: indexPath)
                 self.landingScreenViewModel.loadingOperations.removeValue(forKey: indexPath)
             }
         }
         landingScreenViewModel.loadingQueue.addOperation(dataLoader)
         landingScreenViewModel.loadingOperations[indexPath] = dataLoader
     }
 }
 */
