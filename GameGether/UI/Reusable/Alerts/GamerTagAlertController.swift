//
//  GamerTagAlertController.swift
//  GameGether
//
//  Created by James Ajhar on 8/26/19.
//  Copyright © 2019 James Ajhar. All rights reserved.
//

import UIKit
import PKHUD

class GamerTagAlertController: UIAlertController {

    struct Constants {
        static let maxIGNCharacters: UInt = 32
    }
    
    private weak var gamerTagTextField: UITextField?
    private var gamerTagSaveAction: UIAlertAction?
    

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    convenience init(withgame game: Game,
                     title: String? = nil,
                     message: String? = nil,
                     cancelButtonTitle: String = "cancel",
                     onSaveAction: ((String) -> Void)?,
                     onRemoveAction: ((Game) -> Void)? = nil,
                     onCancelAction: (() -> Void)? = nil) {
        
        self.init(title: title, message: message, preferredStyle: .alert)

        let saveAction = UIAlertAction(title: "save", style: .default) { [weak self] _ in
            guard let ign = self?.gamerTagTextField?.text else { return }
            onSaveAction?(ign)
        }

        self.gamerTagSaveAction = saveAction
        addAction(saveAction)

//        if let onRemoveAction = onRemoveAction {
//            addAction(UIAlertAction(title: "remove game", style: .destructive) { _ in
//                onRemoveAction(game)
//            })
//        } else {
            addAction(UIAlertAction(title: cancelButtonTitle, style: .default, handler: { _ in
                onCancelAction?()
            }))
//        }
        
        addTextField { textField in
            textField.addTarget(self, action: #selector(self.alertViewTextChanged(_:)), for: .editingChanged)
            textField.textAlignment = .center
            self.gamerTagTextField = textField
            textField.text = game.gamerTag.isEmpty ? DataCoordinator.shared.signedInUser?.ign : game.gamerTag
            textField.delegate = self
        }
    }
    
    @objc func alertViewTextChanged(_ sender: UITextField) {
        gamerTagSaveAction?.isEnabled = sender.text?.isEmpty == false
    }
}

extension GamerTagAlertController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == gamerTagTextField {
            // limit to 32 characters max
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            
            guard updatedText.count <= Constants.maxIGNCharacters else {
                return false
            }
        }
        
        return true
    }
}
