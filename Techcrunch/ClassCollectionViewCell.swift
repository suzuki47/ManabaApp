//
//  ClassCollectionViewCell.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/02/25.
//
import UIKit

class ClassCollectionViewCell: UICollectionViewCell {
    var label: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        setupLabel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupLabel() {
        label = UILabel(frame: bounds)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        addSubview(label)
    }

    func configure(text: String) {
        label.text = text
        // 枠線の色を黒に設定
        self.layer.borderColor = UIColor.black.cgColor
        // 枠線の幅を設定
        self.layer.borderWidth = 1.0
    }
}

