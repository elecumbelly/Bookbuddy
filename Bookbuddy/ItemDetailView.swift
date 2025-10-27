//
//  ItemDetailView.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import SwiftUI
internal import CoreData

struct ItemDetailView: View {
    @ObservedObject var item: Item
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Book Cover and Basic Info
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 180)
                        .cornerRadius(12)
                        .overlay(
                            Image(systemName: "book.closed")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sample Book #\(itemNumber)")
                            .font(.title2)
                            .bold()
                        
                        Text("Sample Author")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("ISBN: 1234567890123")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Reading Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reading Status")
                        .font(.headline)
                    
                    HStack {
                        Text("To Read")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        
                        Spacer()
                    }
                }
                
                // Reading Progress (placeholder)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reading Progress")
                        .font(.headline)
                    
                    HStack {
                        Text("Page 0 of 250")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("0%")
                            .font(.subheadline)
                            .bold()
                    }
                    
                    ProgressView(value: 0.0)
                        .progressViewStyle(LinearProgressViewStyle())
                }
                
                // Book Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)
                    
                    if let timestamp = item.timestamp {
                        HStack {
                            Text("Added:")
                            Spacer()
                            Text(timestamp, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Status:")
                        Spacer()
                        Text("Template Book")
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Update Progress") {
                    // TODO: Implement in future builds
                }
                .disabled(true)
            }
        }
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
    
    return NavigationView {
        ItemDetailView(item: sampleItem)
    }
    .environment(\.managedObjectContext, context)
}