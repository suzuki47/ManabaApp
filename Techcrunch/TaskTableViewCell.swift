import UIKit

class TaskTableViewCell: UITableViewCell {
    let titleLabel = UILabel()
    let deadlineLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        deadlineLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // スタイルの設定
        deadlineLabel.font = UIFont.systemFont(ofSize: 12)
        deadlineLabel.textColor = .gray
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(deadlineLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            
            deadlineLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            deadlineLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            deadlineLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            deadlineLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])
    }
    
    func configure(with task: TaskInformation) {
        let classNameDisplay = task.belongedClassName.dropFirst(6) // "34395:卒業研究１(AD)" から "卒業研究１(AD)" を取得
        titleLabel.text = "\(classNameDisplay) : \(task.taskName)"
        
        // DateFormatterの設定
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" // 必要に応じてフォーマットを調整
        let dueDateString = dateFormatter.string(from: task.dueDate)
        deadlineLabel.text = dueDateString
    }
}
