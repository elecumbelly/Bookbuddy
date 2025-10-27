//
//  ItemRowView.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import SwiftUI
internal import CoreData

struct ItemRowView: View {
    let item: Item
    
    var body: some View {
        HStack {
            // Placeholder for book cover
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 70)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "book.closed")
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Sample Book #\(itemNumber)")
                    .font(.headline)
                    .lineLimit(2)
                
                Text("Sample Author")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text("To Read")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    if let timestamp = item.timestamp {
                        Text("Added \(timestamp, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // Generate a pseudo-random book number based on timestamp
    private var itemNumber: Int {
        guard let timestamp = item.timestamp else { return 1 }
        return Int(timestamp.timeIntervalSince1970.truncatingRemainder(dividingBy: 1000))
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleItem = Item(context: context)
    sampleItem.timestamp = Date()
    
    return List {
        ItemRowView(item: sampleItem)
        ItemRowView(item: sampleItem)
    }
}