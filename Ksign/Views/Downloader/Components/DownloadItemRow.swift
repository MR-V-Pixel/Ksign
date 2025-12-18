//
//  DownloadItemRow.swift
//  Ksign
//
//  Created by Nagata Asami on 5/24/25.
//

import SwiftUI

// Download Item Row
struct DownloadItemRow: View {
    let item: DownloadItem
    @Binding var shareItems: [Any]
    var importIpaToLibrary: (DownloadItem) -> Void
    var exportToFiles: (DownloadItem) -> Void
    var deleteItem: (DownloadItem) -> Void

    @State private var showingConfirmationDialog = false

    init(
        item: DownloadItem,
        shareItems: Binding<[Any]>,
        importIpaToLibrary: @escaping (DownloadItem) -> Void,
        exportToFiles: @escaping (DownloadItem) -> Void,
        deleteItem: @escaping (DownloadItem) -> Void
    ) {
        self.item = item
        self._shareItems = shareItems
        self.importIpaToLibrary = importIpaToLibrary
        self.exportToFiles = exportToFiles
        self.deleteItem = deleteItem
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if item.isFinished {
                Image(systemName: "doc.zipper")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            } else {
                if #available(iOS 17.0, *) {
                    Image(systemName: "arrow.down.document")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                        .symbolEffect(.pulse)
                } else {
                    Image(systemName: "arrow.down.document")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body)
                    .lineLimit(1)
                
                Text(item.isFinished ? item.formattedFileSize : item.progressText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !item.isFinished {
                    ProgressView(value: item.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .accentColor(.accentColor)
                }
            }
            
            Spacer()
            
            if !item.isFinished {
                Button {
                    deleteItem(item)
                } label: {
                    Image(systemName: "stop.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            if item.isFinished {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                showingConfirmationDialog = true
            }
        }
        .confirmationDialog(
            item.title,
            isPresented: $showingConfirmationDialog,
            titleVisibility: .visible
        ) {
            fileConfirmationDialogButtons()
        }
        .contextMenu {
            fileConfirmationDialogButtons()
        }
        .swipeActions(edge: .trailing) {
            swipeActions()
        }
    }
    
    @ViewBuilder
    private func fileConfirmationDialogButtons() -> some View {
        Button {
            shareItems = [item.localPath]
            UIActivityViewController.show(activityItems: shareItems)
        } label: {
            Label(.localized("Share"), systemImage: "square.and.arrow.up")
        }
        
        Button {
            importIpaToLibrary(item)
        } label: {
            Label(.localized("Import to Library"), systemImage: "square.grid.2x2.fill")
        }
        
        Button {
            exportToFiles(item)
        } label: {
            Label(.localized("Export to Files App"), systemImage: "square.and.arrow.up.fill")
        }
        
        Button(role: .destructive) {
            deleteItem(item)
        } label: {
            Label(.localized("Delete"), systemImage: "trash")
        }
    }

    @ViewBuilder
    private func swipeActions() -> some View {
        Button(role: .destructive) {
            withAnimation {
                deleteItem(item)
            }
        } label: {
            Label(.localized("Delete"), systemImage: "trash")
        }

        Button(role: .cancel) {
            importIpaToLibrary(item)
        } label: {
            Label(.localized("Import"), systemImage: "square.grid.2x2.fill")
        }
    }
}


struct AppStoreDownloadItemRow: View {
    @ObservedObject var download: Download
    
    var body: some View {
        HStack(spacing: 12) {
            if #available(iOS 17.0, *) {
                Image(systemName: download.unpackageProgress > 0 ? "doc.zipper" : "arrow.down.document")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                    .symbolEffect(.pulse)
            } else {
                Image(systemName: download.unpackageProgress > 0 ? "doc.zipper" : "arrow.down.document")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(download.fileName)
                    .font(.body)
                    .lineLimit(1)
                
                Text(download.progressText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: download.overallProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accentColor(.accentColor)
            }
            
            Spacer()
            if download.unpackageProgress == 0 {
                Button {
                    DownloadManager.shared.cancelDownload(download)
                } label: {
                    Image(systemName: "stop.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
