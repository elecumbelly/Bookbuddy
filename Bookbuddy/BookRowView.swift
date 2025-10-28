//
//  BookRowView.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import SwiftUI
internal import CoreData

struct BookRowView: View {
    let book: Book
    
    var body: some View {
        HStack {
            // Book cover - show actual image if available, otherwise placeholder
            Group {
                if let imageData = book.coverImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 70)
                        .clipped()
                        .cornerRadius(8)
                        .accessibilityLabel("Cover image for \(book.displayTitle)")
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 70)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "book.closed")
                                .foregroundColor(.gray)
                        )
                        .accessibilityLabel("Book cover placeholder for \(book.displayTitle)")
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.displayTitle)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.displayAuthor)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text(book.statusEnum.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(book.statusEnum.color.opacity(0.2))
                        .foregroundColor(book.statusEnum.color)
                        .cornerRadius(4)

                    if book.statusEnum == .reading && book.pageCount > 0 {
                        Text("\(book.readingProgressPercentage)%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleBook = Book(context: context)
    sampleBook.id = UUID()
    sampleBook.title = "The Swift Programming Language"
    sampleBook.author = "Apple Inc."
    sampleBook.isbn = "9780134610993"
    sampleBook.pageCount = 450
    sampleBook.currentPage = 150
    sampleBook.status = "reading"
    
    return List {
        BookRowView(book: sampleBook)
        BookRowView(book: sampleBook)
    }
}
