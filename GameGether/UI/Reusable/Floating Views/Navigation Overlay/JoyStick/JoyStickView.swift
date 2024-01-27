//
//  JoyStickView.swift
//  GameGether
//
//  Created by James Ajhar on 2/3/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import CoreGraphics

/**
 Type definition for a function that will receive updates from the JoyStickView when the handle moves. Takes two
 values, both CGFloats.
 
 - parameter angle: the direction the handle is pointing. Unit is degrees with 0° pointing up (north), and 90° pointing
 right (east).
 - parameter displacement: how far from the view center the joystick is moved in the above direction. Unitless but
 is the ratio of distance moved from center over the radius of the joystick base. Always in range 0.0-1.0
 */
public typealias JoyStickViewMonitor = (_ angle: JoyStickDirection, _ displacement: CGFloat, _ point: CGPoint) -> ()

public enum JoyStickDirection {
    case top
    case bottom
    case left
    case right
}

/**
 A simple implementation of a joystick interface like those found on classic arcade games. This implementation detects
 and reports two values when the joystick moves:
 
 * angle: the direction the handle is pointing. Unit is degrees with 0° pointing up (north), and 90° pointing
 right (east).
 * displacement: how far from the view center the joystick is moved in the above direction. Unitless but
 is the ratio of distance moved from center over the radius of the joystick base. Always in range 0.0-1.0
 
 The view has several settable parameters that be used to configure a joystick's appearance and behavior:
 
 - monitor: a function of type `JoyStickViewMonitor` that will receive updates when the joystick's angle and/or
 displacement values change.
 - movable: a boolean that when true lets the joystick move around in its parent's view when there joystick moves
 beyond displacement of 1.0.
 - movableBounds: a CGRect which limits where a movable joystick may travel
 - baseImage: a UIImage to use for the joystick's base
 - handleImage: a UIImage to use for the joystick's handle
 
 Additional documentation is available via the attribute names below.
 */
@IBDesignable public final class JoyStickView: UIView {
    
    /// Holds a function to call when joystick orientation changes
    public var monitor: JoyStickViewMonitor?
    
    public var onTouchesEnded: JoyStickViewMonitor?
    
    public var onHandleTapped: ((UIView) -> Void)?

    /// The last-reported angle from the joystick handle. Unit is degrees, with 0° up (north) and 90° right (east)
    public var angle: CGFloat { return displacement != 0.0 ? CGFloat(180.0 - angleRadians * 180.0 / Float.pi) : 0.0 }
    
    /// The last-reported displacement from the joystick handle. Dimensionless but is the ratio of movement over
    /// the radius of the joystick base. Always falls between 0.0 and 1.0
    public private(set) var displacement: CGFloat = 0.0
    
    /// If `true` the joystick will move around in the parent's view so that the joystick handle is always at a
    /// displacement of 1.0. This is the default mode of operation. Setting to `false` will keep the view fixed.
    @IBInspectable public var movable: Bool = false
    
    /// The original location of a movable joystick. Used to restore its position when user double-taps on it.
    public var movableCenter: CGPoint? = nil
    
    /// Area where the joystick can move
    public var movableBounds: CGRect? {
        didSet {
            switch movableBounds {
            case .some(let mb):
                centerClamper = { CGPoint(x: min(max($0.x, mb.minX), mb.maxX), y: min(max($0.y, mb.minY), mb.maxY)) }
            default:
                centerClamper = { $0 }
            }
        }
    }
    
    /// The opacity of the base of the joystick. Note that this is different than the view's overall opacity
    /// setting. The end result will be a base image with an opacity of `baseAlpha` * `view.alpha`
    @IBInspectable public var baseAlpha: CGFloat {
        get {
            return baseImageView.alpha
        }
        set {
            baseImageView.alpha = newValue
        }
    }
    
    /// The opacity of the handle of the joystick. Note that this is different than the view's overall opacity setting.
    /// The end result will be a handle image with an opacity of `handleAlpha` * `view.alpha`
    @IBInspectable public var handleAlpha: CGFloat {
        get {
            return handleImageView.alpha
        }
        set {
            handleImageView.alpha = newValue
        }
    }
    
    /// The tintColor to apply to the handle. Changing it while joystick is visible will update the handle image.
    @IBInspectable public var handleTintColor: UIColor? = nil {
        didSet { generateHandleImage() }
    }
    
    /// Scaling factor to apply to the joystick handle. A value of 1.0 will result in no scaling of the image,
    /// however the default value is 0.85 due to historical reasons.
    @IBInspectable public var handleSizeRatio: CGFloat = 1.0 {
        didSet {
//            scaleHandleImageView()
        }
    }
    
    /// Control how the handle image is generated. When this is `false` (default), a CIFilter will be used to tint
    /// the handle image with the `handleTintColor`. This results in a monochrome image of just one color, but with
    /// lighter and darker areas depending on the original image. When this is `true`, the handle image is just
    /// used as a mask, and all pixels with an alpha = 1.0 will be colored with the `handleTintColor` value.
    @IBInspectable public var colorFillHandleImage: Bool = false {
        didSet { generateHandleImage() }
    }
    
    /// Controls how far the handle can travel along the radius of the base. A value of 1.0 (default) will let the handle travel
    /// the full radius, with maximum travel leaving the center of the handle lying on the circumference of the base. A value
    /// greater than 1.0 will let the handle travel beyond the circumference of the base, while a value less than 1.0 will
    /// reduce the travel to values within the circumference. Note that regardless of this value, handle movements will always
    /// report displacement values between 0.0 and 1.0 inclusive.
    @IBInspectable public var travel: CGFloat = 1.0
    
    /// The image to use for the base of the joystick
    @IBInspectable public var baseImage: UIImage? {
        didSet { baseImageView.image = baseImage }
    }
    
    /// The image to use for the joystick handle
    @IBInspectable public var handleImage: UIImage? {
        didSet { generateHandleImage() }
    }
    
    /// The max distance the handle may move in any direction, where the start is the center of the joystick base and the end
    /// is on the circumference of the base when travel is 1.0.
    private var radius: CGFloat { return self.bounds.size.width / 2.0 * travel }
    
    /// The image to use to show the base of the joystick
    private var baseImageView: UIImageView = UIImageView(image: nil)
    
    /// The image to use to show the handle of the joystick
    var handleImageView: UIImageView = UIImageView(image: nil)
    
    let handleImageContainerView: UIView = {
        let shadowView = UIView(frame: .zero)
        shadowView.addDropShadow(color: .black, opacity: 0.33, offset: CGSize(width: 1, height: 5), radius: 5)
        shadowView.cornerRadius = 30
        return shadowView
    }()
    
    /// Set to true if the joystick should stay put (not move)
    public var lock: Bool = false

    /// Cache of the last joystick angle in radians
    private var angleRadians: Float = 0.0
    
    /// Tap gesture recognizer for double-taps which will reset the joystick position
    private var tapGestureRecognizer: UITapGestureRecognizer?
    
    /// A filter for joystick handle centers. Used to restrict handle movements.
    private var centerClamper: (CGPoint) -> CGPoint = { $0 }
    
    /// Tap gesture recognizer for detecting double-taps. Only present if `enableDoubleTapForFrameReset` is true
    private var doubleTapGestureRecognizer: UITapGestureRecognizer?
    
    private var isMovingJoystick: Bool = false
    
    private var topArrow: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "GreyArrow"))
        imageView.tintColor = UIColor(hexString: "#E7E7E7")
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
//    private var bottomArrow: UIImageView = {
//        let imageView = UIImageView(image: #imageLiteral(resourceName: "GreyArrow"))
//        imageView.tintColor = UIColor(hexString: "#E7E7E7")
//        imageView.contentMode = .center
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.transform = CGAffineTransform(rotationAngle: .pi)
//        return imageView
//    }()
    
    private var leftArrow: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "GreyArrow"))
        imageView.tintColor = UIColor(hexString: "#E7E7E7")
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.transform = CGAffineTransform(rotationAngle: -.pi/2)
        return imageView
    }()
    
    /**
     Initialize new joystick view using the given frame.
     - parameter frame: the location and size of the joystick
     */
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    /**
     Initialize new joystick view from a file.
     - parameter coder: the source of the joystick configuration information
     */
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
}

// MARK: - Touch Handling

extension JoyStickView {
    /**
     A touch began in the joystick view
     - parameter touches: the set of UITouch instances, one for each touch event
     - parameter event: additional event info (ignored)
     */
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !lock, let touch = touches.first else { return }
        updatePosition(touch: touch)
    }
    
    /**
     An existing touch has moved.
     - parameter touches: the set of UITouch instances, one for each touch event
     - parameter event: additional event info (ignored)
     */
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !lock, let touch = touches.first else { return }
        updatePosition(touch: touch)
    }
    
    /**
     An existing touch event has been cancelled (probably due to system event such as an alert). Move joystick to
     center of base.
     - parameter touches: the set of UITouch instances, one for each touch event (ignored)
     - parameter event: additional event info (ignored)
     */
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !lock else { return }
        
        // Report the last known position
        onTouchesEnded?(joyStickDirection(forAngle: angle), displacement, handleImageContainerView.center)
        // Move back to the home position
        homePosition()
    }
    
    /**
     User removed touch from display. Move joystick to center of base.
     - parameter touches: the set of UITouch instances, one for each touch event (ignored)
     - parameter event: additional event info (ignored)
     */
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !lock else { return }

        // Report the last known position
        onTouchesEnded?(joyStickDirection(forAngle: angle), displacement, handleImageContainerView.center)
        // Move back to the home position
        homePosition()
    }
    
    /**
     Reset our base to the initial location before the user moved it. By default, this will take place
     whenever the user double-taps on the joystick handle.
     */
    @objc public func resetFrame() {
        guard let movableCenter = self.movableCenter, displacement < 0.5 else { return }
        center = movableCenter
    }
    
    public func resetJoystick() {
        homePosition()
    }
}

// MARK: - Implementation Details

extension JoyStickView {
    
    /**
     Common initialization of view. Creates UIImageView instances for base and handle.
     */
    private func initialize() {
        baseImageView.frame = bounds
        addSubview(baseImageView)

        addSubview(topArrow)
        topArrow.constrainToCenterHorizontal()
        topArrow.constrainTo(edge: .top)?.constant = 6
        topArrow.alpha = 0
        
//        addSubview(bottomArrow)
//        bottomArrow.constrainToCenterHorizontal()
//        bottomArrow.constrainTo(edge: .bottom)?.constant = -6
//        bottomArrow.alpha = 0

        addSubview(leftArrow)
        _ = leftArrow.constrainToCenterVertical()
        leftArrow.constrainTo(edge: .left)?.constant = 6
        leftArrow.alpha = 0

//        scaleHandleImageView()
        
        let bundle = Bundle(for: JoyStickView.self)
        
        if self.baseImage == nil {
            if let baseImage = UIImage(named: "DefaultBase", in: bundle, compatibleWith: nil) {
                self.baseImage = baseImage
            }
        }
        
        baseImageView.image = baseImage
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapped(sender:)))
        handleImageView.addGestureRecognizer(tapGesture)
        handleImageView.isUserInteractionEnabled = true
        
        if self.handleImage == nil {
            if let handleImage = UIImage(named: "DefaultHandle", in: bundle, compatibleWith: nil) {
                self.handleImage = handleImage
            }
        }
        
        generateHandleImage()
        
        handleImageContainerView.translatesAutoresizingMaskIntoConstraints = false
        handleImageContainerView.constrainWidth(60)
        handleImageContainerView.constrainHeight(60)
        
        handleImageView.cornerRadius = 30
        handleImageView.clipsToBounds = true
        handleImageView.translatesAutoresizingMaskIntoConstraints = false

        handleImageContainerView.addSubview(handleImageView)
        handleImageView.constrainToSuperview()
        addSubview(handleImageContainerView)
    }
    
    @objc func handleTapped(sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        onHandleTapped?(view)
    }
    
//    private func scaleHandleImageView() {
//        let inset = (1.0 - handleSizeRatio) * bounds.width
//        handleImageView.frame = bounds.insetBy(dx: inset, dy: inset)
//    }

    private func generateHandleImage() {
        handleImageView.image = handleImage
    }
    
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // If the user isn't touching the handle, pass all taps through
        let view = super.hitTest(point, with: event)
        return handleImageView.frame.contains(point) ? view : nil
    }
    
    /**
     Reset handle position so that it is in the center of the base.
     */
    private func homePosition() {
        isMovingJoystick = false
        
        UIView.animate(withDuration: 0.3) {
            self.handleImageContainerView.center = self.bounds.mid
            self.baseAlpha = 0.0
            self.topArrow.alpha = 0.0
//            self.bottomArrow.alpha = 0.0
            self.leftArrow.alpha = 0.0
            self.topArrow.tintColor = UIColor(hexString: "#E7E7E7")
//            self.bottomArrow.tintColor = UIColor(hexString: "#E7E7E7")
            self.leftArrow.tintColor = UIColor(hexString: "#E7E7E7")
        }
        reportPosition(angleRadians: 0.0, displacement: 0.0)
    }
    
    /**
     Update the handle position based on the current touch location.
     - parameter touch: the UITouch instance describing where the finger/pencil is
     */
    private func updatePosition(touch: UITouch) {
        updateLocation(location: touch.location(in: superview!))
    }
    
    /**
     Update the location of the joystick based on the given touch location. Resulting behavior depends on `movable`
     setting.
     - parameter location: the current handle position. NOTE: in coordinates of the superview
     */
    private func updateLocation(location: CGPoint) {
        
        let delta = location - frame.mid
        let newDisplacement = delta.magnitude / radius
        
        // Ignore moves that are below this minimum threshold. Prevents jerky behavior when the user
        //  just wants to tap the handle instead of drag it.
        if newDisplacement < 0.6, !isMovingJoystick { return }
        
        isMovingJoystick = true
        
        // Calculate pointing angle used displacements. NOTE: using this ordering of dx, dy to atan2f to obtain
        // navigation angles where 0 is at top of clock dial and angle values increase in a clock-wise direction.
        //
        let newAngleRadians = atan2f(Float(delta.dx), Float(delta.dy))
        
        if movable {
            if newDisplacement > 1.0 && repositionBase(location: location, angle: newAngleRadians) {
                repositionHandle(angle: newAngleRadians)
            }
            else {
                handleImageContainerView.center = bounds.mid + delta
            }
        } else {
            handleImageContainerView.center = bounds.mid + delta
        }
        
//        let backgroundAlpha = newDisplacement > 0.1 ? 1 : newDisplacement
//        UIView.animate(withDuration: 0.3) {
//            self.baseAlpha = backgroundAlpha
//            self.topArrow.alpha = backgroundAlpha
////            self.bottomArrow.alpha = backgroundAlpha
//            self.leftArrow.alpha = backgroundAlpha
//        }
//        
//        UIView.animate(withDuration: 0.3) {
//            if newDisplacement > 0.5 {
//                switch self.joyStickDirection(forAngle: self.angle) {
//                case .top:
//                    self.topArrow.tintColor = UIColor(hexString: "#57A2E1")
////                    self.bottomArrow.tintColor = UIColor(hexString: "#E7E7E7")
//                    self.leftArrow.tintColor = UIColor(hexString: "#E7E7E7")
//                    
//                case .bottom:
////                    self.bottomArrow.tintColor = UIColor(hexString: "#57A2E1")
//                    self.topArrow.tintColor = UIColor(hexString: "#E7E7E7")
//                    self.leftArrow.tintColor = UIColor(hexString: "#E7E7E7")
//                    
//                case .left:
//                    self.leftArrow.tintColor = UIColor(hexString: "#57A2E1")
//                    self.topArrow.tintColor = UIColor(hexString: "#E7E7E7")
////                    self.bottomArrow.tintColor = UIColor(hexString: "#E7E7E7")
//
//                case .right:
//                    break
//                }
//            } else {
//                self.topArrow.tintColor = UIColor(hexString: "#E7E7E7")
////                self.bottomArrow.tintColor = UIColor(hexString: "#E7E7E7")
//                self.leftArrow.tintColor = UIColor(hexString: "#E7E7E7")
//            }
//        }
        
        reportPosition(angleRadians: newAngleRadians, displacement: min(newDisplacement, 1.0))
    }
    
    /**
     Report the current joystick values to any registered `monitor`.
     
     - parameter angleRadians: the current angle of the joystick handle
     - parameter displacement: the current displacement of the joystick handle
     */
    private func reportPosition(angleRadians: Float, displacement: CGFloat) {
        if displacement != self.displacement || angleRadians != self.angleRadians {
            self.displacement = displacement
            self.angleRadians = angleRadians
            
            monitor?(joyStickDirection(forAngle: angle), displacement, handleImageContainerView.center)
        }
    }
    
    private func joyStickDirection(forAngle angle: CGFloat) -> JoyStickDirection {

        switch angle {
        case 0...45, 316...360:
            return .top
        case 46...135:
            return .right
        case 136...225:
            return .bottom
        case 226...315:
            return .left
        default:
            // Shouldn't happen
            return .top
        }
    }
    
    /**
     Move the base so that the handle displacement is <= 1.0 from the base. THe last step of this operation is
     a clamping of the base origin so that it stays within a configured boundary. Such clamping can result in
     a joystick handle whose displacement is > 1.0 from the base, so the caller should account for that by looking
     for a `true` return value.
     
     - parameter location: the current joystick handle center position
     - parameter angle: the angle the handle makes with the center of the base
     - returns: true if the base **cannot** move sufficiently to keep the displacement of the handle <= 1.0
     */
    private func repositionBase(location: CGPoint, angle: Float) -> Bool {
        if movableCenter == nil {
            movableCenter = self.center
        }
        
        // Calculate point that should be on the circumference of the base image.
        //
        let end = CGVector(dx: CGFloat(sinf(angle)) * radius, dy: CGFloat(cosf(angle)) * radius)
        
        // Calculate the origin of our frame, working backwards from the given location, and move to it.
        //
        let desiredCenter = location - end //  - frame.size / 2.0
        self.center = centerClamper(desiredCenter)
        return self.center != desiredCenter
    }
    
    /**
     Move the joystick handle so that the angle made up of the triangle from the base 12:00 position on its circumference, the base center,
     and the joystick center is the given value.
     
     - parameter angle: the angle (radians) to conform to
     */
    private func repositionHandle(angle: Float) {
        
        // Keep handle on the circumference of the base image
        //
        let x = CGFloat(sinf(angle)) * radius
        let y = CGFloat(cosf(angle)) * radius
        handleImageContainerView.frame.origin = CGPoint(x: x + bounds.midX - handleImageContainerView.bounds.size.width / 2.0,
                                               y: y + bounds.midY - handleImageContainerView.bounds.size.height / 2.0)
    }
}
