//
//  FloatingButton.swift
//  GameGether
//
//  Created by James Ajhar on 11/29/18.
//  Copyright © 2018 James Ajhar. All rights reserved.
//

import UIKit

enum FloatingViewSocket {
    case topLeft
    case topRight
    case midLeft
    case midRight
    case bottomLeft
    case bottomRight
}

protocol FloatingViewOverlaySocketHandler {
    var topLeftSocketInset: CGFloat? { get }
    var topRightSocketInset: CGFloat? { get }
    var midLeftSocketInset: CGFloat? { get }
    var midRightSocketInset: CGFloat? { get }
    var bottomLeftSocketInset: CGFloat? { get }
    var bottomRightSocketInset: CGFloat? { get }
    
    var sockets: [FloatingViewSocket] { get }
}

extension FloatingViewOverlaySocketHandler {
    var topLeftSocketInset: CGFloat? { return nil }
    var topRightSocketInset: CGFloat? { return nil }
    var midLeftSocketInset: CGFloat? { return nil }
    var midRightSocketInset: CGFloat? { return nil }
    var bottomLeftSocketInset: CGFloat? { return nil }
    var bottomRightSocketInset: CGFloat? { return nil }
    
    var sockets: [FloatingViewSocket] {
        return [.bottomLeft]
    }
}

class FloatingViewOverlay: UIView {
    
    private var floatingViewXConstraint: NSLayoutConstraint?
    private var floatingViewYConstraint: NSLayoutConstraint?
    private var startingConstantX: CGFloat  = 0.0
    private var startingConstantY: CGFloat  = 0.0
    private var isPanning: Bool = false
    
    var floatingView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            
            if let floatingView = floatingView {                
                let panner = UIPanGestureRecognizer(target: self,
                                                    action: #selector(FloatingViewOverlay.panDidFire(panner:)))
                floatingView.addGestureRecognizer(panner)
                floatingView.translatesAutoresizingMaskIntoConstraints = false
                addSubview(floatingView)
                
                floatingViewXConstraint = floatingView.constrainToCenterHorizontal()
                floatingViewYConstraint = floatingView.constrainToCenterVertical()

                // Default position is bottom right
                snapFloatingView(toPoint: CGPoint(x: bounds.maxX, y: bounds.maxY))
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
       
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
    
    @objc func panDidFire(panner: UIPanGestureRecognizer) {
        guard let _ = floatingView else { return }
        
        switch panner.state {
        case .began:
            isPanning = true
            startingConstantX = floatingViewXConstraint?.constant ?? 0
            startingConstantY = floatingViewYConstraint?.constant ?? 0

        case .changed:
            let translation = panner.translation(in: self)
            
            floatingViewXConstraint?.constant = startingConstantX + translation.x
            floatingViewYConstraint?.constant = startingConstantY + translation.y
            layoutIfNeeded()
            
        case .ended, .cancelled:
            isPanning = false
            UIView.animate(withDuration: 0.3) {
                self.snapButtonToSocket()
            }
        default:
            break
        }
    }
    
//    @objc func keyboardDidShow(note: NSNotification) {
//        (window as? FloatingButtonWindow)?.windowLevel = 0
//        (window as? FloatingButtonWindow)?.windowLevel = CGFloat.greatestFiniteMagnitude
//    }
    
    public func snapButtonToSocket() {
        guard let floatingView = floatingView, !isPanning else { return }

        var bestSocket = CGPoint.zero
        var distanceToBestSocket = CGFloat.infinity
        let center = floatingView.center
        for socket in sockets {
            let distance = hypot(center.x - socket.x, center.y - socket.y)
            if distance < distanceToBestSocket {
                distanceToBestSocket = distance
                bestSocket = socket
            }
        }
        
        // Translate the floating view's center coordinate in terms of the superview's true center coordinate
        floatingViewXConstraint?.constant = -(self.center.x - bestSocket.x)
        floatingViewYConstraint?.constant = -(self.center.y - bestSocket.y)
        layoutIfNeeded()
    }
    
    func updateView() {
        UIView.animate(withDuration: 0.3) {
            self.snapButtonToSocket()
        }
    }
    
    public func snapFloatingView(toPoint point: CGPoint) {
        guard let _ = floatingView else { return }

        floatingViewXConstraint?.constant = point.x / 2
        floatingViewYConstraint?.constant = point.y / 2
        layoutIfNeeded()

        snapButtonToSocket()
    }
    
    public func snapFloatingView(toSocket socket: FloatingViewSocket) {
        guard let _ = floatingView else { return }
        
        UIView.animate(withDuration: 0.3) {
            self.snapFloatingView(toPoint: self.point(forSocket: socket))
        }
    }
    
    private var socketViewBounds: CGRect {
        guard let floatingView = floatingView else { return .zero }
        let floatingViewSize = floatingView.bounds.size
        let viewWidthInset = 7 + floatingViewSize.width / 2
        let viewHeightInset = 10 + floatingViewSize.height / 2
        var viewRect = bounds.insetBy(dx: viewWidthInset, dy: viewHeightInset)
        
        viewRect = CGRect(x: viewRect.minX,
                          y: viewRect.minY + safeAreaInsets.top,
                          width: viewRect.width,
                          height: viewRect.height - (safeAreaInsets.bottom + safeAreaInsets.top))
        return viewRect
    }
    
    private var sockets: [CGPoint] {
        
        let topVC = NavigationManager.topMostViewController() as? FloatingViewOverlaySocketHandler
        let availableSockets = topVC?.sockets ?? [.bottomLeft, .bottomRight, .midLeft, .midRight]
        
        var sockets = [CGPoint]()
        
        for socket in availableSockets {
            sockets.append(point(forSocket: socket))
        }

        return sockets
    }
    
    private func point(forSocket socket: FloatingViewSocket) -> CGPoint {
        guard let _ = floatingView else { return .zero }
        
        let topVC = NavigationManager.topMostViewController() as? FloatingViewOverlaySocketHandler
        
        let socketBounds = socketViewBounds

        switch socket {
        case .topLeft:
            return CGPoint(x: socketBounds.minX, y: socketBounds.minY + (topVC?.topLeftSocketInset ?? 60))
        case .topRight:
            return CGPoint(x: socketBounds.minX + (topVC?.midLeftSocketInset ?? 0), y: socketBounds.midY)
        case .midLeft:
            return CGPoint(x: socketBounds.minX + (topVC?.midLeftSocketInset ?? 0), y: socketBounds.midY)
        case .midRight:
            return CGPoint(x: socketBounds.maxX - (topVC?.midRightSocketInset ?? 0), y: socketBounds.midY)
        case .bottomLeft:
            return CGPoint(x: socketBounds.minX, y: socketBounds.maxY - (topVC?.bottomLeftSocketInset ?? 50))
        case .bottomRight:
            return CGPoint(x: socketBounds.maxX, y: socketBounds.maxY - (topVC?.bottomRightSocketInset ?? 50))
        }
    }
}
