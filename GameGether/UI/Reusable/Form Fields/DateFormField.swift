//
//  DateFormField.swift
//  GameGether
//
//  Created by James on 10/5/16.
//  Copyright © 2018 James. All rights reserved.
//

import UIKit

protocol DateFormFieldDelegate: class {
    func dateFormField(dateField: DateFormField, doneButtonPressed date: Date)
}

class DateFormField: FormTextField {

    var datePicker: UIDatePicker!
    private var toolbar: UIToolbar!
    weak var dateFormDelegate: DateFormFieldDelegate?

    var barButtonTitle: String = "done" {
        didSet {
            updateBarButton()
        }
    }
    
    override func commonInit() {
        super.commonInit()

        setTitleLabel(hidden: true)
        
        // Setup date picker
        datePicker = UIDatePicker(frame: .zero)
        datePicker.datePickerMode = .date
        datePicker.maximumDate = Date()
        datePicker.addTarget(self, action: #selector(dateChanged(sender:)), for: .valueChanged)
        inputView = datePicker

        // Setup keyboard toolbar
        toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: frame.width, height: 50))
        toolbar.barStyle = .default
        updateBarButton()
        inputAccessoryView = toolbar
    }
    
    private func updateBarButton() {
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: barButtonTitle,
                            style: .done,
                            target: self,
                            action: #selector(doneButtonPressed(sender:)))
        ]
        toolbar.sizeToFit()
    }

    @objc func doneButtonPressed(sender: UIBarButtonItem?) {
        _ = resignFirstResponder()
        dateFormDelegate?.dateFormField(dateField: self, doneButtonPressed: datePicker.date)
    }
    
    @objc func dateChanged(sender: UIDatePicker) {
        text = sender.date.monthDayYearFormat()
    }

}
