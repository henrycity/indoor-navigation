import Foundation


open class RoomCell: ActionCell {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }

    func initialize() {
        backgroundColor = .clear
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        selectedBackgroundView = backgroundView
        actionTitleLabel?.textColor = .white
        actionTitleLabel?.textAlignment = .left

    }
}

public struct RoomHeaderData {

    var roomName: String
    var roomInfo: String
    var roomCapacity: String
    var roomArea: String
//    var image: UIImage

    public init(name: String, availability: String, capacity: String, area: String) {
        self.roomName = name
        self.roomInfo = availability
        self.roomCapacity = capacity
        self.roomArea = area
//        self.image = image
    }
}

open class RoomHeaderView: UICollectionReusableView {

    open lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.image = UIImage(named: "sp-header-icon")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    open lazy var roomName: UILabel = {
        let roomName = UILabel(frame: CGRect.zero)
        roomName.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
        roomName.textColor = UIColor.white
        roomName.translatesAutoresizingMaskIntoConstraints = false
        roomName.sizeToFit()
        return roomName
    }()

    open lazy var roomAvailability: UILabel = {
        let roomAvailability = UILabel(frame: CGRect.zero)
        roomAvailability.font = UIFont(name: "HelveticaNeue", size: 16)
        roomAvailability.textColor = UIColor.white.withAlphaComponent(0.8)
        roomAvailability.translatesAutoresizingMaskIntoConstraints = false
        roomAvailability.sizeToFit()
        return roomAvailability
    }()

    open lazy var roomCapacity: UILabel = {
        let roomCapacity = UILabel(frame: CGRect.zero)
        roomCapacity.font = UIFont(name: "HelveticaNeue", size: 16)
        roomCapacity.textColor = UIColor.white.withAlphaComponent(0.8)
        roomCapacity.translatesAutoresizingMaskIntoConstraints = false
        roomCapacity.sizeToFit()
        return roomCapacity
    }()

    open lazy var roomArea: UILabel = {
        let roomArea = UILabel(frame: CGRect.zero)
        roomArea.font = UIFont(name: "HelveticaNeue", size: 16)
        roomArea.textColor = UIColor.white.withAlphaComponent(0.8)
        roomArea.translatesAutoresizingMaskIntoConstraints = false
        roomArea.sizeToFit()
        return roomArea
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }

    func initialize() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        addSubview(imageView)
        addSubview(roomName)
        addSubview(roomAvailability)
        addSubview(roomCapacity)
        addSubview(roomArea)
        let separator: UIView = {
            let separator = UIView(frame: CGRect.zero)
            separator.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            separator.translatesAutoresizingMaskIntoConstraints = false
            return separator
        }()
        addSubview(separator)

        let views = [ "ico": imageView, "name": roomName, "availability": roomAvailability,
                      "capacity": roomCapacity, "area": roomArea, "separator": separator ]
        let metrics = [ "icow": 54, "icoh": 54 ]
        let options = NSLayoutFormatOptions()

        addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-5-[ico(icow)]-10-[name]-5-|",
            options: options,
            metrics: metrics,
            views: views))
        addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|[separator]|",
            options: options,
            metrics: metrics,
            views: views))

        addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-20-[ico(icoh)]",
            options: options,
            metrics: metrics,
            views: views))
        addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|[name][availability][capacity][area]-5-|",
            options: .alignAllLeft,
            metrics: metrics,
            views: views))
        addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:[separator(1)]|",
            options: options,
            metrics: metrics,
            views: views))
    }
}

open class RoomActionController: ActionController<RoomCell, ActionData,
    RoomHeaderView, RoomHeaderData, UICollectionReusableView, Void> {

    fileprivate lazy var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        return blurView
    }()

    open override func viewDidLoad() {
        super.viewDidLoad()
        backgroundView.addSubview(blurView)

        cancelView?.frame.origin.y = view.bounds.size.height // Starts hidden below screen
        cancelView?.layer.shadowColor = UIColor.black.cgColor
        cancelView?.layer.shadowOffset = CGSize( width: 0, height: -4)
        cancelView?.layer.shadowRadius = 2
        cancelView?.layer.shadowOpacity = 0.8
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        blurView.frame = backgroundView.bounds
    }

    public override init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        settings.behavior.bounces = true
        settings.behavior.scrollEnabled = true
        settings.cancelView.showCancel = true
        settings.animation.scale = nil
        settings.animation.present.springVelocity = 0.0

        cellSpec = .nibFile(nibName: "RoomCell", bundle: Bundle(for: RoomCell.self), height: { _ in 60 })
        headerSpec = .cellClass( height: { _ in 84 })

        onConfigureCellForAction = { [weak self] cell, action, indexPath in
            cell.setup(action.data?.roomName, detail: action.data?.roomInfo, image: action.data?.image)
            cell.separatorView?.isHidden = indexPath.item == (
                self?.collectionView.numberOfItems(inSection: indexPath.section))! - 1
            cell.alpha = action.enabled ? 1.0 : 0.5
        }
        onConfigureHeader = { (header: RoomHeaderView, data: RoomHeaderData)  in
            header.roomName.text = data.roomName
            header.roomAvailability.text = data.roomInfo
            header.roomCapacity.text = data.roomCapacity
            header.roomArea.text = data.roomArea
//            header.imageView.image = data.image
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func performCustomDismissingAnimation(_ presentedView: UIView, presentingView: UIView) {
        super.performCustomDismissingAnimation(presentedView, presentingView: presentingView)
        cancelView?.frame.origin.y = view.bounds.size.height + 10
    }

    open override func onWillPresentView() {
        cancelView?.frame.origin.y = view.bounds.size.height
    }
}
