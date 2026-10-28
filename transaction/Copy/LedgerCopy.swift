import Foundation

struct LedgerCopy {
    var tabDashboard: String
    var tabTransactions: String
    var tabAccounts: String
    var tabMe: String
    var netAssets: String
    var monthSpend: String
    var monthIncome: String
    var monthBalance: String
    var monthlyBudget: String
    var budgetRemaining: String
    var safeToSpend: String
    var budgetOver: String
    var budgetUnset: String
    var budgetHint: String
    var budgetClear: String
    var categoryBudget: String
    var categoryBudgetHint: String
    var edit: String
    var done: String
    var save: String
    var cancel: String
    var add: String
    var back: String
    var toReview: String
    var markAllReviewed: String
    var checked: String
    var unchecked: String
    var monthCategories: String
    var report: String
    var spendChartEmpty: String
    var sampleBanner: String
    var sampleClear: String
    var paceWarning: String
    var spendPace: String
    var toTransactions: String
    var recurringTitle: String
    var recurringHint: String
    var recurringEmpty: String
    var scopeChipMine: String
    var scopeChipFamily: String
    var filter: String
    var filterScope: String
    var scopeMine: String
    var scopeFamily: String
    var time: String
    var today: String
    var thisMonth: String
    var customRange: String
    var rangeStart: String
    var rangeEnd: String
    var rangeTo: String
    var accounts: String
    var accountCountFormat: String
    var accountsEmpty: String
    var accountKindBank: String
    var accountKindCash: String
    var accountKindCard: String
    var accountKindOther: String
    var addAccount: String
    var editAccount: String
    var newAccount: String
    var accountName: String
    var accountNamePh: String
    var accountKindLabel: String
    var deleteAccount: String
    var accountBalance: String
    var accountDetailActivity: String
    var filterAccount: String
    var holdingsStock: String
    var holdingsFund: String
    var holdingsLabel: String
    var holdingKindStock: String
    var holdingKindEtf: String
    var holdingKindFund: String
    var addHolding: String
    var editHolding: String
    var newHolding: String
    var holdingKindLabel: String
    var holdingCode: String
    var holdingName: String
    var holdingQty: String
    var holdingCostPrice: String
    var holdingCostPricePh: String
    var holdingPrice: String
    var holdingPriceAsOf: String
    var holdingMarketValue: String
    var holdingPnl: String
    var deleteHolding: String
    var holdingDuplicate: String
    var holdingCodeStock: String
    var holdingNameStock: String
    var holdingCodeEtf: String
    var holdingNameEtf: String
    var holdingCodeFund: String
    var holdingNameFund: String
    var transfer: String
    var transferTitle: String
    var transferFrom: String
    var transferTo: String
    var transferCategory: String
    var accountPeriodNet: String
    var accountsTrend: String
    var accountsWindow7: String
    var accountsWindow30: String
    var accountPeriodDelta: String
    var transactions: String
    var searchPlaceholder: String
    var filterAll: String
    var filterOpen: String
    var filterDone: String
    var periodSpend: String
    var periodIncome: String
    var txEmpty: String
    var rankUp: String
    var rankDown: String
    var rankFlat: String
    var vsLastMonth: String
    var txViewList: String
    var txViewCalendar: String
    var weekdays: [String]
    var calendarWeek: [String]
    var me: String
    var categories: String
    var profileHint: String
    var privacy: String
    var language: String
    var currency: String
    var streakDays: String
    var streakToday: String
    var streakNone: String
    var privacyTitle: String
    var exportBackup: String
    var dataExportNote: String
    var exportBook: String
    var dataManage: String
    var clearBook: String
    var clearBookConfirm: String
    var clearBookDone: String
    var importData: String
    var importPaste: String
    var importDone: String
    var importInvalid: String
    var importFile: String
    var nicknameTitle: String
    var profileTitle: String
    var gender: String
    var genderFemale: String
    var genderMale: String
    var genderSecret: String
    var entryEdit: String
    var shared: String
    var entryNew: String
    var amount: String
    var name: String
    var namePh: String
    var category: String
    var date: String
    var account: String
    var titleSuggestions: String
    var newCategory: String
    var deleteEntry: String
    var todayWord: String
    var yesterdayWord: String
    var fundShare: String
    var stockShare: String
    var localeZh: String
    var localeEn: String
    var unsetName: String
    var unsetMark: String
    var familyTag: String
    var monthOverview: String
    var monthTitleFormat: String
    var monthUnitFormat: String
    var monthDayFormat: String
    var categoryAddedFormat: String
    var starterCategories: [String]
    var categoryHintAmounts: [String: Double]
    var localeID: String

    func monthTitle(now: Date = Date()) -> String {
        let month = LedgerDay.month(of: now)
        return fill(monthTitleFormat, [
            "month": String(month),
            "monthName": LedgerDay.monthName(month, wide: true, localeID: localeID),
            "overview": monthOverview,
        ])
    }

    func monthUnit(_ month: Int) -> String {
        fill(monthUnitFormat, [
            "month": String(month),
            "monthName": LedgerDay.monthName(month, wide: false, localeID: localeID),
        ])
    }

    func monthDay(_ month: Int, _ day: Int) -> String {
        fill(monthDayFormat, [
            "month": String(month),
            "monthName": LedgerDay.monthName(month, wide: false, localeID: localeID),
            "day": String(day),
        ])
    }

    func categoryAdded(_ name: String) -> String {
        fill(categoryAddedFormat, ["name": name])
    }

    func categoryHint(_ name: String) -> Double {
        categoryHintAmounts[name] ?? 500
    }

    func accountCountText(_ count: Int) -> String {
        fill(accountCountFormat, ["count": String(count)])
    }

    private func fill(_ template: String, _ values: [String: String]) -> String {
        values.reduce(template) { text, item in
            text.replacingOccurrences(of: "{\(item.key)}", with: item.value)
        }
    }

    func dayChip(_ iso: String, now: Date = Date()) -> String {
        let today = LedgerDay.today(now)
        let yesterday = LedgerDay.adding(days: -1, to: today)
        if iso == today { return todayWord }
        if iso == yesterday { return yesterdayWord }
        let parts = iso.split(separator: "-")
        guard parts.count == 3, let month = Int(parts[1]), let day = Int(parts[2]) else { return iso }
        return monthDay(month, day)
    }

    func periodChip(mode: PeriodMode, from: String, to: String, now: Date = Date()) -> String {
        switch mode {
        case .today: return today
        case .month: return monthUnit(LedgerDay.month(of: now))
        case .range:
            let start = min(from, to)
            let end = max(from, to)
            if start == end { return dayChip(start, now: now) }
            let s = start.split(separator: "-")
            let e = end.split(separator: "-")
            guard s.count == 3, e.count == 3 else { return "\(start)–\(end)" }
            return "\(Int(s[1]) ?? 0)/\(Int(s[2]) ?? 0)–\(Int(e[1]) ?? 0)/\(Int(e[2]) ?? 0)"
        }
    }

    func accountKind(_ kind: AccountKind) -> String {
        switch kind {
        case .bank: return accountKindBank
        case .cash: return accountKindCash
        case .card: return accountKindCard
        case .other: return accountKindOther
        }
    }

    func holdingKind(_ kind: HoldingKind) -> String {
        switch kind {
        case .stock: return holdingKindStock
        case .etf: return holdingKindEtf
        case .fund: return holdingKindFund
        }
    }

    func shareUnit(_ kind: HoldingKind) -> String {
        kind == .fund ? fundShare : stockShare
    }

    func genderName(_ gender: Gender) -> String {
        switch gender {
        case .female: return genderFemale
        case .male: return genderMale
        case .secret: return genderSecret
        }
    }

    static func resolve(_ locale: BookLocale) -> LedgerCopy {
        locale == .en ? englishCopy : chinese
    }
}

private let chinese = LedgerCopy(
    tabDashboard: "总览", tabTransactions: "流水", tabAccounts: "账户", tabMe: "我的",
    netAssets: "净资产", monthSpend: "本月支出", monthIncome: "收入", monthBalance: "本月结余",
    monthlyBudget: "本月预算", budgetRemaining: "剩余", safeToSpend: "今日还可花", budgetOver: "已超支",
    budgetUnset: "设置预算", budgetHint: "设置本月支出上限，便于在总览查看剩余额度", budgetClear: "清除预算",
    categoryBudget: "分类预算", categoryBudgetHint: "可为各分类单独设上限，留空表示不设限",
    edit: "编辑", done: "完成", save: "保存", cancel: "取消", add: "添加", back: "返回",
    toReview: "待核对", markAllReviewed: "全部核对", checked: "已核对", unchecked: "未核对",
    monthCategories: "本月分类", report: "报表", spendChartEmpty: "记一笔后，这里会出现本月曲线。",
    sampleBanner: "示例账可点开修改", sampleClear: "清空", paceWarning: "按当前节奏，本月可能超预算",
    spendPace: "本月支出节奏", toTransactions: "流水",
    recurringTitle: "固定扣款", recurringHint: "相同名称与金额的重复支出", recurringEmpty: "同一名称和金额记满两笔后，会出现在这里。",
    scopeChipMine: "我的", scopeChipFamily: "家庭", filter: "筛选", filterScope: "范围",
    scopeMine: "只看我的", scopeFamily: "家庭", time: "时间", today: "今日", thisMonth: "本月",
    customRange: "自定义", rangeStart: "开始", rangeEnd: "结束", rangeTo: "至",
    accounts: "账户", accountCountFormat: "{count} 个", accountsEmpty: "添加第一个账户，填入真实余额。",
    accountKindBank: "银行卡", accountKindCash: "现金", accountKindCard: "信用卡", accountKindOther: "其他",
    addAccount: "添加账户", editAccount: "编辑账户", newAccount: "添加账户",
    accountName: "账户名称", accountNamePh: "Visa、现金、工资卡", accountKindLabel: "账户类型",
    deleteAccount: "删除账户及流水", accountBalance: "当前余额", accountDetailActivity: "查看流水", filterAccount: "账户",
    holdingsStock: "股票", holdingsFund: "基金", holdingsLabel: "持仓", holdingKindStock: "股票", holdingKindEtf: "ETF", holdingKindFund: "基金",
    addHolding: "添加持仓", editHolding: "编辑持仓", newHolding: "添加持仓", holdingKindLabel: "标的类型",
    holdingCode: "代码", holdingName: "名称", holdingQty: "数量/份额", holdingCostPrice: "成本价",
    holdingCostPricePh: "每股或每份成本", holdingPrice: "现价", holdingPriceAsOf: "现价日期",
    holdingMarketValue: "市值", holdingPnl: "浮动盈亏", deleteHolding: "删除持仓", holdingDuplicate: "已有相同代码的持仓",
    holdingCodeStock: "NVDA", holdingNameStock: "英伟达", holdingCodeEtf: "SPY", holdingNameEtf: "标普500",
    holdingCodeFund: "VFIAX", holdingNameFund: "先锋500",
    transfer: "转账", transferTitle: "账户转账", transferFrom: "转出", transferTo: "转入", transferCategory: "转账",
    accountPeriodNet: "区间净流入", accountsTrend: "净资产走势", accountsWindow7: "7 天", accountsWindow30: "1 月",
    accountPeriodDelta: "区间变动",
    transactions: "流水", searchPlaceholder: "搜名称、分类或账户", filterAll: "全部", filterOpen: "未核对", filterDone: "已核对",
    periodSpend: "支出", periodIncome: "收入", txEmpty: "这个时间段里没有匹配的流水。",
    rankUp: "升", rankDown: "降", rankFlat: "平", vsLastMonth: "较上月",
    txViewList: "列表", txViewCalendar: "日历",
    weekdays: ["周日", "周一", "周二", "周三", "周四", "周五", "周六"],
    calendarWeek: ["日", "一", "二", "三", "四", "五", "六"],
    me: "我的", categories: "分类", profileHint: "点击填写昵称", privacy: "隐私协议", language: "语言", currency: "货币",
    streakDays: "连续记账", streakToday: "今日已记", streakNone: "今天还没记", privacyTitle: "隐私协议",
    exportBackup: "导出 JSON 备份", dataExportNote: "账户、流水、持仓和预算都会写进这一份 JSON。", exportBook: "导出账本", dataManage: "数据管理", clearBook: "清除数据",
    clearBookConfirm: "清除后，账户、流水、持仓和预算都会去掉，并且不会再填回示例。", clearBookDone: "账本数据已清除",
    importData: "导入账本", importPaste: "粘贴导出的 JSON", importDone: "导入成功", importInvalid: "JSON 无效，请检查内容",
    importFile: "选择 JSON 文件",
    nicknameTitle: "昵称", profileTitle: "昵称与性别", gender: "性别", genderFemale: "女", genderMale: "男", genderSecret: "保密",
    entryEdit: "改一笔", shared: "记入家庭", entryNew: "记一笔", amount: "金额", name: "名称", namePh: "午饭、工资、房租",
    category: "分类", date: "日期", account: "账户", titleSuggestions: "常用备注", newCategory: "新分类", deleteEntry: "删除",
    todayWord: "今天", yesterdayWord: "昨天", fundShare: "份", stockShare: "股",
    localeZh: "中文", localeEn: "English", unsetName: "未设置", unsetMark: "未", familyTag: "家庭",
    monthOverview: "总览",
    monthTitleFormat: "{month}月{overview}", monthUnitFormat: "{month}月", monthDayFormat: "{month}月{day}日",
    categoryAddedFormat: "已添加分类：{name}",
    starterCategories: ["餐饮", "交通", "日用", "居住", "收入", "订阅", "娱乐"],
    categoryHintAmounts: ["餐饮": 1800, "交通": 400, "日用": 600, "居住": 3200, "收入": 8000, "订阅": 200, "娱乐": 500],
    localeID: "zh_CN"
)

private let englishCopy = LedgerCopy(
    tabDashboard: "Overview", tabTransactions: "Activity", tabAccounts: "Accounts", tabMe: "Me",
    netAssets: "Net worth", monthSpend: "Spent", monthIncome: "Income", monthBalance: "Month balance",
    monthlyBudget: "Monthly budget", budgetRemaining: "Left", safeToSpend: "Safe today", budgetOver: "Over budget",
    budgetUnset: "Set budget", budgetHint: "Cap this month’s spending", budgetClear: "Clear budget",
    categoryBudget: "Category caps", categoryBudgetHint: "Set a cap per category; leave blank for no limit",
    edit: "Edit", done: "Done", save: "Save", cancel: "Cancel", add: "Add", back: "Back",
    toReview: "To review", markAllReviewed: "Mark all reviewed", checked: "Reviewed", unchecked: "Review",
    monthCategories: "Categories", report: "Report", spendChartEmpty: "Add a transaction to see this month’s curve.",
    sampleBanner: "Sample entries can be edited", sampleClear: "Clear",
    paceWarning: "At this pace you may exceed budget", spendPace: "Spending pace", toTransactions: "Activity",
    recurringTitle: "Recurring", recurringHint: "Same title & amount repeating",
    recurringEmpty: "Shows here after two expenses with the same title and amount.",
    scopeChipMine: "Mine", scopeChipFamily: "Household", filter: "Filter", filterScope: "Scope",
    scopeMine: "Mine only", scopeFamily: "Household", time: "Time", today: "Today", thisMonth: "This month",
    customRange: "Custom", rangeStart: "Start", rangeEnd: "End", rangeTo: "to",
    accounts: "Accounts", accountCountFormat: "{count}", accountsEmpty: "Add your first account with the real balance.",
    accountKindBank: "Bank", accountKindCash: "Cash", accountKindCard: "Credit", accountKindOther: "Other",
    addAccount: "Add account", editAccount: "Edit account", newAccount: "Add account",
    accountName: "Account name", accountNamePh: "Visa, Cash, Payroll", accountKindLabel: "Account type",
    deleteAccount: "Delete account & transactions", accountBalance: "Current balance",
    accountDetailActivity: "View activity", filterAccount: "Account",
    holdingsStock: "Stocks", holdingsFund: "Funds", holdingsLabel: "Holdings", holdingKindStock: "Stock", holdingKindEtf: "ETF", holdingKindFund: "Fund",
    addHolding: "Add holding", editHolding: "Edit holding", newHolding: "Add holding", holdingKindLabel: "Type",
    holdingCode: "Symbol", holdingName: "Name", holdingQty: "Shares / units", holdingCostPrice: "Cost per share/unit",
    holdingCostPricePh: "Per share or unit", holdingPrice: "Price", holdingPriceAsOf: "Price date",
    holdingMarketValue: "Market value", holdingPnl: "Unrealized P/L", deleteHolding: "Delete holding",
    holdingDuplicate: "A holding with this symbol already exists",
    holdingCodeStock: "NVDA", holdingNameStock: "NVIDIA", holdingCodeEtf: "SPY", holdingNameEtf: "S&P 500",
    holdingCodeFund: "VFIAX", holdingNameFund: "Vanguard 500",
    transfer: "Transfer", transferTitle: "Transfer", transferFrom: "From", transferTo: "To", transferCategory: "Transfer",
    accountPeriodNet: "Net inflow", accountsTrend: "Net worth trend", accountsWindow7: "7D", accountsWindow30: "1M",
    accountPeriodDelta: "Period change",
    transactions: "Activity", searchPlaceholder: "Search name, category, or account",
    filterAll: "All", filterOpen: "Review", filterDone: "Reviewed",
    periodSpend: "Spent", periodIncome: "Income", txEmpty: "No transactions match this period.",
    rankUp: "up", rankDown: "down", rankFlat: "flat", vsLastMonth: "vs last mo.",
    txViewList: "List", txViewCalendar: "Calendar",
    weekdays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
    calendarWeek: ["S", "M", "T", "W", "T", "F", "S"],
    me: "Me", categories: "Categories", profileHint: "Tap to set nickname", privacy: "Privacy",
    language: "Language", currency: "Currency",
    streakDays: "Streak", streakToday: "Logged today", streakNone: "Not logged today", privacyTitle: "Privacy",
    exportBackup: "Export JSON backup", dataExportNote: "Accounts, activity, holdings and budgets go into this JSON.", exportBook: "Export book", dataManage: "Data", clearBook: "Clear data",
    clearBookConfirm: "Accounts, transactions, holdings and budgets will be removed, and the sample book will not come back.",
    clearBookDone: "Book data cleared",
    importData: "Import book", importPaste: "Paste exported JSON", importDone: "Import complete",
    importInvalid: "Invalid JSON. Check the contents.", importFile: "Choose JSON file",
    nicknameTitle: "Nickname", profileTitle: "Nickname & gender", gender: "Gender",
    genderFemale: "Female", genderMale: "Male", genderSecret: "Private",
    entryEdit: "Edit transaction", shared: "Household", entryNew: "Add transaction",
    amount: "Amount", name: "Name", namePh: "Lunch, salary, rent", category: "Category", date: "Date", account: "Account",
    titleSuggestions: "Recent titles", newCategory: "New category", deleteEntry: "Delete",
    todayWord: "Today", yesterdayWord: "Yesterday", fundShare: "units", stockShare: "shares",
    localeZh: "中文", localeEn: "English", unsetName: "Not set", unsetMark: "—", familyTag: "Household",
    monthOverview: "Overview",
    monthTitleFormat: "{monthName} {overview}", monthUnitFormat: "{monthName}", monthDayFormat: "{monthName} {day}",
    categoryAddedFormat: "Added category: {name}",
    starterCategories: ["Dining", "Transit", "Daily", "Housing", "Income", "Subscriptions", "Entertainment"],
    categoryHintAmounts: ["Dining": 1800, "Transit": 400, "Daily": 600, "Housing": 3200, "Income": 8000, "Subscriptions": 200, "Entertainment": 500],
    localeID: "en_US"
)
