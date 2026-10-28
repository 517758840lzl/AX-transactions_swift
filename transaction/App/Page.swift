import Foundation

enum Page: Hashable {
    case entry(id: String?)
    case filter(which: String)
    case budget
    case account(id: String)
    case accountForm(id: String?)
    case holding(id: String)
    case holdingForm(id: String?)
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
}
