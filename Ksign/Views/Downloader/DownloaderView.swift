//
//  DownloaderView.swift
//  Ksign
//
//  Created by Nagata Asami on 5/24/25.
//

import SwiftUI
import UniformTypeIdentifiers
import NimbleViews
import UIKit

struct DownloaderView: View {
    @StateObject private var downloadManager = IPADownloadManager()
    @StateObject private var libraryManager = DownloadManager.shared
    
    @State private var selectedItem: DownloadItem?
    @State private var showActionSheet = false
    @State private var webViewURL: URL?
    @State private var shareItems: [Any] = []
    @State private var showDocumentPicker = false
    @State private var fileToExport: URL?
    @State private var _searchText = ""
    
    private var filteredDownloadItems: [DownloadItem] {
        if _searchText.isEmpty {
            return downloadManager.downloadItems
        } else {
            return downloadManager.downloadItems.filter { $0.title.localizedCaseInsensitiveContains(_searchText) }
        }
    }

    var body: some View {
        NBNavigationView("IPA Downloads") {
            List {
                ForEach(filteredDownloadItems) { item in
                    DownloadItemRow(item: item) { tappedItem in
                        selectedItem = tappedItem
                        showActionSheet = true
                    }
                }
            }
            .listStyle(.plain)
            .overlay {
                if downloadManager.downloadItems.isEmpty {
                    if #available(iOS 17, *) {
                        ContentUnavailableView {
                            Label(.localized("No downloaded IPAs"), systemImage: "square.and.arrow.down.fill")
                        } description: {
                            Text(.localized("Get started by downloading your first IPA file."))
                        } actions: {
                            Button {
                                _addDownload()
                            } label: {
                                Text("Add Download").bg()
                            }
                        }
                    }
                }
            }
            .searchable(text: $_searchText, placement: .platform())
            .toolbar {
                NBToolbarButton(
                    "Add",
                    systemImage: "plus",
                    placement: .topBarTrailing
                ) {
                   _addDownload()
                }
            }
            .onAppear {
                downloadManager.loadDownloadedIPAs()
            }
            .confirmationDialog(.localized("Choose an action"), isPresented: $showActionSheet, titleVisibility: .visible) {
                actionSheetContent
            }
            .fullScreenCover(item: $webViewURL) { url in
                webViewSheet(url: url)
            }
            .sheet(isPresented: $showDocumentPicker) {
                documentPickerSheet
            }
        }
    }
}


// MARK: - Alert & Sheet Content
private extension DownloaderView {
    
    @ViewBuilder
    var actionSheetContent: some View {
        if let selectedItem = selectedItem {
            Button("Share") {
                shareItem(selectedItem)
            }
            
            Button("Import to Library") {
                importIpaToLibrary(selectedItem)
            }
            
            Button("Export to Files App") {
                exportToFiles(selectedItem)
            }
            
            Button("Delete", role: .destructive) {
                deleteItem(selectedItem)
            }
            
            Button("Cancel", role: .cancel) {}
        }
    }
    
    func webViewSheet(url: URL) -> some View {
        WebViewSheet(
            downloadManager: downloadManager,
            url: url,
        )
    }
    
    @ViewBuilder
    var documentPickerSheet: some View {
        if let fileURL = fileToExport {
            FileExporterRepresentableView(
                urlsToExport: [fileURL],
                asCopy: true,
                useLastLocation: false,
                onCompletion: { _ in
                    showDocumentPicker = false
                }
            )
        }
    }

}

// MARK: - Action Handlers
private extension DownloaderView {
    func _addDownload() {
        UIAlertController.showAlertWithTextBox(
            title: .localized("Enter Website URL"),
            message: .localized("Enter the URL of the website containing the IPA file"),
            textFieldPlaceholder: .localized("https://example.com"),
            submit: .localized("OK"),
            cancel: .localized("Cancel"),
            onSubmit: { url in
                handleURLInput(url: url)
            }
        )
    }

    func handleURLInput(url: String) {
        guard !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        var finalUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalUrl.lowercased().hasPrefix("http://") && !finalUrl.lowercased().hasPrefix("https://") {
            finalUrl = "https://" + finalUrl
        }
        
        guard let validUrl = URL(string: finalUrl) else {
            UIAlertController.showAlertWithOk(title: "Error", message: "Invalid URL format")
            return
        }
        
        print(validUrl)
        
        if downloadManager.isIPAFile(validUrl) {
            downloadManager.checkFileTypeAndDownload(url: validUrl) { result in
                switch result {
                case .success:
                    UIAlertController.showAlertWithOk(title: "Success", message: "The IPA file is being downloaded!\nYou can close this window or download more!")
                case .failure(let error):
                    UIAlertController.showAlertWithOk(title: "Error", message: error.localizedDescription)
                }
            }
        } else {
            print("validUrl: \(validUrl)")
            webViewURL = validUrl
        }
    }
    
    func shareItem(_ item: DownloadItem) {
        shareItems = [item.localPath]
        UIActivityViewController.show(activityItems: shareItems)
    }
    
    private func importIpaToLibrary(_ file: DownloadItem) {
        let id = "FeatherManualDownload_\(UUID().uuidString)"
        let download = self.libraryManager.startArchive(from: file.url, id: id)
        libraryManager.handlePachageFile(url: file.url, dl: download) { err in
            DispatchQueue.main.async {
                if (err != nil) {
                    UIAlertController.showAlertWithOk(
                        title: "Error",
                        message: .localized("Whoops!, something went wrong when extracting the file. \nMaybe try switching the extraction library in the settings?"),
                    )
                }
                if let index = libraryManager.getDownloadIndex(by: download.id) {
                    libraryManager.downloads.remove(at: index)
                }
            }
        }
    }
    
    func exportToFiles(_ item: DownloadItem) {
        fileToExport = item.localPath
        showDocumentPicker = true
    }
    
    func deleteItem(_ item: DownloadItem) {
        do {
            try FileManager.default.removeItem(at: item.localPath)
            downloadManager.downloadItems.removeAll { $0.id == item.id }
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if let index = downloadManager.downloadItems.firstIndex(where: { $0.id == item.id }) {
                        downloadManager.downloadItems.remove(at: index)
                    }
                }
            }
        } catch {
            UIAlertController.showAlertWithOk(title: "Error", message: error.localizedDescription)
        }
    }
} 
