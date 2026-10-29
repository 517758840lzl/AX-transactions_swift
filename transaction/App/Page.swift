//
//  Page.swift
//  transaction
//
//  Created by Lzl on 2026/10/2.
//

import Foundation

enum Page: Hashable {
    case entry(id: String?)
    case filter(which: String)
    case budget
    case account(id: String)
    case accountForm(id: String?, chooseKind: Bool)
    case transfer
    case repeatPlan(id: String?)
    case yearReport
    case savingGoals
    case savingGoal(id: String?)
    case profile
    case categories
    case language
    case currency
    case privacy
    case export
    case removed
    case worthTrend
}
