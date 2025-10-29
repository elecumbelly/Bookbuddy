# Agent Context Files - Bookbuddy

This directory contains documentation and context files specifically for AI coding agents (like Claude Code) working on the Bookbuddy project. These files provide architectural context, development principles, and lessons learned from production issues.

---

## 📋 File Index

| File | Purpose | Read When |
|------|---------|-----------|
| **`.agentmindset.md`** | Core development principles and non-negotiables | Start of every session, before major changes |
| **`.agentsystemdata-model.md`** | Core Data model, architecture, and data flow | Working with entities, relationships, or data layer |
| **`.agentknown-issues.md`** | Critical pitfalls, regressions, and "don't do this" patterns | Before refactoring core features, after encountering bugs |

---

## 🎯 Quick Start for AI Agents

**At the start of each session:**
1. Read `.agentmindset.md` - Understand development principles
2. Skim `.agentsystemdata-model.md` - Refresh on current architecture
3. Check `.agentknown-issues.md` - Avoid known pitfalls

**Before major refactoring:**
1. Read relevant sections of `.agentsystemdata-model.md`
2. **CAREFULLY read `.agentknown-issues.md`** - Critical!
3. Search codebase for `#warning` directives - Protected code sections

**After discovering a bug:**
1. Check if issue is documented in `.agentknown-issues.md`
2. After fixing, update `.agentknown-issues.md` if it's a pattern worth protecting

---

## 📁 File Descriptions

### `.agentmindset.md`
**Core development principles and non-negotiables**

Contains:
- Rule of Explicitness: Never assume features
- Quality Standards: Swift Concurrency, Apple conventions
- Apple Platform Focus: Native frameworks and APIs
- Non-Negotiables: No silent failures, token efficiency
- Project-Specific Rules: Book data integrity, privacy, performance

**When to reference:**
- Start of new session
- Before proposing architectural changes
- When making technical stack decisions
- Before adding third-party dependencies

---

### `.agentsystemdata-model.md`
**Core Data model, architecture, and complete data flow**

Contains:
- Entity definitions (Book, PagePhoto)
- Computed properties and relationships
- Data validation rules (ISBN, page numbers)
- Image compression strategy
- API integration (Open Library)
- Complete data flow for all features
- Performance considerations
- Version history

**When to reference:**
- Working with Core Data entities
- Implementing new features
- Debugging data persistence issues
- Planning migrations
- Understanding existing workflows

**Current Version:** v0.5.3
- Document scanner for page photos (v0.5)
- Speech recognition for progress updates (v0.3 → v0.5.3)
- Page photo markup and archive (v0.4)

---

### `.agentknown-issues.md`
**⚠️ CRITICAL: Documented pitfalls and regressions**

Contains:
- 🚨 Gesture Recognition Blocking (UIImpactFeedbackGenerator)
- ⚠️ Audio Session Management (AVAudioSession conflicts)
- 📋 User Workflow Requirements (Auto-start speech recognition)
- Protection strategies and testing protocols
- Full regression history with version numbers

**When to reference:**
- **ALWAYS** before refactoring speech recognition
- Before modifying audio/camera features
- When adding haptic feedback anywhere
- After encountering gesture timeout errors
- Before "improving" UX that seems unintuitive

**Why this file exists:**
v0.5.2 introduced regressions by adding "improvements" that:
- Broke ALL gesture recognition (haptic feedback blocking)
- Conflicted with camera audio (aggressive session cleanup)
- Removed required auto-start feature (misunderstood workflow)

This file documents these patterns to prevent future repeats.

---

## 🛡️ Protection Mechanisms

### 1. Inline Code Warnings
Critical sections have `#warning` directives that show up in Xcode:
```swift
#warning("🚨 PROTECTED CODE: Do not add haptic feedback here...")
```

### 2. Inline Comments
Detailed `// ⚠️ CRITICAL:` comments explaining WHY and referencing this documentation.

### 3. This Documentation
Complete context for why certain patterns are forbidden.

**All three layers reference each other for full context.**

---

## 🔄 Maintenance

### Adding New Documentation
Create new files following the naming pattern: `.agent[topic].md`

### Updating Existing Files
- Update `.agentsystemdata-model.md` after data model changes
- Update `.agentknown-issues.md` after discovering/fixing production bugs
- Update version numbers and dates

### Deprecating Documentation
If a file becomes obsolete:
1. Delete the file (don't leave stale docs)
2. Update this README to remove references
3. Commit with clear explanation

---

## 📚 Related Documentation

**Project Root:**
- `CLAUDE.md` - Technical overview for general Claude sessions
- `README.md` - User-facing project documentation
- `.gitignore` - Excludes .agent/ from version control (UPDATE: Now tracked!)

**Note:** This directory is NOW tracked in git (changed in v0.4.2) to preserve critical context across sessions.

---

## 💡 Philosophy

These files exist because:
1. **AI agents have no persistent memory** between sessions
2. **Context tokens are expensive** - load only what's needed
3. **Regressions happen** when patterns aren't documented
4. **Code comments aren't enough** - need architectural context
5. **Future agents benefit** from lessons learned today

Keep files focused, current, and actionable.

---

*Last Updated: October 29, 2025 (v0.5.3)*
*Directory Structure: Flat (no subdirectories) for simplicity*
