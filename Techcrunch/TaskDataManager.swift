import Foundation
import CoreData

class TaskDataManager: DataManager {
    private var notificationAdapterBag: [Int: NotificationCustomAdapter] = [:]
    
    // DateFormatterをクラスのプロパティとして宣言し、クロージャを使って初期化します。
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    // イニシャライザ内では、スーパークラスのイニシャライザを呼び出す前に
    // 自身のプロパティが初期化されている必要があるため、formatterはここで初期化しません。
    override init(dataName: String, context: NSManagedObjectContext) {
        // スーパークラスのイニシャライザを呼び出します。
        super.init(dataName: dataName, context: context)
        // formatterの初期化はクラスのプロパティとして直接行っているため、ここで再び行う必要はありません。
    }

    /*
    func addAdapter(num: Int, adapter: NotificationCustomAdapter) {
        notificationAdapterBag[num] = adapter
    }

    func removeAdapter(num: Int) {
        notificationAdapterBag.removeValue(forKey: num)
    }
     */

    func setTaskData() {
        loadData()
        //getTaskDataFromManaba()
        reorderTaskData()
    }

    func addTaskData(title: String, deadLine: String) {
        // DateFormatterを使用してStringをDateに変換
        if let deadLineDate = formatter.date(from: deadLine) {
            let defaultTiming = Calendar.current.date(byAdding: .hour, value: -1, to: deadLineDate)
            print("\(deadLine)の一時間前は\(String(describing: defaultTiming))です。AddTaskCustomDialog 41")
            addData(title: title, subTitle: deadLine, notificationTimings: [defaultTiming].compactMap { $0 })
            print("デフォルトの通知タイミングを設定できました。AddTaskCustomDialog 43")
        } else {
            print("デフォルトの通知タイミングを設定できませんでした。AddTaskCustomDialog 46")
            addData(title: title, subTitle: deadLine)
        }
        reorderTaskData()
    }

    func removeTaskData(at index: Int) {
        // superクラスのremoveDataを呼び出し
        super.removeData(at: index)
        //removeAdapter(num: index)
        reorderTaskData()
    }

    func isExist(name: String) -> Bool {
        return !dataList.contains { $0.title == name }
    }

    func reorderTaskData() {
        dataList.sort { (data1, data2) -> Bool in
            guard let subtitle1 = data1.subtitle, let date1 = formatter.date(from: subtitle1),
                  let subtitle2 = data2.subtitle, let date2 = formatter.date(from: subtitle2) else {
                return false
            }
            return date1 < date2
        }
    }

    //TODO: 渡されたタプルのデータをここでaddDataを使って，dataListに追加する(isExistで重複回避）
    
    func getTaskDataFromManaba(cookieValue: String) {
        let htmlParser = ManabaScraper(cookiestring: cookieValue)
        Task {
            do {
                let headers = try await htmlParser.parse()
                //self.headers = headers
            }catch {
                print("Failed: \(error)")
            }
        }           
    }
    // 以下、他のメソッドの定義...
    /*
    // requestScrapingメソッドのプレースホルダー（具体的な実装が必要です）
    func requestScraping() throws -> [String] {
        // スクレーピングのコードをここに実装します。
        return []
    }
     */
}


// その他の補助クラスや関数の定義...
