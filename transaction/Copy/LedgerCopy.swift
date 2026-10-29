//
//  LedgerCopy.swift
//  transaction
//
//  Created by Lzl on 2026/10/6.
//

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
    var countBudget: String
    var countWorth: String
    var worthLeftOut: String
    var hideAmounts: String
    var hideAmountsOn: String
    var hideAmountsOff: String
    var repeatDay: String
    var repeatPosted: String
    var repeatWaiting: String
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
    var yearReport: String
    var yearSpend: String
    var yearIncome: String
    var yearBalance: String
    var savingGoals: String
    var savingTarget: String
    var savingSaved: String
    var claimTitle: String
    var claimMark: String
    var claimPaid: String
    var claimDone: String
    var claimEmpty: String
    var claimBackFormat: String
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
    var accountGuide: String
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
    var accountMix: String
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
    var periodBalance: String
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
    var meLedger: String
    var meDisplay: String
    var meData: String
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
    var importConfirm: String
    var importFile: String
    var nicknameTitle: String
    var avatarTitle: String
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
    var calendarTitleFormat: String
    var monthPrevious: String
    var monthNext: String
    var categoryAddedFormat: String
    var starterCategories: [String]
    var categoryHintAmounts: [String: Double]
    var cardStatementDay: String
    var cardDueDay: String
    var cardBill: String
    var refundMark: String
    var refundDone: String
    var refundBackFormat: String
    var splitMark: String
    var splitAmount: String
    var goalAttach: String
    var goalNone: String
    var goalDeposit: String
    var goalFrom: String
    var goalTo: String
    var archiveAccount: String
    var restoreAccount: String
    var archivedTitle: String
    var removedTitle: String
    var removedRestore: String
    var removedEmpty: String
    var lockOnOpen: String
    var lockTitle: String
    var lockRetry: String
    var lockOnWord: String
    var lockOffWord: String
    var amountSolve: String
    var worthGrowth: String
    var worthPastWeek: String
    var worthPastMonth: String
    var worthPastQuarter: String
    var worthPastYear: String
    var worthPastAll: String
    var worthSpanWeek: String
    var worthSpanMonth: String
    var worthSpanQuarter: String
    var worthSpanYear: String
    var worthSpanAll: String
    var localeID: String
    var billStatementFormat: String
    var billDueFormat: String
    var statsMonthly: String
    var statsAnnual: String
    var statsOut: String
    var statsIn: String
    var statsOther: String
    var statsCountFormat: String
    var statsCompareMonthFormat: String
    var statsCompareYearFormat: String
    var statsComposeFormat: String
    var statsRankFormat: String
    var statsEmpty: String
    var statsThisMonth: String
    var statsThisYear: String
    var statsPrev: String
    var statsNext: String
    var yearClassify: String
    var yearCompare: String
    var yearTopFormat: String
    var yearAccountOut: String
    var yearAccountIn: String
    var yearMostFormat: String
    var yearAverageFormat: String
    var yearCountFormat: String
    var yearExpand: String
    var yearFold: String
    var yearRefunded: String
    var yearPrev: String
    var yearNext: String
    var accountMonthFlow: String

    func monthTitle(now: Date = Date()) -> String {
        let month = LedgerDay.month(of: now)
        return fill(monthTitleFormat, [
            "month": String(month),
            "monthName": LedgerDay.monthName(month, wide: true, localeID: localeID),
            "overview": monthOverview,
        ])
    }

    func calendarTitle(year: Int, month: Int) -> String {
        fill(calendarTitleFormat, [
            "year": String(year),
            "month": String(month),
            "monthName": LedgerDay.monthName(month, wide: true, localeID: localeID),
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

    func claimBack(_ title: String) -> String {
        fill(claimBackFormat, ["title": title])
    }

    func refundBack(_ title: String) -> String {
        fill(refundBackFormat, ["title": title])
    }

    func billStatement(_ name: String, amount: String) -> String {
        fill(billStatementFormat, ["name": name, "amount": amount])
    }

    func billDue(_ name: String, amount: String) -> String {
        fill(billDueFormat, ["name": name, "amount": amount])
    }

    func statsKindName(_ kind: String) -> String {
        switch kind {
        case "in": return statsIn
        case "other": return statsOther
        default: return statsOut
        }
    }

    func statsCount(_ count: Int, kind: String) -> String {
        fill(statsCountFormat, ["count": String(count), "kind": kind])
    }

    func statsCompare(annual: Bool, kind: String) -> String {
        fill(annual ? statsCompareYearFormat : statsCompareMonthFormat, ["kind": kind])
    }

    func statsCompose(_ when: String, kind: String) -> String {
        fill(statsComposeFormat, ["when": when, "kind": kind])
    }

    func statsRank(_ when: String, kind: String) -> String {
        fill(statsRankFormat, ["when": when, "kind": kind])
    }

    func yearTop(_ kind: String) -> String {
        fill(yearTopFormat, ["kind": kind])
    }

    func yearAccount(out: Bool) -> String {
        out ? yearAccountOut : yearAccountIn
    }

    func yearMost(_ when: String) -> String {
        fill(yearMostFormat, ["when": when])
    }

    func yearAverage(_ kind: String) -> String {
        fill(yearAverageFormat, ["kind": kind])
    }

    func yearCount(_ count: Int) -> String {
        fill(yearCountFormat, ["count": String(count)])
    }

    func worthPast(_ span: WorthSpan) -> String {
        switch span {
        case .week: return worthPastWeek
        case .month: return worthPastMonth
        case .quarter: return worthPastQuarter
        case .year: return worthPastYear
        case .all: return worthPastAll
        }
    }

    func worthSpanTitle(_ span: WorthSpan) -> String {
        switch span {
        case .week: return worthSpanWeek
        case .month: return worthSpanMonth
        case .quarter: return worthSpanQuarter
        case .year: return worthSpanYear
        case .all: return worthSpanAll
        }
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

    func genderName(_ gender: Gender) -> String {
        switch gender {
        case .female: return genderFemale
        case .male: return genderMale
        case .secret: return genderSecret
        }
    }

    static func resolve(_ locale: BookLocale) -> LedgerCopy {
        switch locale {
        case .zh: return chinese
        case .zhHant: return traditionalCopy
        case .en: return englishCopy
        case .ja: return japaneseCopy
        case .ko: return koreanCopy
        case .es: return spanishCopy
        case .pt: return portugueseCopy
        case .fr: return frenchCopy
        case .de: return germanCopy
        case .it: return italianCopy
        }
    }
}

private let chinese = LedgerCopy(
    tabDashboard: "总览", tabTransactions: "流水", tabAccounts: "账户", tabMe: "我的",
    netAssets: "净资产", monthSpend: "本月支出", monthIncome: "收入", monthBalance: "本月结余",
    monthlyBudget: "本月预算", budgetRemaining: "剩余", safeToSpend: "今日还可花", budgetOver: "已超支",
    budgetUnset: "设置预算", budgetHint: "设置本月支出上限，便于在总览查看剩余额度", budgetClear: "清除预算",
    countBudget: "计入预算", countWorth: "计入净资产", worthLeftOut: "不计入净资产",
    hideAmounts: "隐藏金额", hideAmountsOn: "已隐藏", hideAmountsOff: "显示中",
    repeatDay: "每月几号", repeatPosted: "本月已记", repeatWaiting: "本月待记",
    categoryBudget: "分类预算", categoryBudgetHint: "可为各分类单独设上限，留空表示不设限",
    edit: "编辑", done: "完成", save: "保存", cancel: "取消", add: "添加", back: "返回",
    toReview: "待核对", markAllReviewed: "全部核对", checked: "已核对", unchecked: "未核对",
    monthCategories: "本月分类", report: "报表",
    yearReport: "年报", yearSpend: "今年支出", yearIncome: "今年收入", yearBalance: "今年结余",
    savingGoals: "存钱目标", savingTarget: "目标金额", savingSaved: "已经存下",
    claimTitle: "待报销", claimMark: "待报销", claimPaid: "报销到账", claimDone: "已报销",
    claimEmpty: "把一笔支出标成待报销。到账后点这里，同样的金额会记回账户。",
    claimBackFormat: "{title} 报销",
    spendChartEmpty: "记一笔后，这里会出现本月曲线。",
    sampleBanner: "示例账可点开修改", sampleClear: "清空", paceWarning: "按当前节奏，本月可能超预算",
    spendPace: "本月支出节奏", toTransactions: "流水",
    recurringTitle: "周期记账", recurringHint: "到日子自动记入", recurringEmpty: "设好房租或工资，到了每月这一天会自动记一笔。",
    scopeChipMine: "我的", scopeChipFamily: "家庭", filter: "筛选", filterScope: "范围",
    scopeMine: "只看我的", scopeFamily: "家庭", time: "时间", today: "今日", thisMonth: "本月",
    customRange: "自定义", rangeStart: "开始", rangeEnd: "结束", rangeTo: "至",
    accounts: "账户", accountCountFormat: "{count} 个", accountsEmpty: "添加第一个账户，填入真实余额。",
    accountKindBank: "银行卡", accountKindCash: "现金", accountKindCard: "信用卡", accountKindOther: "其他",
    addAccount: "添加账户", accountGuide: "还没有自己的账户，去添加", editAccount: "编辑账户", newAccount: "添加账户",
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
    accountPeriodNet: "区间净流入", accountsTrend: "净资产走势", accountMix: "构成", accountsWindow7: "7 天", accountsWindow30: "1 月",
    accountPeriodDelta: "区间变动",
    transactions: "流水", searchPlaceholder: "搜名称、分类或账户", filterAll: "全部", filterOpen: "未核对", filterDone: "已核对",
    periodSpend: "支出", periodIncome: "收入", periodBalance: "结余", txEmpty: "这个时间段里没有匹配的流水。",
    rankUp: "升", rankDown: "降", rankFlat: "平", vsLastMonth: "较上月",
    txViewList: "列表", txViewCalendar: "日历",
    weekdays: ["周日", "周一", "周二", "周三", "周四", "周五", "周六"],
    calendarWeek: ["日", "一", "二", "三", "四", "五", "六"],
    me: "我的", meLedger: "账本", meDisplay: "显示", meData: "数据", categories: "分类", profileHint: "点击填写昵称", privacy: "隐私协议", language: "语言", currency: "货币",
    streakDays: "连续记账", streakToday: "今日已记", streakNone: "今天还没记", privacyTitle: "隐私协议",
    exportBackup: "导出 JSON 备份", dataExportNote: "账户、流水和预算都会写进这一份 JSON。", exportBook: "导出账本", dataManage: "数据管理", clearBook: "清除数据",
    clearBookConfirm: "清除后，账户、流水和预算都会去掉，并且不会再填回示例。", clearBookDone: "账本数据已清除",
    importData: "导入账本", importPaste: "粘贴导出的 JSON", importDone: "导入成功", importInvalid: "JSON 无效，请检查内容",
    importConfirm: "这份文件会换掉现在的账本，包括账户和流水。",
    importFile: "选择 JSON 文件",
    nicknameTitle: "昵称", avatarTitle: "头像", profileTitle: "昵称与性别", gender: "性别", genderFemale: "女", genderMale: "男", genderSecret: "保密",
    entryEdit: "改一笔", shared: "记入家庭", entryNew: "记一笔", amount: "金额", name: "名称", namePh: "午饭、工资、房租",
    category: "分类", date: "日期", account: "账户", titleSuggestions: "常用备注", newCategory: "新分类", deleteEntry: "删除",
    todayWord: "今天", yesterdayWord: "昨天", fundShare: "份", stockShare: "股",
    localeZh: "中文", localeEn: "English", unsetName: "未设置", unsetMark: "未", familyTag: "家庭",
    monthOverview: "总览",
    monthTitleFormat: "{month}月{overview}", monthUnitFormat: "{month}月", monthDayFormat: "{month}月{day}日",
    calendarTitleFormat: "{year}年{month}月", monthPrevious: "上个月", monthNext: "下个月",
    categoryAddedFormat: "已添加分类：{name}",
    starterCategories: ["餐饮", "交通", "日用", "居住", "收入", "订阅", "娱乐"],
    categoryHintAmounts: ["餐饮": 1800, "交通": 400, "日用": 600, "居住": 3200, "收入": 8000, "订阅": 200, "娱乐": 500],
    cardStatementDay: "出账日", cardDueDay: "还款日", cardBill: "本期账单",
    refundMark: "退款", refundDone: "已退款", refundBackFormat: "{title} 退款",
    splitMark: "拆成两笔", splitAmount: "另一笔金额",
    goalAttach: "计入存钱目标", goalNone: "不计入", goalDeposit: "存入目标", goalFrom: "从", goalTo: "转到",
    archiveAccount: "归档", restoreAccount: "恢复", archivedTitle: "已归档",
    removedTitle: "回收站", removedRestore: "恢复", removedEmpty: "回收站是空的",
    lockOnOpen: "打开时解锁", lockTitle: "解锁后才能看账", lockRetry: "再试一次",
    lockOnWord: "已开启", lockOffWord: "未开启",     amountSolve: "计算",
    worthGrowth: "区间净增长", worthPastWeek: "过去7天", worthPastMonth: "过去1个月", worthPastQuarter: "过去3个月", worthPastYear: "过去1年", worthPastAll: "全部",
    worthSpanWeek: "7天", worthSpanMonth: "1月", worthSpanQuarter: "3月", worthSpanYear: "1年", worthSpanAll: "全部",
    localeID: "zh_CN",
    billStatementFormat: "{name} 出账了，本期 {amount}",
    billDueFormat: "{name} 今天该还，本期 {amount}",
    statsMonthly: "月账单", statsAnnual: "年账单", statsOut: "支出", statsIn: "收入", statsOther: "其他",
    statsCountFormat: "{count} 笔{kind}，合计",
    statsCompareMonthFormat: "月{kind}对比", statsCompareYearFormat: "年{kind}对比",
    statsComposeFormat: "{when} {kind}构成", statsRankFormat: "{when} {kind}排行（前 10）",
    statsEmpty: "这段还没有这类记录", statsThisMonth: "本月", statsThisYear: "本年",
    statsPrev: "上一期", statsNext: "下一期",
    yearClassify: "分类", yearCompare: "月对比", yearTopFormat: "大额{kind}",
    yearAccountOut: "支出方式", yearAccountIn: "入账账户",
    yearMostFormat: "{when} 最多", yearAverageFormat: "月均{kind}", yearCountFormat: "{count} 笔",
    yearExpand: "展开", yearFold: "收起", yearRefunded: "已退",
    yearPrev: "上一年", yearNext: "下一年",
    accountMonthFlow: "本月进出"
)

private let englishCopy = LedgerCopy(
    tabDashboard: "Overview", tabTransactions: "Activity", tabAccounts: "Accounts", tabMe: "Me",
    netAssets: "Net worth", monthSpend: "Spent", monthIncome: "Income", monthBalance: "Month balance",
    monthlyBudget: "Monthly budget", budgetRemaining: "Left", safeToSpend: "Safe today", budgetOver: "Over budget",
    budgetUnset: "Set budget", budgetHint: "Cap this month’s spending", budgetClear: "Clear budget",
    countBudget: "Count in budget", countWorth: "Count in net worth", worthLeftOut: "Outside net worth",
    hideAmounts: "Hide amounts", hideAmountsOn: "Hidden", hideAmountsOff: "Visible",
    repeatDay: "Day of month", repeatPosted: "Posted", repeatWaiting: "Waiting",
    categoryBudget: "Category caps", categoryBudgetHint: "Set a cap per category; leave blank for no limit",
    edit: "Edit", done: "Done", save: "Save", cancel: "Cancel", add: "Add", back: "Back",
    toReview: "To review", markAllReviewed: "Mark all reviewed", checked: "Reviewed", unchecked: "Review",
    monthCategories: "Categories", report: "Report",
    yearReport: "Year", yearSpend: "Spent this year", yearIncome: "Income this year", yearBalance: "Year balance",
    savingGoals: "Savings goals", savingTarget: "Target", savingSaved: "Saved",
    claimTitle: "To reimburse", claimMark: "Waiting for reimbursement", claimPaid: "Money arrived", claimDone: "Reimbursed",
    claimEmpty: "Mark an expense as waiting. When the money arrives, tap here and it is written back to the account.",
    claimBackFormat: "{title} reimbursed",
    spendChartEmpty: "Add a transaction to see this month’s curve.",
    sampleBanner: "Sample entries can be edited", sampleClear: "Clear",
    paceWarning: "At this pace you may exceed budget", spendPace: "Spending pace", toTransactions: "Activity",
    recurringTitle: "Repeating", recurringHint: "Posts on its day",
    recurringEmpty: "Set rent or pay once. It posts itself on that day each month.",
    scopeChipMine: "Mine", scopeChipFamily: "Household", filter: "Filter", filterScope: "Scope",
    scopeMine: "Mine only", scopeFamily: "Household", time: "Time", today: "Today", thisMonth: "This month",
    customRange: "Custom", rangeStart: "Start", rangeEnd: "End", rangeTo: "to",
    accounts: "Accounts", accountCountFormat: "{count}", accountsEmpty: "Add your first account with the real balance.",
    accountKindBank: "Bank", accountKindCash: "Cash", accountKindCard: "Credit", accountKindOther: "Other",
    addAccount: "Add account", accountGuide: "No account of your own yet. Add one", editAccount: "Edit account", newAccount: "Add account",
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
    accountPeriodNet: "Net inflow", accountsTrend: "Net worth trend", accountMix: "Split", accountsWindow7: "7D", accountsWindow30: "1M",
    accountPeriodDelta: "Period change",
    transactions: "Activity", searchPlaceholder: "Search name, category, or account",
    filterAll: "All", filterOpen: "Review", filterDone: "Reviewed",
    periodSpend: "Spent", periodIncome: "Income", periodBalance: "Balance", txEmpty: "No transactions match this period.",
    rankUp: "up", rankDown: "down", rankFlat: "flat", vsLastMonth: "vs last mo.",
    txViewList: "List", txViewCalendar: "Calendar",
    weekdays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
    calendarWeek: ["S", "M", "T", "W", "T", "F", "S"],
    me: "Me", meLedger: "Book", meDisplay: "Display", meData: "Data", categories: "Categories", profileHint: "Tap to set nickname", privacy: "Privacy",
    language: "Language", currency: "Currency",
    streakDays: "Streak", streakToday: "Logged today", streakNone: "Not logged today", privacyTitle: "Privacy",
    exportBackup: "Export JSON backup", dataExportNote: "Accounts, activity and budgets go into this JSON.", exportBook: "Export book", dataManage: "Data", clearBook: "Clear data",
    clearBookConfirm: "Accounts, transactions and budgets will be removed, and the sample book will not come back.",
    clearBookDone: "Book data cleared",
    importData: "Import book", importPaste: "Paste exported JSON", importDone: "Import complete",
    importInvalid: "Invalid JSON. Check the contents.",
    importConfirm: "This file replaces the current book, including accounts and transactions.",
    importFile: "Choose JSON file",
    nicknameTitle: "Nickname", avatarTitle: "Avatar", profileTitle: "Nickname & gender", gender: "Gender",
    genderFemale: "Female", genderMale: "Male", genderSecret: "Private",
    entryEdit: "Edit transaction", shared: "Household", entryNew: "Add transaction",
    amount: "Amount", name: "Name", namePh: "Lunch, salary, rent", category: "Category", date: "Date", account: "Account",
    titleSuggestions: "Recent titles", newCategory: "New category", deleteEntry: "Delete",
    todayWord: "Today", yesterdayWord: "Yesterday", fundShare: "units", stockShare: "shares",
    localeZh: "中文", localeEn: "English", unsetName: "Not set", unsetMark: "—", familyTag: "Household",
    monthOverview: "Overview",
    monthTitleFormat: "{monthName} {overview}", monthUnitFormat: "{monthName}", monthDayFormat: "{monthName} {day}",
    calendarTitleFormat: "{monthName} {year}", monthPrevious: "Previous month", monthNext: "Next month",
    categoryAddedFormat: "Added category: {name}",
    starterCategories: ["Dining", "Transit", "Daily", "Housing", "Income", "Subscriptions", "Entertainment"],
    categoryHintAmounts: ["Dining": 1800, "Transit": 400, "Daily": 600, "Housing": 3200, "Income": 8000, "Subscriptions": 200, "Entertainment": 500],
    cardStatementDay: "Statement day", cardDueDay: "Due day", cardBill: "This statement",
    refundMark: "Refund", refundDone: "Refunded", refundBackFormat: "{title} refund",
    splitMark: "Split in two", splitAmount: "Other amount",
    goalAttach: "Count toward a goal", goalNone: "None", goalDeposit: "Add to goal", goalFrom: "From", goalTo: "To",
    archiveAccount: "Archive", restoreAccount: "Restore", archivedTitle: "Archived",
    removedTitle: "Recently deleted", removedRestore: "Restore", removedEmpty: "Nothing here",
    lockOnOpen: "Unlock to open", lockTitle: "Unlock to see the book", lockRetry: "Try again",
    lockOnWord: "On", lockOffWord: "Off",     amountSolve: "Calculate",
    worthGrowth: "Net change", worthPastWeek: "Past 7 days", worthPastMonth: "Past month", worthPastQuarter: "Past 3 months", worthPastYear: "Past year", worthPastAll: "All",
    worthSpanWeek: "7D", worthSpanMonth: "1M", worthSpanQuarter: "3M", worthSpanYear: "1Y", worthSpanAll: "All",
    localeID: "en_US",
    billStatementFormat: "{name} statement posted, this period {amount}",
    billDueFormat: "{name} is due today, this period {amount}",
    statsMonthly: "Monthly", statsAnnual: "Annual", statsOut: "Expenditures", statsIn: "Incomes", statsOther: "Others",
    statsCountFormat: "{count} {kind}, total",
    statsCompareMonthFormat: "Monthly {kind} comparison", statsCompareYearFormat: "Annual {kind} comparison",
    statsComposeFormat: "{when} {kind} mix", statsRankFormat: "{when} {kind} ranking (top 10)",
    statsEmpty: "Nothing in this period", statsThisMonth: "This month", statsThisYear: "This year",
    statsPrev: "Previous", statsNext: "Next",
    yearClassify: "Classification", yearCompare: "Monthly comparison", yearTopFormat: "Top {kind}",
    yearAccountOut: "Payment method", yearAccountIn: "Received into",
    yearMostFormat: "{when} most", yearAverageFormat: "Average monthly {kind}", yearCountFormat: "{count} in total",
    yearExpand: "Expand", yearFold: "Collapse", yearRefunded: "Refunded",
    yearPrev: "Previous year", yearNext: "Next year",
    accountMonthFlow: "This month"
)
