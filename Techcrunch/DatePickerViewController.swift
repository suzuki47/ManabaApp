import UIKit
import UserNotifications

protocol DatePickerViewControllerDelegate: AnyObject {
    func didPickDate(date: Date)
}

class DatePickerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    weak var delegate: DatePickerViewControllerDelegate?
    
    private let navigationBar = UINavigationBar()
    private let datePicker = UIDatePicker()
    private let timePicker = UIPickerView()
    private let timeLabel = UILabel()
    
    private var selectedDate = Date()
    private var selectedHour = 12
    private var selectedMinute = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        setupDatePicker()
        setupTimePicker()
        setupTimeLabel()
        setupPresentationController()
    }
    
    private func setupView() {
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
    }
    
    private func setupNavigationBar() {
        let navigationItem = UINavigationItem(title: "カレンダー")
        
        let cancelButton = UIBarButtonItem(title: "キャンセル", style: .plain, target: self, action: #selector(cancelButtonTapped))
        navigationItem.leftBarButtonItem = cancelButton
        
        let saveButton = UIBarButtonItem(title: "保存", style: .plain, target: self, action: #selector(saveButtonTapped))
        navigationItem.rightBarButtonItem = saveButton
        
        navigationBar.items = [navigationItem]
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        
        // ナビゲーションバーを安全エリア内に配置
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupDatePicker() {
        datePicker.datePickerMode = .date
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 10),
            datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            datePicker.heightAnchor.constraint(equalToConstant: 300)
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
    
    private func setupPresentationController() {
        if let presentationController = presentationController as? UISheetPresentationController {
            presentationController.detents = [.medium(), .large()]
            presentationController.prefersGrabberVisible = true
        }
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
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
            delegate?.didPickDate(date: date)
        }
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 24
        } else {
            return 60
        }
    }
    
    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return String(format: "%02d", row)
        } else {
            return String(format: "%02d", row)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            selectedHour = row
        } else {
            selectedMinute = row
        }
    }
}

/*import UIKit

protocol DatePickerViewControllerDelegate: AnyObject {
    func didPickDate(date: Date)
}

class DatePickerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UICalendarViewDelegate {
    
    weak var delegate: DatePickerViewControllerDelegate?
    
    private let navigationBar = UINavigationBar()
    private let calendarView = UICalendarView()
    private let timePicker = UIPickerView()
    private let timeLabel = UILabel()
    
    private var selectedDate = Date()
    private var selectedHour = 12
    private var selectedMinute = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        setupCalendarView()
        setupTimePicker()
        setupTimeLabel()
        setupPresentationController()
    }
    
    private func setupView() {
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
    }
    
    private func setupNavigationBar() {
        let navigationItem = UINavigationItem(title: "カレンダー")
        
        let cancelButton = UIBarButtonItem(title: "キャンセル", style: .plain, target: self, action: #selector(cancelButtonTapped))
        navigationItem.leftBarButtonItem = cancelButton
        
        let saveButton = UIBarButtonItem(title: "保存", style: .plain, target: self, action: #selector(saveButtonTapped))
        navigationItem.rightBarButtonItem = saveButton
        
        navigationBar.items = [navigationItem]
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupCalendarView() {
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.delegate = self
        view.addSubview(calendarView)
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 10),
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
    
    private func setupPresentationController() {
        if let presentationController = presentationController as? UISheetPresentationController {
            presentationController.detents = [.medium(), .large()]
            presentationController.prefersGrabberVisible = true
        }
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
            delegate?.didPickDate(date: date)
        }
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 24
        } else {
            return 60
        }
    }
    
    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return String(format: "%02d", row)
        } else {
            return String(format: "%02d", row)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            selectedHour = row
        } else {
            selectedMinute = row
        }
    }
    
    // MARK: - UICalendarViewDelegate
    
    func calendarView(_ calendarView: UICalendarView, didChangeDateSelection selectedDates: Set<DateComponents>) {
        if let dateComponents = selectedDates.first,
           let date = Calendar.current.date(from: dateComponents) {
            selectedDate = date
        }
    }
}*/
