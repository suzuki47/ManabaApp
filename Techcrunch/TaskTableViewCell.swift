import UIKit

enum TaskSection: Int, CaseIterable {
    case submitted = 0
    case today
    case tomorrow
    case later
    
    var title: String {
        switch self {
        case .submitted: return "提出した課題"
        case .today: return "今日"
        case .tomorrow: return "明日"
        case .later: return "明後日以降"
        }
    }
}

class TaskTableViewCell: UITableViewCell {
    let titleLabel = UILabel()
    let deadlineLabel = UILabel()
    let countdownLabel = UILabel()
    var timer: Timer?
    var dueDate: Date? // dueDate プロパティの追加

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        startTimer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        deadlineLabel.translatesAutoresizingMaskIntoConstraints = false
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // スタイルの設定
        deadlineLabel.font = UIFont.systemFont(ofSize: 12)
        deadlineLabel.textColor = .gray
        countdownLabel.font = UIFont.systemFont(ofSize: 12)
        countdownLabel.textColor = .red
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(deadlineLabel)
        contentView.addSubview(countdownLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            
            deadlineLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            deadlineLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            
            countdownLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            countdownLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            countdownLabel.leadingAnchor.constraint(equalTo: deadlineLabel.trailingAnchor, constant: 0),
            countdownLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])
    }
    
    func configure(with task: TaskData, inSection section: TaskSection) {
        let classNameDisplay = String(task.belongedClassName.dropFirst(6)) // "34395:卒業研究１(AD)" から "卒業研究１(AD)" を取得
        
        let truncatedClassNameDisplay: String
        if classNameDisplay.count > 6 {
            truncatedClassNameDisplay = String(classNameDisplay.prefix(5)) + "..."
        } else {
            truncatedClassNameDisplay = classNameDisplay
        }
        
        let truncatedTaskName: String
        if task.taskName.count > 6 {
            truncatedTaskName = String(task.taskName.prefix(5)) + "..."
        } else {
            truncatedTaskName = task.taskName
        }
        
        titleLabel.text = "\(truncatedClassNameDisplay) : \(truncatedTaskName)"
        
        // DateFormatterの設定
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" // 必要に応じてフォーマットを調整
        let dueDateString = dateFormatter.string(from: task.dueDate)
        deadlineLabel.text = dueDateString
        
        self.dueDate = task.dueDate // dueDate の設定
        
        // 「今日」のセクション以外ではカウントダウンラベルを非表示にする
        countdownLabel.isHidden = section != .today
        
        updateCountdown()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCountdown), userInfo: nil, repeats: true)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func updateCountdown() {
        guard let dueDate = dueDate else { return } // dueDate を参照するように変更
        let now = Date()
        let timeInterval = dueDate.timeIntervalSince(now)
        
        if timeInterval > 0 {
            let hours = Int(timeInterval) / 3600
            let minutes = Int(timeInterval) % 3600 / 60
            let seconds = Int(timeInterval) % 60
            countdownLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            countdownLabel.text = "Expired"
            stopTimer()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stopTimer()
        countdownLabel.text = nil
        dueDate = nil // dueDate のクリア
    }
}
