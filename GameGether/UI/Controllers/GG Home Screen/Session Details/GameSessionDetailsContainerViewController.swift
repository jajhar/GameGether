//
//  GameSessionDetailsContainerViewController.swift
//  GameGether
//
//  Created by James Ajhar on 11/5/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit

class GameSessionDetailsContainerViewController: UIViewController {

    // MARK: - Properties
    
    private var sessionDetailsViewController: GameSessionDetailsViewController?
    
    public var session: GameSession?
    
    public var onDismiss: (() -> Void)?
    
    public var onSessionJoined: ((GameSession) -> Void)?
    public var onSessionLeft: ((GameSession) -> Void)?
    public var onGoToLobbyPressed: ((GameSession) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? GameSessionDetailsViewController {
            vc.session = session
            
            vc.onClosePressed = { [weak self] in
                self?.dismissSelf(completion: {
                    self?.onDismiss?()
                })
            }
            
            vc.onGoToLobbyPressed = onGoToLobbyPressed
            vc.onSessionJoined = onSessionJoined
            vc.onSessionLeft = onSessionLeft
            
            sessionDetailsViewController = vc
        }
    }

}
