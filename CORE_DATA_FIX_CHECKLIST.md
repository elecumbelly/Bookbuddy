# Core Data Model Fix - Quick Reference Checklist

## 📋 Tomorrow's 5-Minute Fix

### Current Issue:
- Error: "executeFetchRequest:error: A fetch request must have an entity"
- Cause: Missing `Book` entity in Core Data model file

### Solution Steps:

#### Step 1: Open Core Data Model
- [ ] Open Xcode
- [ ] Navigate to `Bookbuddy.xcdatamodeld` in project navigator  
- [ ] Click on it to open the visual editor

#### Step 2: Add Book Entity
- [ ] Click "+" button at bottom of editor
- [ ] Name the new entity: `Book` (capital B)

#### Step 3: Add All Attributes
Copy this list exactly:

| ✓ | Attribute Name | Type | Optional |
|---|---|---|---|
| [ ] | `id` | UUID | ✓ |
| [ ] | `title` | String | ✓ |
| [ ] | `author` | String | ✓ |
| [ ] | `isbn` | String | ✓ |
| [ ] | `publishedDate` | Date | ✓ |
| [ ] | `pageCount` | Integer 32 | |
| [ ] | `currentPage` | Integer 32 | |
| [ ] | `dateAdded` | Date | ✓ |
| [ ] | `coverImageData` | Binary Data | ✓ |
| [ ] | `bookDescription` | String | ✓ |
| [ ] | `status` | String | ✓ |

**Note:** For each attribute:
1. Click "+" next to Attributes in the Book entity
2. Set the name and type as shown above
3. Check "Optional" box for attributes marked with ✓

#### Step 4: Configure Entity Settings
- [ ] Select `Book` entity in the editor
- [ ] In Data Model Inspector (right panel)
- [ ] Set "Codegen" dropdown to "Manual/None"

#### Step 5: Clean & Test
- [ ] Press `Cmd+Shift+K` (Clean Build Folder)
- [ ] Press `Cmd+B` (Build)
- [ ] Run your app - the fetch error should be gone!
- [ ] Test adding a book with ISBN lookup

## Expected Result:
✅ Your AddBookView will work perfectly  
✅ No more "fetch request must have an entity" error  
✅ Full ISBN lookup and book adding functionality  

## What This Fixes:
- `ContentView.swift` - @FetchRequest for Book entities will work
- `AddBookView.swift` - Creating new Book objects will work  
- `BookDetailView.swift` - Displaying book data will work

---
*Created: October 27, 2025*  
*Status: Ready to implement*