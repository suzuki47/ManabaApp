//
//  UnregisteredClassesPopupViewController.swift
//  Ritsumeikan
//
//  Created by 鈴木悠太 on 2024/07/09.
//

import UIKit

protocol UnregisteredClassesPopupDelegate: AnyObject {
    func didSelectClass(_ classInfo: ClassData, from controller: UnregisteredClassesPopupViewController)
}

class UnregisteredClassesPopupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var tableView: UITableView!
    var classesToRegister: [ClassData] = []
    weak var delegate: UnregisteredClassesPopupDelegate?
    var selectedClass: ClassData?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true

        setupTableView()
        setupTitleLabel()

        preferredContentSize = CGSize(width: 300, height: 400) // ポップアップのサイズを指定
    }

    private func setupTitleLabel() {
        let titleLabel = UILabel()
        titleLabel.text = "未登録の授業があります"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func setupTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ClassCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return classesToRegister.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ClassCell", for: indexPath)
        let classInfo = classesToRegister[indexPath.row]
        cell.textLabel?.text = classInfo.name
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedClass = classesToRegister[indexPath.row]
        delegate?.didSelectClass(selectedClass, from: self)
    }
}
