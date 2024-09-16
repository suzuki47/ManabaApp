import UIKit
import FSCalendar

protocol DatePickerViewControllerDelegate: AnyObject {
    func didPickDate(date: Date, forTaskId taskId: Int)
}

class DatePickerViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource, UIPickerViewDelegate, UIPickerViewDataSource {

    weak var delegate: DatePickerViewControllerDelegate?
    var taskId: Int?

    private let navigationBar = UINavigationBar()
    private let calendarView = FSCalendar()
    private let timePicker = UIPickerView()
    private let timeLabel = UILabel()
    private let notificationTimeLabel = UILabel()

    private var selectedDate = Date()
    private var selectedHour = 12
    private var selectedMinute = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        setupNotificationTimeLabel()
        setupCalendarView()
        setupTimePicker()
        setupTimeLabel()
        setupPresentationController()
        
        initializeTimePicker()
        updateNotificationTimeLabel()
    }

    private func setupView() {
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
    }

    private func setupNavigationBar() {
        let navigationItem = UINavigationItem(title: "日時選択")
        
        let cancelButton = UIBarButtonItem(title: "キャンセル", style: .plain, target: self, action: #selector(cancelButtonTapped))
        navigationItem.leftBarButtonItem = cancelButton
        
        let saveButton = UIBarButtonItem(title: "保存", style: .plain, target: self, action: #selector(saveButtonTapped))
        navigationItem.rightBarButtonItem = saveButton
        
        navigationBar.items = [navigationItem]
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupNotificationTimeLabel() {
        notificationTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        notificationTimeLabel.text = "🕐通知時刻：\(formattedDateAndTime())"
        notificationTimeLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        notificationTimeLabel.textAlignment = .center
        view.addSubview(notificationTimeLabel)
        
        NSLayoutConstraint.activate([
            notificationTimeLabel.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 10),
            notificationTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            notificationTimeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
    }

    private func setupCalendarView() {
        calendarView.delegate = self
        calendarView.dataSource = self
        calendarView.appearance.headerTitleFont = UIFont.systemFont(ofSize: 18)
        calendarView.appearance.headerDateFormat = "yyyy年MM月"
        calendarView.appearance.headerTitleColor = UIColor.black
        calendarView.appearance.headerMinimumDissolvedAlpha = 0.0
        
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendarView)
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: notificationTimeLabel.bottomAnchor, constant: 10),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            calendarView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }

    private func setupTimePicker() {
        timePicker.delegate = self
        timePicker.dataSource = self
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timePicker)
        
        NSLayoutConstraint.activate([
            timePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timePicker.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            timePicker.heightAnchor.constraint(equalToConstant: 100)
        ])
    }

    private func setupTimeLabel() {
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.text = "時刻選択"
        timeLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        timeLabel.textAlignment = .center
        view.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            timeLabel.bottomAnchor.constraint(equalTo: timePicker.topAnchor, constant: -10),
            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    /*
    private func setupPresentationController() {
        if let presentationController = presentationController as? UISheetPresentationController {
            presentationController.detents = [.medium(), .large()]
            presentationController.prefersGrabberVisible = true
        }
    }*/
    
    private func setupPresentationController() {
        if let presentationController = presentationController as? UISheetPresentationController {
            if #available(iOS 16.0, *) {
                // 画面の70％を覆うカスタムデタントを定義
                let customDetent = UISheetPresentationController.Detent.custom(identifier: .medium) { context in
                    return context.maximumDetentValue * 0.75
                }
                presentationController.detents = [customDetent]
                presentationController.preferredCornerRadius = 20
                presentationController.prefersGrabberVisible = true
            } else {
                // iOS 16未満のバージョンのフォールバック
                presentationController.detents = [.medium(), .large()]
                presentationController.prefersGrabberVisible = true
            }
        }
    }

    private func initializeTimePicker() {
        timePicker.selectRow(selectedHour, inComponent: 0, animated: false)
        timePicker.selectRow(selectedMinute, inComponent: 1, animated: false)
    }

    private func updateNotificationTimeLabel() {
        notificationTimeLabel.text = "🕐通知時刻：\(formattedDateAndTime())"
    }

    private func formattedDateAndTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = selectedHour
        components.minute = selectedMinute
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return ""
    }

    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func saveButtonTapped() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = selectedHour
        components.minute = selectedMinute
        if let date = calendar.date(from: components) {
            print("DatePickerViewController: 保存ボタンが押されました。選択された日時: \(date), タスクID: \(taskId)")
            
            if let taskId = taskId {
                delegate?.didPickDate(date: date, forTaskId: taskId)
            } else {
                print("Error: taskId is nil")
            }
        }
        dismiss(animated: true, completion: nil)
    }

    // MARK: - FSCalendarDelegate
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        selectedDate = date
        updateNotificationTimeLabel()
    }

    // MARK: - UIPickerViewDataSource
    
    @objc func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    @objc func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 24
        } else {
            return 60
        }
    }
    
    // MARK: - UIPickerViewDelegate
    
    @objc func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return String(format: "%02d", row)
        } else {
            return String(format: "%02d", row)
        }
    }
    
    @objc func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            selectedHour = row
        } else {
            selectedMinute = row
        }
        updateNotificationTimeLabel()
    }
}
