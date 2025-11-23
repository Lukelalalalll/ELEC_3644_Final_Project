//
//  LibraryView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/24.
//

import SwiftUI

struct LibraryView: View {
    var body: some View {
        VStack {
            Text("666")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .foregroundColor(.red)
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LibraryView()
        }
    }
}
