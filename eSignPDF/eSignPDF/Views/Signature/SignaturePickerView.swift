//
//  SignaturePickerView.swift
//  eSignPDF
//

import SwiftData
import SwiftUI

struct SignaturePickerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \SignatureRecord.createdAt, order: .reverse) private var records: [SignatureRecord]
    @Environment(\.dismiss) private var dismiss

    var onPick: (SignatureModel) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "No signatures yet",
                        systemImage: "signature",
                        description: Text("Create a signature from the Home tab.")
                    )
                } else {
                    List(records) { record in
                        Button {
                            onPick(SignatureModel(entity: record))
                        } label: {
                            HStack(spacing: 14) {
                                if let img = SignatureModel(entity: record).loadImage() {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 36)
                                        .padding(6)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.93)))
                                }
                                Text(record.name)
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(colorScheme == .dark ? Color.black.opacity(0.92) : Color(uiColor: .systemBackground), for: .navigationBar)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .tint(.primary)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}
