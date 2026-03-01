//
//  PDF_UtilsApp.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import SwiftUI

@main
struct PDF_UtilsApp: App {
    @State private var viewModel = PDFMergeViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
        .defaultSize(width: 960, height: 640)
        .windowResizability(.contentMinSize)
    }
}
