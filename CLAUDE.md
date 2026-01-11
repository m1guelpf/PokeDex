# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PokeDex is an iOS app (iOS 26.0+) built with SwiftUI for tracking Pokémon catches across multiple games. It uses SQLite for local storage with a migration system, lazy sprite loading, and supports first-launch onboarding with starter-dependent Pokemon filtering.

## Build & Development Commands

### Building and Running

**IMPORTANT**: Always use MCP tools for building, never use xcodebuild directly.

```bash
# Build and run on a simulator (preferred method)
mcp__xcodebuildmcp__build_run_sim

# Build for device
mcp__xcodebuildmcp__build_device

# Clean build
mcp__xcodebuildmcp__clean
```

### Testing
The project does not currently have a test suite.

### Deployment

**CRITICAL**: Deployment is automated via git push. NEVER push to git to trigger deployment without explicit user authorization. The CI/CD pipeline (Fastlane) handles TestFlight uploads automatically when code is pushed.

## Architecture

### Database Layer (SQLiteData + GRDB)

The app uses a custom migration and seeding system built on top of SQLiteData (Point-Free) and GRDB:

- **Database initialization**: `src/Database/Database.swift:appDatabase()` - Creates the database, registers migrations, and seeds data in preview contexts
- **Migration protocol**: `src/Database/Migration.swift` - Defines `Migration` protocol for schema changes and `Seeder` protocol for data seeding
- **Migrations directory**: `src/Database/Migrations/` - Numbered migration files (e.g., `1_CreatePokemonTable.swift`, `99_Seeder.swift`)
- **Debug behavior**: `eraseDatabaseOnSchemaChange = true` in DEBUG builds automatically resets the database when schema changes

To add a new migration:
1. Create a new file in `src/Database/Migrations/` with naming pattern `{number}_{Description}.swift`
2. Implement the `Migration` protocol with a `static func run(_ db: Database) throws` method
3. Register it in `appDatabase()` by adding it to `migrator.registerMigrations([...])`

### Dependency Injection

Uses Point-Free's swift-dependencies for dependency injection:

- Database and sync engine bootstrapped via `prepareDependencies { try $0.bootstrapDatabase() }` in `App.swift:8-14` and `ContentView.swift:88-91`
- Access database with `@Dependency(\.defaultDatabase) var database`
- Extension in `DependencyValues+database.swift` provides `bootstrapDatabase()` helper

### Data Models

**Database Models** (`src/Models/Database/`):
- **Game**: Multi-game support with `@Table` macro
  - Key fields: `id`, `slug`, `name`, `generation`, `totalPokemon`, `selectedStarter`, `spriteURLTemplate`, `createdAt`
  - `sprite(for: Pokemon) -> URL?`: Generates sprite URL by replacing `{sprite}` placeholder in template
  - `delete(_:)`: Deletes game with cascade to Pokemon and sprite cleanup
  - `static var currentGame`: Query helper for active game from TinyStorage

- **Pokemon**: Pokemon data with `@Table("pokemon")` macro
  - Key fields: `id`, `gameId`, `name`, `dexNumber`, `notes`, `isRegistered`
  - `imageName`: Computed property for sprite filename (e.g., "Mr. Mime" → "mr-mime")
  - `spriteFilePath(for: Game)`: Path to locally cached sprite
  - Uses generic `update(set:)` from `Table+update` extension

**Data Models** (`src/Models/Data/`):
- **GameManifest**: JSON structure for bundled game data
  - Nested: `GameManifest.Game`, `GameManifest.Game.Pokemon`
  - `static func load() throws`: Loads from bundled `games.json`
  - Pokemon filtering: `excludedForStarters` array determines availability based on starter choice

### Views Architecture

**Entry Point**:
- **RootContainer**: Conditional rendering based on game existence
  - `@FetchAll(Game.all)` to check if games exist
  - Shows `SplashScreen` if empty, otherwise `GameScreen`
  - Auto-repairs `activeGameId` in TinyStorage if needed

**Onboarding Flow** (`src/Views/Onboarding/`, `src/Views/Screens/SplashScreen.swift`):
- **SplashScreen**: Welcome screen with sheet presentation
- **GameCreationSheet**: Stage-based onboarding using enum
  - Stages: `.selectingGame`, `.selectingStarter(game)`, `.downloading(progress)`, `.completed`
  - Inline async setup logic (no separate ViewModel or Service)
  - Progress reporting via `AsyncStream` from SpriteManager

**Main Views**:
- **GameScreen**: Main Pokemon list with multi-game support
  - `@FetchAll` with dynamic query based on `currentGameID` binding
  - Toolbar title menu for game switching (tap title → picker + "Add Game")
  - Search, filtering, swipe actions, shake gesture for settings

**Settings** (`src/Views/Sheets/SettingsPage.swift`):
- Clear database functionality
- Displays current game name

**View Extensions**:
- `View+onShake.swift`: Shake gesture support
- `View+if.swift`: Conditional view modifiers

### Sprite Management

**SpriteManager** (`src/Support/SpriteManager.swift`):
- `@MainActor` singleton for thread-safe image caching
- **Lazy loading pattern**: Returns placeholder immediately, downloads in background if missing
- `get(for: Pokemon, in: Game)`: Gets sprite with fallback to placeholder
- `download(for: [Pokemon], in: Game)`: Batch download with progress reporting
  - 50 concurrent downloads (TaskGroup with semaphore pattern)
  - Returns `AsyncStream<Progress>` for UI updates
- `cleanup()`: Removes orphaned sprite directories
- `deleteAll(forGame:)`: Cleans up when game is deleted
- Sprites stored in `Documents/sprites/{gameSlug}/{pokemonName}.png`

### Storage

Uses TinyStorage for lightweight preference storage:
- `@TinyStorageItem(.activeGameId)` - Currently selected game (UUID)
- `@TinyStorageItem(.showingPercentage)` - Toggle percentage vs count display
- `@TinyStorageItem(.showingOnlyMissing)` - Filter to show only uncaught Pokémon
- Extension in `TinyStorage+shared.swift` provides shared storage keys

### Error Handling

Uses Point-Free's IssueReporting:
- Configured with `OSLogIssueReporter()` in `App.swift:8`
- Wrap risky operations with `withErrorReporting { try ... }`
- Logger defined in `src/Support/Logging.swift`

## Key Dependencies (Package.swift)

- **SQLiteData** (Point-Free): Type-safe SQLite wrapper with structured queries
- **GRDB**: Underlying SQLite database engine
- **swift-dependencies**: Dependency injection
- **TinyStorage**: Lightweight UserDefaults wrapper
- **SwiftCSV**: CSV parsing for data import
- **IssueReporting**: Error reporting and logging

## Asset Management

**Static Assets**: `src/Assets.xcassets/`
- Pokeball icon and other UI assets

**Pokemon Sprites**: Downloaded at runtime and cached locally
- Source: `pokemondb.net` (URL template stored in Game model)
- Cache location: `Documents/sprites/{gameSlug}/{pokemonName}.png`
- Lazy loading: SpriteManager returns placeholder immediately, downloads in background
- Sprite filename normalization: Apostrophes removed, spaces/dots → hyphens, ♂ → "-m", ♀ → "-f"

## Code Style & Patterns

### Architectural Preferences

**Prefer inline logic over separate service classes**:
- ✅ Logic in views (e.g., `GameCreationSheet.setup()`) when it's view-specific
- ✅ Static methods on models (e.g., `GameManifest.load()`)
- ✅ Computed properties for derived data (e.g., `Game.sprite(for:)`)
- ❌ Avoid creating dedicated "Manager" or "Service" classes unless shared across many views
- Exception: SpriteManager is justified as a singleton for caching and concurrency control

**Prefer generic extensions over copy-paste**:
- ✅ `Table+update` extension for all PrimaryKeyedTable types
- ✅ Generic helpers in `Extensions/` instead of per-model methods

**Stage-based state machines in views**:
- ✅ Use enums with associated values for multi-stage flows (e.g., `GameCreationSheet.Stage`)
- ✅ Inline state management instead of separate `@Observable` classes when scoped to one view

**Model responsibilities**:
- ✅ Static query helpers (e.g., `Game.currentGame`)
- ✅ Computed properties for derived values
- ✅ Instance methods for operations on self (e.g., `Game.delete(_:)`)

### Swift Patterns

- Uses SwiftUI with `@FetchAll` property wrapper for reactive database queries
- Dynamic queries: Initialize `@FetchAll` with runtime values in `init()` when needed
- Extensive use of Point-Free utilities (`tap`, `with` helpers in `helpers.swift`)
- Sendable protocol conformance throughout for Swift 6 concurrency
- `@MainActor` for singletons that manage UI resources (e.g., SpriteManager)
- AsyncStream for progress reporting in long-running operations

### File Organization

```
src/
├── App.swift                    # App entry point
├── Database/
│   ├── Database.swift           # Database configuration
│   ├── Migration.swift          # Migration protocol
│   └── Migrations/              # Numbered migrations (1_, 2_, 99_Seeder)
├── Extensions/
│   ├── DependencyValues+*.swift # Dependency injection extensions
│   ├── TinyStorage+shared.swift # Storage key definitions
│   ├── Table+update.swift       # Generic database update extension
│   └── View+*.swift             # View modifiers
├── Models/
│   ├── Database/                # @Table models (Game, Pokemon)
│   └── Data/                    # JSON/data models (GameManifest)
├── Resources/
│   └── games.json               # Bundled game data
├── Support/
│   ├── helpers.swift            # Point-Free utilities
│   ├── Logging.swift            # Logger setup
│   ├── NetworkMonitor.swift     # Network status
│   └── SpriteManager.swift      # Sprite download/cache singleton
└── Views/
    ├── RootContainer.swift      # Main entry point
    ├── Components/              # Reusable UI components
    ├── Onboarding/              # First-launch flow
    ├── Screens/                 # Full-screen views
    └── Sheets/                  # Sheet presentations
```

## Multi-Game System

### Architecture Overview

The app supports multiple Pokemon games with starter-dependent Pokemon filtering:

**Game Selection Flow**:
1. First launch → RootContainer detects no games → Shows SplashScreen
2. User taps "Get Started" → GameCreationSheet presented as sheet
3. User selects game (e.g., Pokemon FireRed) → Shows starter selection
4. User selects starter (Bulbasaur/Charmander/Squirtle) → Filters Pokemon
5. Sprites download in background (50 concurrent) → Shows progress
6. Setup completes → Navigates to GameScreen

**Starter-Dependent Filtering** (Pokemon FireRed example):
- Bulbasaur → Can catch Entei, excludes Charmander/Squirtle evolution lines
- Charmander → Can catch Suicune, excludes Bulbasaur/Squirtle evolution lines
- Squirtle → Can catch Raikou, excludes Bulbasaur/Charmander evolution lines
- Implemented via `excludedForStarters` array in `games.json`

**Game Switching**:
- Tap navigation title in GameScreen → Picker menu appears
- Select different game → Updates `activeGameId` in TinyStorage
- @FetchAll query updates → List refreshes with new game's Pokemon
- "Add Game" button in same menu to launch onboarding again

### Database Schema

**Games Table** (`1_CreateGamesTable`):
```swift
id: UUID (primary key)
slug: String (unique, e.g., "firered")
name: String (e.g., "Pokemon FireRed")
generation: Int
totalPokemon: Int
selectedStarter: String? (e.g., "bulbasaur")
dataVersion: String
spriteURLTemplate: String (e.g., "https://img.pokemondb.net/sprites/firered-leafgreen/normal/{sprite}.png")
createdAt: Date (UnixTime)
```

**Pokemon Table** (`2_CreatePokemonTable`):
```swift
id: UUID (primary key)
gameId: UUID (foreign key → games.id, cascade delete)
name: String
dexNumber: Int
notes: String (catch location/method)
isRegistered: Bool (caught status)

Index: (gameId, dexNumber) for efficient queries
```

### Game Data Format

**games.json** structure:
```json
{
  "version": "1.0",
  "games": [
    {
      "slug": "firered",
      "name": "Pokemon FireRed",
      "generation": 3,
      "spriteGeneration": "firered-leafgreen",
      "hasStarterChoice": true,
      "availableStarters": ["bulbasaur", "charmander", "squirtle"],
      "pokemon": [
        {
          "dexNumber": 1,
          "name": "Bulbasaur",
          "notes": "Starter Pokemon from Prof. Oak.",
          "spriteSlug": "bulbasaur",
          "excludedForStarters": ["bulbasaur"]
        }
      ]
    }
  ]
}
```

**Key Fields**:
- `spriteGeneration`: Determines sprite style (e.g., "firered-leafgreen", "black-white")
- `excludedForStarters`: Array of starters that cannot obtain this Pokemon
- `spriteSlug`: Pokemon name for URL construction (may differ from display name)
