//
//  QCFlowChips.swift
//  transaction
//
//  Created by Lzl on 2026/10/26.
//

import SwiftUI

// Por fora sempre se chamou QCFlowChips, mas lá dentro já é o QCFlexibleChips há bastante tempo.
// Não me apeteceu ir mudar todos os sítios que chamam isto. Ficou a fazer ponte, um dia unifico
struct QCFlowChips: View {
    var names: [String]
    var editing: Bool
    var canRemove: Bool
    var onRemove: (String) -> Void

    var body: some View {
        QCFlexibleChips(names: names, editing: editing, canRemove: canRemove, onRemove: onRemove)
    }
}
