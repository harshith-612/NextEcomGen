import Foundation
import SwiftData

@Model
final class AddressEntity {

    var addressValue: String?
    var id: UUID?
    var user: UserEntity?

    init() {}
}
