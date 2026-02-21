//
//  DetailRow.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Font.TownGreenFonts.caption)
                .foregroundStyle(Color.primaryGreen)
            Text(value)
                .font(Font.TownGreenFonts.body)
                .foregroundStyle(Color.darkGreen)
        }
    }
}
