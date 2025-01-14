//
//  PageOverviewCollectionViewController.swift
//  F1TV
//
//  Created by Noah Fetz on 24.10.20.
//

import UIKit

class PageOverviewCollectionViewController: BaseCollectionViewController, UICollectionViewDelegateFlowLayout, ContentPageLoadedProtocol, ContentVideoLoadedProtocol {
    var contentSections: [ContentSection]?
    
    var pageUri: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCollectionView()
    }
    
    func setupCollectionView() {
    }
    
    func initialize(pageUri: String) {
        self.pageUri = pageUri
    }
    
    func initialize(contentSections: [ContentSection]) {
        self.contentSections = contentSections
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let pageUri = self.pageUri {
            DataManager.instance.loadContentPage(pageUri: pageUri, contentPageProtocol: self)
        }
    }
    
    func didLoadContentPage(contentPage: ResultObjectDto) {
        var localSections = [ContentSection]()
        for contentContainer in contentPage.containers ?? [ContainerDto]() {
            //Some sub pages don't have sections, so we put them all into one big section
            if(ContainerLayoutType.fromIdentifier(identifier: contentContainer.layout ?? "") == .ContentItem) {
                if(localSections.isEmpty){
                    var section = ContentSection()
                    section.layoutType = ContainerLayoutType.fromIdentifier(identifier: contentContainer.layout ?? "")
                    section.container = contentContainer
                    localSections.append(section)
                }
                
                if var firstSection = localSections.first {
                    localSections.remove(at: 0)
                    firstSection.items.append(self.getContentItem(itemContainer: contentContainer))
                    localSections.insert(firstSection, at: 0)
                }
                
                continue
            }
            
            localSections.append(self.getContentSection(contentContainer: contentContainer))
        }
        
        self.contentSections = localSections
        self.collectionView.reloadData()
    }
    
    func getContentSection(contentContainer: ContainerDto) -> ContentSection {
        switch ContainerLayoutType.fromIdentifier(identifier: contentContainer.layout ?? "") {
        case .Hero:
            var heroSection = ContentSection()
            
            heroSection.layoutType = ContainerLayoutType.fromIdentifier(identifier: contentContainer.layout ?? "")
            heroSection.container = contentContainer
            heroSection.title = NSLocalizedString("featured_title", comment: "")
            
            for itemContainer in contentContainer.retrieveItems?.resultObj.containers ?? [ContainerDto]() {
                heroSection.items.append(self.getContentItem(itemContainer: itemContainer))
            }
            
            return heroSection
            
        case .HorizontalThumbnail, .VerticalThumbnail:
            var thumbnailSection = ContentSection()
            
            thumbnailSection.layoutType = ContainerLayoutType.fromIdentifier(identifier: contentContainer.layout ?? "")
            thumbnailSection.container = contentContainer
            thumbnailSection.title = contentContainer.metadata?.label ?? ""
            
            for itemContainer in contentContainer.retrieveItems?.resultObj.containers ?? [ContainerDto]() {
                thumbnailSection.items.append(self.getContentItem(itemContainer: itemContainer))
            }
            
            return thumbnailSection
            
        case .Title:
            if let title = contentContainer.metadata?.label {
                if(!title.isEmpty){
                    var titleSection = ContentSection()
                    
                    titleSection.layoutType = ContainerLayoutType.fromIdentifier(identifier: contentContainer.layout ?? "")
                    titleSection.container = contentContainer
                    titleSection.title = contentContainer.metadata?.label ?? ""
                    
                    return titleSection
                }
            }
            
            return ContentSection()
            
        default:
            print("Not recognizing this layout")
            return ContentSection()
        }
    }
    
    func getContentItem(itemContainer: ContainerDto) -> ContentItem {
        return ContentItem(objectType: ContentObjectType.fromIdentifier(identifier: itemContainer.metadata?.contentType ?? ContentObjectType().getIdentifier()), container: itemContainer)
        /*switch ContentObjectType.fromIdentifier(identifier: itemContainer.metadata.contentType ?? ContentObjectType().getIdentifier()) {
        case .Video:
            var videoContentItem = ContentItem()
            
            videoContentItem.objectType = ContentObjectType.fromIdentifier(identifier: itemContainer.metadata.contentType ?? ContentObjectType().getIdentifier())
            videoContentItem.container = itemContainer
            
            return videoContentItem
            
        case .Bundle:
            var bundleContentItem = ContentItem()
            
            
            
        case .Unknown, .Launcher:
            print("Not recognizing this object type")
            return ContentItem()
        }*/
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.contentSections?.count ?? 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.contentSections?[section].items.count ?? 3
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ConstantsUtil.thumbnailTitleSubtitleCollectionViewCell, for: indexPath) as! ThumbnailTitleSubtitleCollectionViewCell
       
        cell.setDefaultConfig()
        cell.disableSkeleton()
        
        if(self.contentSections == nil) {
            cell.configureSkeleton()
        }else{
            let currentItem = self.contentSections?[indexPath.section].items[indexPath.row] ?? ContentItem()
            
            switch currentItem.objectType {
            case .Video:
                cell.titleLabel.text = currentItem.container.metadata?.title
                cell.titleLabel.font = UIFont(name: "Formula1-Display-Bold", size: 20)
                
                if(currentItem.container.metadata?.emfAttributes?.videoType != "meetingSession" && !(currentItem.container.metadata?.additionalStreams?.isEmpty ?? true)){
                    if let additionalStream = currentItem.container.metadata?.additionalStreams?.first {
                        if(additionalStream.type == "obc") {
                            cell.thumbnailImageView.backgroundColor = UIColor(rgb: additionalStream.hex ?? "#00000000")
                            cell.subtitleLabel.text = String(additionalStream.racingNumber) + " | " + additionalStream.title
                            cell.accessoryFooterLabel.text = additionalStream.teamName
                            cell.accessoryFooterLabel.textColor = UIColor(rgb: additionalStream.hex ?? "#00000000")
                        }else{
                            cell.thumbnailImageView.image = UIImage(named: "thumb_placeholder")
                        }
                    }
                }else{
                    var subtitleString = currentItem.container.metadata?.uiDuration
                    subtitleString?.append(" | ")
                    subtitleString?.append(currentItem.container.metadata?.contentSubtype ?? "")
                    cell.subtitleLabel.text = subtitleString
                    cell.subtitleLabel.font = UIFont(name: "Titillium-Regular", size: 20)
                    
                    cell.accessoryFooterLabel.text = ""
                    if let property = currentItem.container.properties?.first {
                        let series = SeriesType.fromCapitalDisplayName(capitalDisplayName: property.series)
                        cell.accessoryFooterLabel.text = series.getCapitalDisplayName()
                        cell.accessoryFooterLabel.textColor = series.getColor()
                    }
                    
                    if((currentItem.container.metadata?.pictureUrl?.isEmpty) ?? true) {
                        cell.thumbnailImageView.image = UIImage(named: "thumb_placeholder")
                    }else{
                        cell.applyImage(pictureId: currentItem.container.metadata?.pictureUrl ?? "", imageView: cell.thumbnailImageView)
                    }
                }
                
            case .Bundle:
                cell.titleLabel.text = currentItem.container.metadata?.title
                
                //Load flags and stuff if bundle seems to be a race session in a country
                if((currentItem.container.metadata?.emfAttributes?.meetingCountryKey?.isEmpty) ?? true) {
                    cell.subtitleLabel.text = currentItem.container.metadata?.emfAttributes?.globalMeetingName?.uppercased()
                }else{
                    cell.subtitleLabel.text = currentItem.container.metadata?.emfAttributes?.meetingCountryName?.uppercased()
                    cell.applyImage(countryId: currentItem.container.metadata?.emfAttributes?.meetingCountryKey ?? "", imageView: cell.accessoryOverlayImageView)
                    cell.footerLabel.text = currentItem.container.metadata?.emfAttributes?.meetingDisplayDate ?? ""
                }
                
                if((currentItem.container.metadata?.pictureUrl?.isEmpty) ?? true) {
                    cell.thumbnailImageView.image = UIImage(named: "thumb_placeholder")
                }else{
                    cell.applyImage(pictureId: currentItem.container.metadata?.pictureUrl ?? "", imageView: cell.thumbnailImageView)
                }
                
            case .Launcher:
                cell.titleLabel.font = UIFont(name: "Titillium-Bold", size: 32)
                cell.titleLabel.textAlignment = .center
                
                cell.titleLabel.text = currentItem.container.metadata?.longDescription
                
                if((currentItem.container.metadata?.pictureUrl?.isEmpty) ?? true) {
                    cell.thumbnailImageView.image = UIImage(named: "thumb_placeholder")
                }else{
                    cell.applyImage(pictureId: currentItem.container.metadata?.pictureUrl ?? "", imageView: cell.thumbnailImageView)
                }
                
            default:
                print("No content")
            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(self.contentSections == nil) {
            if let pageUri = self.pageUri {
                DataManager.instance.loadContentPage(pageUri: pageUri, contentPageProtocol: self)
            }
            return
        }
        
        let currentItem = self.contentSections?[indexPath.section].items[indexPath.row] ?? ContentItem()
        
        switch currentItem.objectType {
        case .Video:
            if(currentItem.container.metadata?.emfAttributes?.videoType == "meetingSession"){
                DataManager.instance.loadContentVideo(videoId: String(currentItem.container.metadata?.contentId ?? 0), contentVideoProtocol: self)
                
                return
            }
            
            //Play the video
            if(!CredentialHelper.isLoginInformationCached() || CredentialHelper.getUserInfo().authData.subscriptionStatus != "active"){
                UserInteractionHelper.instance.showAlert(title: NSLocalizedString("account_no_subscription_title", comment: ""), message: NSLocalizedString("account_no_subscription_message", comment: ""))
                return
            }
            
            if let id = currentItem.container.metadata?.contentId {
                if let additionalStream = currentItem.container.metadata?.additionalStreams?.first {
                    PlayerController.instance.playStream(contentId: additionalStream.playbackUrl)
                    return
                }
                
                PlayerController.instance.playStream(contentId: String(id))
            }
        
            
        case .Launcher, .Bundle:
            //Open sub-page
            if let action = currentItem.container.actions?.first {
                let sideInfoVc = self.getViewControllerWith(viewIdentifier: ConstantsUtil.sideBarInfoViewController) as! SideBarInfoViewController
                sideInfoVc.initialize(contentItem: currentItem)
                
                let subPageVc = self.getViewControllerWith(viewIdentifier: ConstantsUtil.pageOverviewCollectionViewController) as! PageOverviewCollectionViewController
                subPageVc.initialize(pageUri: action.uri)
                
                let splitVc = UISplitViewController()
                splitVc.viewControllers = [sideInfoVc, subPageVc]
                
                self.presentFullscreenInNavigationController(viewController: splitVc)
            }
            
        default:
            print("Cannot handle this yet")
        }
    }
    
    func didLoadVideo(contentVideo: ResultObjectDto) {
        if let container = contentVideo.containers?.first {
            if(container.metadata?.additionalStreams?.isEmpty ?? true) {
                if let id = container.metadata?.contentId {
                    PlayerController.instance.playStream(contentId: String(id))
                    return
                }
            }
            
            var mainChannelsSection = ContentSection()
            mainChannelsSection.title = NSLocalizedString("main_channels_title", comment: "")
            
            var driverChannelsSection = ContentSection()
            driverChannelsSection.title = NSLocalizedString("driver_channels_title", comment: "")
            
            var mainItems = [ContentItem]()
            var driverItems = [ContentItem]()
            
            //Add the main feed manually
            var mainFeedMetadata = container.metadata
            mainFeedMetadata?.title = NSLocalizedString("main_feed_title", comment: "")
            mainFeedMetadata?.emfAttributes?.videoType = ""
            mainFeedMetadata?.additionalStreams = nil
            let mainFeedChannel = ContentItem(objectType: .Video, container: ContainerDto(layout: "CONTENT_ITEM", actions: nil, properties: container.properties, metadata: mainFeedMetadata, bundles: nil, categories: nil, platformVariants: container.platformVariants, retrieveItems: nil, contentId: container.metadata?.contentId ?? 0, suggest: container.suggest, platformName: container.platformName))
            mainItems.append(mainFeedChannel)
            
            for additionalChannel in container.metadata?.additionalStreams ?? [AdditionalStreamDto]() {
                var additionalChannelMetadata = container.metadata
                additionalChannelMetadata?.emfAttributes?.videoType = ""
                additionalChannelMetadata?.pictureUrl = nil
                additionalChannelMetadata?.additionalStreams = [additionalChannel]
                
                switch additionalChannel.type {
                case "additional":
                    switch additionalChannel.title {
                    case "TRACKER":
                        additionalChannelMetadata?.title = NSLocalizedString("tracker_feed_title", comment: "")
                        
                    case "PIT LANE":
                        additionalChannelMetadata?.title = NSLocalizedString("pit_lane_feed_title", comment: "")
                        
                    case "DATA":
                        additionalChannelMetadata?.title = NSLocalizedString("data_feed_title", comment: "")
                        
                    default:
                        additionalChannelMetadata?.title = additionalChannel.title
                    }
                    
                    let additionalFeedChannel = ContentItem(objectType: .Video, container: ContainerDto(layout: "CONTENT_ITEM", actions: nil, properties: container.properties, metadata: additionalChannelMetadata, bundles: nil, categories: nil, platformVariants: container.platformVariants, retrieveItems: nil, contentId: container.metadata?.contentId ?? 0, suggest: container.suggest, platformName: container.platformName))
                    mainItems.append(additionalFeedChannel)
                    
                case "obc":
                    additionalChannelMetadata?.title = (additionalChannel.driverFirstName ?? "") + " " + (additionalChannel.driverLastName ?? "")
                    
                    let additionalFeedChannel = ContentItem(objectType: .Video, container: ContainerDto(layout: "CONTENT_ITEM", actions: nil, properties: container.properties, metadata: additionalChannelMetadata, bundles: nil, categories: nil, platformVariants: container.platformVariants, retrieveItems: nil, contentId: container.metadata?.contentId ?? 0, suggest: container.suggest, platformName: container.platformName))
                    driverItems.append(additionalFeedChannel)
                    
                default:
                    print("What even is this?")
                }
            }
            
            mainChannelsSection.items = mainItems
            driverChannelsSection.items = driverItems
            
            let sideInfoVc = self.getViewControllerWith(viewIdentifier: ConstantsUtil.sideBarInfoViewController) as! SideBarInfoViewController
            sideInfoVc.initialize(contentItem: ContentItem(objectType: ContentObjectType.fromIdentifier(identifier: container.metadata?.objectType ?? ContentObjectType().getIdentifier()), container: container))
            
            let subPageVc = self.getViewControllerWith(viewIdentifier: ConstantsUtil.pageOverviewCollectionViewController) as! PageOverviewCollectionViewController
            subPageVc.initialize(contentSections: [mainChannelsSection, driverChannelsSection])
            
            let splitVc = UISplitViewController()
            splitVc.viewControllers = [sideInfoVc, subPageVc]
            
            self.presentFullscreenInNavigationController(viewController: splitVc)
        }
    }
    
    @objc func viewAllPressed(_ button: UIButton) {
        var currentItem = self.contentSections?[button.tag] ?? ContentSection()
        
        if let actionUrl = currentItem.container.actions?.first?.uri {
            let sideInfoVc = self.getViewControllerWith(viewIdentifier: ConstantsUtil.sideBarInfoViewController) as! SideBarInfoViewController
            currentItem.container.metadata?.title = currentItem.title
            sideInfoVc.initialize(contentItem: ContentItem(objectType: .Bundle, container: currentItem.container))
            
            let subPageVc = self.getViewControllerWith(viewIdentifier: ConstantsUtil.pageOverviewCollectionViewController) as! PageOverviewCollectionViewController
            subPageVc.initialize(pageUri: actionUrl)
            
            let splitVc = UISplitViewController()
            splitVc.viewControllers = [sideInfoVc, subPageVc]
            
            self.presentFullscreenInNavigationController(viewController: splitVc)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //2*24 between cells + 2*24 for left and right
        let width = (collectionView.frame.width-96)/3
        return CGSize(width: width, height: width*ConstantsUtil.thumnailCardHeightMultiplier)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = self.collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ConstantsUtil.customHeaderCollectionReusableView, for: indexPath)
            
            for subview in headerView.subviews {
                subview.removeFromSuperview()
            }
            
            let currentItem = self.contentSections?[indexPath.section]
            if(!((currentItem?.title.isEmpty) ?? false)) {
                let height = self.getSupplementaryHeight(section: indexPath.section, contentSection: currentItem ?? ContentSection())
                
                let holderStackView = UIStackView(frame: CGRect(x: 24, y: height-80, width: self.view.bounds.width-48, height: 60))
                holderStackView.axis = .horizontal
                holderStackView.spacing = 2
                
                switch currentItem?.layoutType {
                case .Title:
                    let titleLabel = FontAdjustedUILabel()
                    titleLabel.font = UIFont(name: "Formula1-Display-Bold", size: 60)
                    titleLabel.text = currentItem?.title
                    
                    titleLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 250), for: .horizontal)
                    titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 750), for: .horizontal)
                    
                    holderStackView.addArrangedSubview(titleLabel)
                    
                default:
                    let titleLabel = FontAdjustedUILabel()
                    titleLabel.font = UIFont(name: "Formula1-Display-Bold", size: 34)
                    titleLabel.text = currentItem?.title
                    
                    holderStackView.addArrangedSubview(titleLabel)
                }
                
                if let actionUrl = currentItem?.container.actions?.first?.uri {
                    if(!actionUrl.isEmpty) {
                        let actionButton = UIButton(type: .system)
                        actionButton.setTitle(NSLocalizedString("view_all", comment: ""), for: .normal)
                        actionButton.tag = indexPath.section
                        actionButton.addTarget(self, action: #selector(self.viewAllPressed), for: .primaryActionTriggered)
                        
                        actionButton.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
                        actionButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 751), for: .horizontal)
                        
                        holderStackView.addArrangedSubview(actionButton)
                    }
                }
                
                headerView.addSubview(holderStackView)
            }
            
            return headerView
        default:
            print("No user for kind: " + kind)
            assert(false, "Did not expect a footer view")
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let currentItem = self.contentSections?[section]
        
        return CGSize(width: self.view.frame.width, height: self.getSupplementaryHeight(section: section, contentSection: currentItem ?? ContentSection()))
    }
    
    func getSupplementaryHeight(section: Int, contentSection: ContentSection) -> CGFloat {
        var heigt: CGFloat = 120
        
        if(section == 0) {
            heigt = 80
        }
        
        switch contentSection.layoutType {
        case .Title:
            heigt+=100
            
        default:
            print("It's fine like that")
        }
        
        if(contentSection.title.isEmpty) {
            heigt = 50
        }
        
        return heigt
    }
}
