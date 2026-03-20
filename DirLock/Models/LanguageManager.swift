import SwiftUI

enum AppLanguage: String {
    case chinese = "zh"
    case english = "en"
}

class LanguageManager: ObservableObject {
    @AppStorage("app.language") var language: String = AppLanguage.english.rawValue

    var isChinese: Bool { language == AppLanguage.chinese.rawValue }

    func toggle() {
        language = isChinese ? AppLanguage.english.rawValue : AppLanguage.chinese.rawValue
    }

    func s(_ zh: String, _ en: String) -> String {
        isChinese ? zh : en
    }
}
