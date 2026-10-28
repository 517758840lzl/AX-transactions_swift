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
    case profile
    case data
    case importBook
    case privacy
}
