//
//  EditableTableViewCell.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/07/26.
//

import UIKit

class EditableTableViewCell: UITableViewCell {
    let textField: UITextField
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        textField = UITextField(frame: .zero)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTextField()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTextField() {
        textField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textField)
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
}

