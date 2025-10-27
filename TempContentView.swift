//
//  TempContentView.swift - Temporary fix using Item entity
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import SwiftUI
internal import CoreData

struct TempContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @State private var showingAddItem = false
    
    var body: some View {
        NavigationView {
            if items.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Books Yet")
                        .font(.title2)
                        .bold()
                    
                    Text("Add your first book to get started")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: { showingAddItem = true }) {
                        Label("Add Your First Book", systemImage: "plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding()
            } else {
                List {
                    ForEach(items) { item in
                        NavigationLink {
                            ItemDetailView(item: item)
                        } label: {
                            ItemRowView(item: item)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: { showingAddItem = true }) {
                            Label("Add Book", systemImage: "plus")
                        }
                    }
                }
                .navigationTitle("My Library")
            }
        }
        .sheet(isPresented: $showingAddItem) {
            TempAddItemView()
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Handle error appropriately in a real app
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct TempAddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isbn = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Book Information") {
                    TextField("ISBN", text: $isbn)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Add Item (Temporary)") {
                        addItem()
                    }
                    .disabled(isbn.isEmpty)
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addItem()
                    }
                    .disabled(isbn.isEmpty)
                }
            }
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                print("Failed to save item: \(nsError.localizedDescription)")
            }
        }
    }
}

#Preview {
    TempContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
