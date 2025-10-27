//
//  BookDetailView.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import SwiftUI
internal import CoreData

struct BookDetailView: View {
    @ObservedObject var book: Book
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingUpdateProgress = false

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
                        Text(book.displayTitle)
                            .font(.title2)
                            .bold()
                        
                        Text(book.displayAuthor)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        if let isbn = book.isbn {
                            Text("ISBN: \(isbn)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
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
                        Text(book.statusEnum.displayName)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(statusColor.opacity(0.2))
                            .foregroundColor(statusColor)
                            .cornerRadius(8)
                        
                        Spacer()
                    }
                }
                
                // Reading Progress
                if book.pageCount > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reading Progress")
                            .font(.headline)
                        
                        HStack {
                            Text("Page \(book.currentPage) of \(book.pageCount)")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(book.readingProgressPercentage)%")
                                .font(.subheadline)
                                .bold()
                        }
                        
                        ProgressView(value: book.readingProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                
                // Book Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)
                    
                    if let dateAdded = book.dateAdded {
                        HStack {
                            Text("Added:")
                            Spacer()
                            Text(dateAdded, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let publishedDate = book.publishedDate {
                        HStack {
                            Text("Published:")
                            Spacer()
                            Text(publishedDate, style: .date)
                                .foregroundColor(.secondary)
                        }
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
                    showingUpdateProgress = true
                }
            }
        }
        .sheet(isPresented: $showingUpdateProgress) {
            UpdateProgressView(book: book)
        }
    }
    
    private var statusColor: Color {
        switch book.statusEnum {
        case .toRead:
            return .blue
        case .reading:
            return .orange
        case .completed:
            return .green
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleBook = Book(context: context)
    sampleBook.id = UUID()
    sampleBook.title = "The Swift Programming Language"
    sampleBook.author = "Apple Inc."
    sampleBook.isbn = "9780134610993"
    sampleBook.publishedDate = Date()
    sampleBook.dateAdded = Date()
    sampleBook.pageCount = 450
    sampleBook.currentPage = 150
    sampleBook.status = "reading"
    
    return NavigationView {
        BookDetailView(book: sampleBook)
    }
    .environment(\.managedObjectContext, context)
}
