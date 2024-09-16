import UIKit

class NotificationCell: UITableViewCell {
    var checkbox: UIButton!
    var titleLabel: UILabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCheckbox()
        setupTitleLabel()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCheckbox()
        setupTitleLabel()
    }

    func setupCheckbox() {
        checkbox = UIButton(type: .system)
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.setImage(UIImage(systemName: "square"), for: .normal)
        checkbox.tintColor = .black
        contentView.addSubview(checkbox)

        NSLayoutConstraint.activate([
            checkbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            checkbox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkbox.widthAnchor.constraint(equalToConstant: 24),
            checkbox.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func setupTitleLabel() {
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])
    }
}
