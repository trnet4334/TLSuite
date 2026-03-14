# Strategy Lab & Portfolio Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace StrategyLabView and PortfolioView stubs with full-featured screens matching the HTML prototypes, backed by a SwiftData `Strategy` model and stub `PortfolioViewModel`.

**Architecture:** Strategy Lab uses SwiftData (`Strategy` @Model → `StrategyRepository` → `StrategyViewModel`) with a 2-panel `HSplitView` (card grid + Inspector). Portfolio is stub-only (`PortfolioViewModel` with hardcoded data, no persistence) with a 2-panel `HSplitView` (main content + allocation inspector). Sidebar gains a context-aware bottom card that switches per selected screen.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, Swift Charts, Swift Testing framework (`@Suite`, `#expect`), `@Observable`, macOS 14+.

**Design references:**
- `strategy_lab.html` — visual reference for Strategy Lab
- `portfolio.html` — visual reference for Portfolio
- `docs/plans/2026-03-14-strategy-lab-portfolio-design.md` — full spec

**Existing patterns to follow:**
- `Core/Repositories/TradeRepository.swift` — struct with `ModelContext`, `#Predicate` with local vars
- `Features/Journal/TradeViewModel.swift` — `@Observable final class`, `@MainActor` methods, `TradeRepository` injected
- `Tests/FMSYSAppTests/TradeRepositoryTests.swift` — `@MainActor @Suite(.serialized)`, `makeRepository()` returning `(Repo, Context, Container)`, `_ = _container` to keep container alive
- `Tests/FMSYSAppTests/ChecklistViewModelTests.swift` — nested in `extension FMSYSTests { @Suite struct ... }`
- Design tokens: `Color.fmsPrimary`, `Color.fmsLoss`, `Color.fmsWarning`, `Color.fmsOnSurface`, `Color.fmsMuted`, `Color.fmsSurface`, `Color.fmsBackground`

---

### Task 1: `Strategy` @Model + update ModelContainer schema

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Core/Models/Strategy.swift`
- Modify: `FMSYSApp/Sources/FMSYSApp/FMSYSApp.swift`
- Create: `FMSYSApp/Tests/FMSYSAppTests/StrategyRepositoryTests.swift` (scaffold only — tests come in Task 2)

**Step 1: Create `Strategy.swift`**

```swift
// Sources/FMSYSCore/Core/Models/Strategy.swift
import Foundation
import SwiftData

public enum StrategyStatus: String, Codable, CaseIterable {
    case active, paused, drafting, archived
}

@Model
public final class Strategy {
    public var id: UUID
    public var userId: String
    public var name: String
    public var indicatorTag: String        // e.g. "EMA Cross + RSI"
    public var statusRaw: String
    public var logicCode: String
    public var emaFastPeriod: Int
    public var emaSlowPeriod: Int
    public var riskMgmtEnabled: Bool
    public var trailingStopEnabled: Bool
    public var winRate: Double?
    public var profitFactor: Double?
    public var createdAt: Date
    public var updatedAt: Date

    public var status: StrategyStatus {
        get { StrategyStatus(rawValue: statusRaw) ?? .drafting }
        set { statusRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        userId: String,
        name: String,
        indicatorTag: String = "",
        status: StrategyStatus = .drafting,
        logicCode: String = "",
        emaFastPeriod: Int = 9,
        emaSlowPeriod: Int = 21,
        riskMgmtEnabled: Bool = false,
        trailingStopEnabled: Bool = false,
        winRate: Double? = nil,
        profitFactor: Double? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.indicatorTag = indicatorTag
        self.statusRaw = status.rawValue
        self.logicCode = logicCode
        self.emaFastPeriod = emaFastPeriod
        self.emaSlowPeriod = emaSlowPeriod
        self.riskMgmtEnabled = riskMgmtEnabled
        self.trailingStopEnabled = trailingStopEnabled
        self.winRate = winRate
        self.profitFactor = profitFactor
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

**Step 2: Update `FMSYSApp.swift` to include `Strategy.self` in the ModelContainer schema**

Find this line in `FMSYSApp/Sources/FMSYSApp/FMSYSApp.swift`:
```swift
return try ModelContainer(for: Trade.self, configurations: config)
```
Replace with:
```swift
return try ModelContainer(for: Trade.self, Strategy.self, configurations: config)
```

**Step 3: Scaffold `StrategyRepositoryTests.swift`** with a compilation-check test:

```swift
// Tests/FMSYSAppTests/StrategyRepositoryTests.swift
import Foundation
import SwiftData
import Testing
@testable import FMSYSCore

@MainActor
@Suite(.serialized)
struct StrategyRepositoryTests {

    private func makeContainer() throws -> (ModelContext, ModelContainer) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Strategy.self, configurations: config)
        return (container.mainContext, container)
    }

    @Test func strategyModelInitializesCorrectly() throws {
        let (_, _container) = try makeContainer()
        _ = _container
        let s = Strategy(userId: "u1", name: "Test", indicatorTag: "EMA", status: .active)
        #expect(s.name == "Test")
        #expect(s.status == .active)
        #expect(s.emaFastPeriod == 9)
        #expect(s.emaSlowPeriod == 21)
        #expect(s.winRate == nil)
    }
}
```

**Step 4: Build and run test**

```bash
cd FMSYSApp && swift test --filter StrategyRepositoryTests 2>&1 | tail -10
```
Expected: 1 test passes.

**Step 5: Commit**

```bash
git add Sources/FMSYSCore/Core/Models/Strategy.swift \
        Sources/FMSYSApp/FMSYSApp.swift \
        Tests/FMSYSAppTests/StrategyRepositoryTests.swift
git commit -m "feat: add Strategy SwiftData model and StrategyStatus enum"
```

---

### Task 2: `StrategyRepository` + tests

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Core/Repositories/StrategyRepository.swift`
- Modify: `FMSYSApp/Tests/FMSYSAppTests/StrategyRepositoryTests.swift`

**Step 1: Write failing tests** — append to `StrategyRepositoryTests.swift`:

```swift
// Add private factory inside StrategyRepositoryTests
private func makeRepository() throws -> (StrategyRepository, ModelContext, ModelContainer) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: Strategy.self, configurations: config)
    let context = container.mainContext
    return (StrategyRepository(context: context), context, container)
}

private func makeStrategy(
    userId: String = "u1",
    name: String = "Test Strategy",
    status: StrategyStatus = .active
) -> Strategy {
    Strategy(userId: userId, name: name, indicatorTag: "EMA", status: status)
}

@Test func insertAndFindAll() throws {
    let (sut, _, _container) = try makeRepository()
    _ = _container
    let s = makeStrategy()
    try sut.insert(s)
    let all = try sut.findAll(userId: "u1")
    #expect(all.count == 1)
    #expect(all.first?.name == "Test Strategy")
}

@Test func findAllFiltersByUserId() throws {
    let (sut, _, _container) = try makeRepository()
    _ = _container
    try sut.insert(makeStrategy(userId: "u1"))
    try sut.insert(makeStrategy(userId: "u2"))
    let result = try sut.findAll(userId: "u1")
    #expect(result.count == 1)
}

@Test func findAllByStatusFilters() throws {
    let (sut, _, _container) = try makeRepository()
    _ = _container
    try sut.insert(makeStrategy(status: .active))
    try sut.insert(makeStrategy(status: .paused))
    try sut.insert(makeStrategy(status: .drafting))
    let active = try sut.findAll(userId: "u1", status: .active)
    #expect(active.count == 1)
    #expect(active.first?.status == .active)
}

@Test func deleteRemovesStrategy() throws {
    let (sut, _, _container) = try makeRepository()
    _ = _container
    let s = makeStrategy()
    try sut.insert(s)
    try sut.delete(s)
    let all = try sut.findAll(userId: "u1")
    #expect(all.isEmpty)
}
```

**Step 2: Run tests to confirm they fail**

```bash
swift test --filter StrategyRepositoryTests 2>&1 | tail -10
```
Expected: compile error — `StrategyRepository` not found.

**Step 3: Create `StrategyRepository.swift`**

```swift
// Sources/FMSYSCore/Core/Repositories/StrategyRepository.swift
import Foundation
import SwiftData

public struct StrategyRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func findAll(userId: String) throws -> [Strategy] {
        let uid = userId
        let descriptor = FetchDescriptor<Strategy>(
            predicate: #Predicate { $0.userId == uid },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func findAll(userId: String, status: StrategyStatus) throws -> [Strategy] {
        let uid = userId
        let raw = status.rawValue
        let descriptor = FetchDescriptor<Strategy>(
            predicate: #Predicate { $0.userId == uid && $0.statusRaw == raw },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func insert(_ strategy: Strategy) throws {
        context.insert(strategy)
        try context.save()
    }

    public func save() throws {
        try context.save()
    }

    public func delete(_ strategy: Strategy) throws {
        context.delete(strategy)
        try context.save()
    }
}
```

**Step 4: Run tests to confirm they pass**

```bash
swift test --filter StrategyRepositoryTests 2>&1 | tail -10
```
Expected: 5 tests pass (1 from Task 1 + 4 new).

**Step 5: Commit**

```bash
git add Sources/FMSYSCore/Core/Repositories/StrategyRepository.swift \
        Tests/FMSYSAppTests/StrategyRepositoryTests.swift
git commit -m "feat: add StrategyRepository with CRUD and status filter"
```

---

### Task 3: `StrategyViewModel` + tests

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Features/StrategyLab/StrategyViewModel.swift`
- Create: `FMSYSApp/Tests/FMSYSAppTests/StrategyViewModelTests.swift`

**Step 1: Write failing tests**

```swift
// Tests/FMSYSAppTests/StrategyViewModelTests.swift
import Foundation
import SwiftData
import Testing
@testable import FMSYSCore

extension FMSYSTests {
    @MainActor
    @Suite(.serialized)
    struct StrategyViewModelTests {

        private func makeSUT() throws -> (StrategyViewModel, ModelContainer) {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Strategy.self, configurations: config)
            let repo = StrategyRepository(context: container.mainContext)
            let defaults = UserDefaults(suiteName: "test.strategy.\(UUID().uuidString)")!
            let vm = StrategyViewModel(repository: repo, userId: "u1", defaults: defaults)
            return (vm, container)
        }

        @Test func loadSeeds3StrategiesOnFirstLaunch() throws {
            let (sut, _container) = try makeSUT()
            _ = _container
            sut.load()
            #expect(sut.strategies.count == 3)
        }

        @Test func loadDoesNotSeedTwice() throws {
            let (sut, _container) = try makeSUT()
            _ = _container
            sut.load()
            sut.load()
            #expect(sut.strategies.count == 3)
        }

        @Test func addCreatesNewDraftingStrategy() throws {
            let (sut, _container) = try makeSUT()
            _ = _container
            sut.load()
            let before = sut.strategies.count
            sut.add()
            #expect(sut.strategies.count == before + 1)
            #expect(sut.strategies.first?.status == .drafting)
            #expect(sut.selectedStrategy?.status == .drafting)
        }

        @Test func deleteRemovesStrategyAndUpdatesSelection() throws {
            let (sut, _container) = try makeSUT()
            _ = _container
            sut.load()
            let id = sut.strategies.last!.id
            sut.delete(id: id)
            #expect(sut.strategies.allSatisfy { $0.id != id })
        }

        @Test func updatePersistsChanges() throws {
            let (sut, _container) = try makeSUT()
            _ = _container
            sut.load()
            let strategy = sut.strategies.first!
            strategy.name = "Updated Name"
            sut.update(strategy)
            #expect(sut.strategies.first(where: { $0.id == strategy.id })?.name == "Updated Name")
        }

        @Test func selectedStrategySetToFirstAfterLoad() throws {
            let (sut, _container) = try makeSUT()
            _ = _container
            sut.load()
            #expect(sut.selectedStrategy != nil)
        }
    }
}
```

**Step 2: Run tests to confirm they fail**

```bash
swift test --filter StrategyViewModelTests 2>&1 | tail -10
```
Expected: compile error — `StrategyViewModel` not found.

**Step 3: Create `StrategyViewModel.swift`**

```swift
// Sources/FMSYSCore/Features/StrategyLab/StrategyViewModel.swift
import Foundation
import Observation
import SwiftData

@Observable
public final class StrategyViewModel {
    public var strategies: [Strategy] = []
    public var selectedStrategy: Strategy?
    public var errorMessage: String?

    private let repository: StrategyRepository
    private let userId: String
    private let defaults: UserDefaults

    private static let seededKey = "fmsys.strategySeeded"

    public init(
        repository: StrategyRepository,
        userId: String = "current-user",
        defaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.userId = userId
        self.defaults = defaults
    }

    @MainActor
    public func load() {
        seedIfNeeded()
        do {
            strategies = try repository.findAll(userId: userId)
            if selectedStrategy == nil {
                selectedStrategy = strategies.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func add() {
        let s = Strategy(userId: userId, name: "New Strategy", indicatorTag: "")
        do {
            try repository.insert(s)
            strategies = try repository.findAll(userId: userId)
            selectedStrategy = s
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func update(_ strategy: Strategy) {
        strategy.updatedAt = Date()
        do {
            try repository.save()
            strategies = try repository.findAll(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func delete(id: UUID) {
        guard let s = strategies.first(where: { $0.id == id }) else { return }
        do {
            if selectedStrategy?.id == id { selectedStrategy = nil }
            try repository.delete(s)
            strategies = try repository.findAll(userId: userId)
            if selectedStrategy == nil { selectedStrategy = strategies.first }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Seed

    private func seedIfNeeded() {
        guard !defaults.bool(forKey: Self.seededKey) else { return }
        guard (try? repository.findAll(userId: userId))?.isEmpty == true else {
            defaults.set(true, forKey: Self.seededKey)
            return
        }
        let seed: [(String, String, StrategyStatus, Double?, Double?)] = [
            ("Trend Follower Pro",  "EMA Cross + RSI",      .active,   0.642, 2.14),
            ("Mean Reversion V2",   "Bollinger Band Scalp",  .paused,   0.588, 1.45),
            ("Volatility Breakout", "ATR Expansion",         .drafting, nil,   nil),
        ]
        let logic = "func onBarUpdate() {\n    // Check EMA Cross\n    if ema9.crossAbove(ema21) {\n        if rsi.value > 50 {\n            enterLong(\"L1\")\n        }\n    }\n}"
        for (name, tag, status, wr, pf) in seed {
            let s = Strategy(
                userId: userId,
                name: name,
                indicatorTag: tag,
                status: status,
                logicCode: status == .active ? logic : "",
                riskMgmtEnabled: status == .active,
                winRate: wr,
                profitFactor: pf
            )
            try? repository.insert(s)
        }
        defaults.set(true, forKey: Self.seededKey)
    }
}
```

**Step 4: Run tests**

```bash
swift test --filter StrategyViewModelTests 2>&1 | tail -10
```
Expected: 6 tests pass.

**Step 5: Commit**

```bash
git add Sources/FMSYSCore/Features/StrategyLab/StrategyViewModel.swift \
        Tests/FMSYSAppTests/StrategyViewModelTests.swift
git commit -m "feat: add StrategyViewModel with seed, CRUD, and selection"
```

---

### Task 4: `StrategyCard` view

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Features/StrategyLab/Views/StrategyCard.swift`

No unit tests — pure SwiftUI view. Build verification is the test.

**Step 1: Create `StrategyCard.swift`**

```swift
// Sources/FMSYSCore/Features/StrategyLab/Views/StrategyCard.swift
import SwiftUI
import Charts

public struct StrategyCard: View {
    let strategy: Strategy
    let isSelected: Bool
    let onTap: () -> Void

    private var statusColor: Color {
        switch strategy.status {
        case .active:   return Color.fmsPrimary
        case .paused:   return Color.fmsMuted
        case .drafting: return Color.fmsWarning
        case .archived: return Color.fmsMuted.opacity(0.5)
        }
    }

    private var sparklinePoints: [Double] {
        switch strategy.status {
        case .active:   return [10, 12, 11, 15, 14, 18, 20]
        case .paused:   return [15, 14, 16, 13, 15, 14, 15]
        case .drafting: return [10, 10, 11, 10, 12, 11, 13]
        case .archived: return [20, 18, 15, 12, 10, 8, 7]
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(strategy.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text(strategy.indicatorTag.isEmpty ? "No indicator" : strategy.indicatorTag)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.fmsMuted)
                        .textCase(.uppercase)
                }
                Spacer()
                statusBadge
            }
            .padding(.bottom, 12)

            // Sparkline
            Chart {
                ForEach(Array(sparklinePoints.enumerated()), id: \.offset) { idx, val in
                    LineMark(
                        x: .value("t", idx),
                        y: .value("v", val)
                    )
                    .foregroundStyle(statusColor)
                    .lineStyle(strategy.status == .drafting
                        ? StrokeStyle(lineWidth: 1.5, dash: [4])
                        : StrokeStyle(lineWidth: 1.5))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 48)
            .opacity(strategy.status == .paused ? 0.6 : 1.0)
            .padding(.bottom, 12)

            // Metrics
            Divider()
                .overlay(Color.fmsMuted.opacity(0.1))
                .padding(.bottom, 8)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(strategy.status == .drafting ? "EXP. WIN RATE" : "WIN RATE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.fmsMuted)
                    Text(strategy.winRate.map { String(format: "%.1f%%", $0 * 100) } ?? "—")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(strategy.status == .drafting ? "RR RATIO" : "PROFIT FACTOR")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.fmsMuted)
                    Text(strategy.profitFactor.map { String(format: "%.2f", $0) } ?? "—")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                }
            }
        }
        .padding(16)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? Color.fmsPrimary.opacity(0.5) : Color.fmsMuted.opacity(0.1),
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var statusBadge: some View {
        Text(strategy.status.rawValue.capitalized)
            .font(.system(size: 9, weight: .bold))
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15), in: Capsule())
            .foregroundStyle(statusColor)
    }
}
```

**Step 2: Build**

```bash
swift build 2>&1 | tail -10
```
Expected: build succeeds.

**Step 3: Commit**

```bash
git add Sources/FMSYSCore/Features/StrategyLab/Views/StrategyCard.swift
git commit -m "feat: add StrategyCard with sparkline and status badge"
```

---

### Task 5: `StrategyInspectorPanel` view

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Features/StrategyLab/Views/StrategyInspectorPanel.swift`

**Step 1: Create `StrategyInspectorPanel.swift`**

```swift
// Sources/FMSYSCore/Features/StrategyLab/Views/StrategyInspectorPanel.swift
import SwiftUI

public struct StrategyInspectorPanel: View {
    @Bindable var viewModel: StrategyViewModel

    public var body: some View {
        if let strategy = viewModel.selectedStrategy {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 24) {
                    logicSection(strategy: strategy)
                    parametersSection(strategy: strategy)
                    Button {
                        viewModel.update(strategy)
                        // TODO: trigger real backtest in future phase
                    } label: {
                        Text("Run Backtest")
                            .font(.system(size: 13, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(Color.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
        } else {
            ContentUnavailableView(
                "No Strategy Selected",
                systemImage: "flask",
                description: Text("Select a strategy to inspect its logic and parameters.")
            )
        }
    }

    @ViewBuilder
    private func logicSection(strategy: Strategy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Strategy Logic", systemImage: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)

            TextEditor(text: Binding(
                get: { strategy.logicCode },
                set: { strategy.logicCode = $0 }
            ))
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(Color(red: 0.788, green: 0.820, blue: 0.855))
            .scrollContentBackground(.hidden)
            .padding(10)
            .frame(minHeight: 140)
            .background(Color(hex: "#1e1e1e"), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func parametersSection(strategy: Strategy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Parameters", systemImage: "slider.horizontal.3")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)

            parameterSlider(
                label: "EMA Fast Period",
                value: Binding(
                    get: { Double(strategy.emaFastPeriod) },
                    set: { strategy.emaFastPeriod = Int($0) }
                ),
                range: 1...50
            )
            parameterSlider(
                label: "EMA Slow Period",
                value: Binding(
                    get: { Double(strategy.emaSlowPeriod) },
                    set: { strategy.emaSlowPeriod = Int($0) }
                ),
                range: 1...100
            )

            Divider().overlay(Color.fmsMuted.opacity(0.1))

            Toggle(isOn: Binding(
                get: { strategy.riskMgmtEnabled },
                set: { strategy.riskMgmtEnabled = $0 }
            )) {
                Text("Risk Management")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsOnSurface.opacity(0.7))
            }
            .tint(Color.fmsPrimary)

            Toggle(isOn: Binding(
                get: { strategy.trailingStopEnabled },
                set: { strategy.trailingStopEnabled = $0 }
            )) {
                Text("Trailing Stop")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsOnSurface.opacity(0.7))
            }
            .tint(Color.fmsPrimary)
        }
    }

    @ViewBuilder
    private func parameterSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsOnSurface.opacity(0.7))
                Spacer()
                Text(String(Int(value.wrappedValue)))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
            }
            Slider(value: value, in: range, step: 1)
                .tint(Color.fmsPrimary)
        }
    }
}
```

**Step 2: Build**

```bash
swift build 2>&1 | tail -10
```
Expected: build succeeds.

**Step 3: Commit**

```bash
git add Sources/FMSYSCore/Features/StrategyLab/Views/StrategyInspectorPanel.swift
git commit -m "feat: add StrategyInspectorPanel with code editor, sliders, and toggles"
```

---

### Task 6: `StrategyLabView` full rewrite + wire in `MainAppView`

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/StrategyLab/Views/StrategyLabView.swift`
- Modify: `FMSYSApp/Sources/FMSYSCore/App/MainAppView.swift`

**Step 1: Rewrite `StrategyLabView.swift`**

```swift
// Sources/FMSYSCore/Features/StrategyLab/Views/StrategyLabView.swift
import SwiftUI
import SwiftData

public struct StrategyLabView: View {
    @State private var viewModel: StrategyViewModel

    public init(modelContainer: ModelContainer) {
        let repo = StrategyRepository(context: modelContainer.mainContext)
        self._viewModel = State(wrappedValue: StrategyViewModel(repository: repo))
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    public var body: some View {
        HSplitView {
            mainContent
            inspectorPanel
        }
        .task { viewModel.load() }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            header
            if viewModel.strategies.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.strategies) { strategy in
                            StrategyCard(
                                strategy: strategy,
                                isSelected: viewModel.selectedStrategy?.id == strategy.id,
                                onTap: { viewModel.selectedStrategy = strategy }
                            )
                        }
                    }
                    .padding(24)
                }
            }
        }
        .frame(minWidth: 400)
        .background(Color.fmsBackground)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Strategy Lab")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Text("Develop, test, and optimize algorithmic models")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
            }
            Spacer()
            Button {
                viewModel.add()
            } label: {
                Label("New Strategy", systemImage: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.fmsOnSurface, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color.fmsBackground)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
    }

    private var inspectorPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Inspector")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.fmsMuted)
            }
            .padding(16)
            Divider().overlay(Color.fmsMuted.opacity(0.1))
            StrategyInspectorPanel(viewModel: viewModel)
        }
        .frame(width: 320)
        .background(Color.fmsSurface.opacity(0.5))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "flask.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.fmsMuted.opacity(0.4))
            Text("Create Your First Strategy")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.fmsOnSurface)
            Text("Build, test, and optimize your algorithmic trading strategies.")
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsMuted)
                .multilineTextAlignment(.center)
            Button("New Strategy") { viewModel.add() }
                .buttonStyle(.borderedProminent)
                .tint(Color.fmsPrimary)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

**Step 2: Update `MainAppView.swift`**

In the `screenContent` computed property, find:
```swift
case .strategyLab:
    StrategyLabView()
```
Replace with:
```swift
case .strategyLab:
    StrategyLabView(modelContainer: modelContainer)
```

**Step 3: Build**

```bash
swift build 2>&1 | tail -10
```
Expected: build succeeds.

**Step 4: Run all tests**

```bash
swift test 2>&1 | tail -5
```
Expected: all existing tests still pass.

**Step 5: Commit**

```bash
git add Sources/FMSYSCore/Features/StrategyLab/Views/StrategyLabView.swift \
        Sources/FMSYSCore/App/MainAppView.swift
git commit -m "feat: rewrite StrategyLabView with card grid and inspector panel"
```

---

### Task 7: `PortfolioViewModel` + tests

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Features/Portfolio/PortfolioViewModel.swift`
- Create: `FMSYSApp/Tests/FMSYSAppTests/PortfolioViewModelTests.swift`

**Step 1: Write failing tests**

```swift
// Tests/FMSYSAppTests/PortfolioViewModelTests.swift
import Foundation
import Testing
@testable import FMSYSCore

extension FMSYSTests {
    @Suite
    struct PortfolioViewModelTests {

        @Test func kpiValuesMatchStubs() {
            let sut = PortfolioViewModel()
            #expect(sut.totalNetLiquidity == 142_500.42)
            #expect(sut.dailyPnL == 1_842.20)
            #expect(sut.buyingPower == 58_210.15)
        }

        @Test func defaultRangeIsYTD() {
            let sut = PortfolioViewModel()
            #expect(sut.selectedRange == .ytd)
        }

        @Test func performanceCurveHasPoints() {
            let sut = PortfolioViewModel()
            #expect(sut.performanceCurve.count > 0)
        }

        @Test func positionsContainsThreeStubs() {
            let sut = PortfolioViewModel()
            #expect(sut.positions.count == 3)
            let symbols = sut.positions.map { $0.id }
            #expect(symbols.contains("AAPL"))
            #expect(symbols.contains("MSFT"))
            #expect(symbols.contains("BTC"))
        }

        @Test func allocationPercentsApproximatelySum100() {
            let sut = PortfolioViewModel()
            let total = sut.allocation.reduce(0) { $0 + $1.percent }
            #expect(abs(total - 1.0) < 0.01)
        }

        @Test func riskMetricsArePositive() {
            let sut = PortfolioViewModel()
            #expect(sut.betaWeighting > 0)
            #expect(sut.marginUtilization > 0)
            #expect(sut.marginUtilization <= 1.0)
        }
    }
}
```

**Step 2: Run tests to confirm they fail**

```bash
swift test --filter PortfolioViewModelTests 2>&1 | tail -10
```
Expected: compile error — `PortfolioViewModel` not found.

**Step 3: Create `PortfolioViewModel.swift`**

```swift
// Sources/FMSYSCore/Features/Portfolio/PortfolioViewModel.swift
import Foundation
import Observation
import SwiftUI

// MARK: - Supporting types

public struct PortfolioPosition: Identifiable {
    public let id: String        // ticker symbol
    public let name: String
    public let qty: Double
    public let lastPrice: Double
    public let marketValue: Double
    public let unrealizedPnL: Double
}

public struct AllocationSlice: Identifiable {
    public let id: String
    public let name: String
    public let percent: Double   // 0.0 – 1.0
    public let color: Color
}

public enum PortfolioRange: String, CaseIterable {
    case oneMonth    = "1M"
    case threeMonths = "3M"
    case ytd         = "YTD"
    case all         = "ALL"
}

// MARK: - PortfolioViewModel

@Observable
public final class PortfolioViewModel {
    public let totalNetLiquidity: Double = 142_500.42
    public let dailyPnL: Double          = 1_842.20
    public let buyingPower: Double       = 58_210.15
    public var selectedRange: PortfolioRange = .ytd
    public let betaWeighting: Double     = 1.12
    public let marginUtilization: Double = 0.32

    public var performanceCurve: [EquityPoint] {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(from: cal.dateComponents([.year], from: now))!
        let values: [Double] = [100_000, 108_000, 115_000, 112_000, 128_000, 135_000, 142_500]
        let step = now.timeIntervalSince(start) / Double(values.count - 1)
        return values.enumerated().map { idx, val in
            EquityPoint(date: start.addingTimeInterval(Double(idx) * step), value: val)
        }
    }

    public let positions: [PortfolioPosition] = [
        PortfolioPosition(id: "AAPL", name: "Apple Inc.",      qty: 150,  lastPrice: 192.42,     marketValue: 28_863.00, unrealizedPnL:  1_420.15),
        PortfolioPosition(id: "MSFT", name: "Microsoft Corp.", qty: 45,   lastPrice: 425.22,     marketValue: 19_134.90, unrealizedPnL:    682.40),
        PortfolioPosition(id: "BTC",  name: "Bitcoin",         qty: 0.82, lastPrice: 64_310.00,  marketValue: 52_734.20, unrealizedPnL:   -412.00),
    ]

    public let allocation: [AllocationSlice] = [
        AllocationSlice(id: "Stocks", name: "Stocks", percent: 0.452, color: Color(red: 0.231, green: 0.510, blue: 0.965)),
        AllocationSlice(id: "ETFs",   name: "ETFs",   percent: 0.248, color: Color.fmsPrimary),
        AllocationSlice(id: "Crypto", name: "Crypto", percent: 0.195, color: Color(red: 1.0,   green: 0.584, blue: 0.0)),
        AllocationSlice(id: "Forex",  name: "Forex",  percent: 0.105, color: Color(red: 0.663, green: 0.329, blue: 1.0)),
    ]
}
```

**Note on colors:** `AllocationSlice` colors use explicit RGB values to avoid coupling to platform system colors. They approximate the design prototype's blue/orange/purple per asset class.

**Step 4: Run tests**

```bash
swift test --filter PortfolioViewModelTests 2>&1 | tail -10
```
Expected: 6 tests pass.

**Step 5: Commit**

```bash
git add Sources/FMSYSCore/Features/Portfolio/PortfolioViewModel.swift \
        Tests/FMSYSAppTests/PortfolioViewModelTests.swift
git commit -m "feat: add PortfolioViewModel with stub positions and allocation"
```

---

### Task 8: `PortfolioInspectorPanel` view

**Files:**
- Create: `FMSYSApp/Sources/FMSYSCore/Features/Portfolio/Views/PortfolioInspectorPanel.swift`

**Step 1: Create `PortfolioInspectorPanel.swift`**

```swift
// Sources/FMSYSCore/Features/Portfolio/Views/PortfolioInspectorPanel.swift
import SwiftUI

// MARK: - Donut Chart

struct AllocationDonutView: View {
    let slices: [AllocationSlice]

    var body: some View {
        ZStack {
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 8
                let lineWidth: CGFloat = 8
                let gapAngle: Double = 0.04
                var startAngle = -Double.pi / 2
                let total = slices.reduce(0) { $0 + $1.percent }
                for slice in slices {
                    let sweep = (slice.percent / total) * (2 * .pi) - gapAngle
                    let path = Path { p in
                        p.addArc(center: center, radius: radius,
                                 startAngle: .radians(startAngle),
                                 endAngle: .radians(startAngle + sweep),
                                 clockwise: false)
                    }
                    ctx.stroke(path, with: .color(slice.color),
                               style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    startAngle += sweep + gapAngle
                }
            }
            .frame(width: 160, height: 160)

            VStack(spacing: 2) {
                Text("Total Assets")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                    .textCase(.uppercase)
                Text("$142k")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Color.fmsOnSurface)
            }
        }
    }
}

// MARK: - Inspector Panel

public struct PortfolioInspectorPanel: View {
    let viewModel: PortfolioViewModel

    public var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 28) {
                allocationSection
                Divider().overlay(Color.fmsMuted.opacity(0.1))
                riskSection
            }
            .padding(20)
        }
    }

    private var allocationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Asset Allocation")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)
                .tracking(1)

            HStack {
                Spacer()
                AllocationDonutView(slices: viewModel.allocation)
                Spacer()
            }

            VStack(spacing: 10) {
                ForEach(viewModel.allocation) { slice in
                    HStack {
                        Circle()
                            .fill(slice.color)
                            .frame(width: 10, height: 10)
                        Text(slice.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.fmsOnSurface)
                        Spacer()
                        Text(String(format: "%.1f%%", slice.percent * 100))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.fmsOnSurface)
                    }
                }
            }
        }
    }

    private var riskSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Exposure")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)
                .tracking(1)

            riskBar(
                label: "Beta Weighting (SPY)",
                fillFraction: viewModel.betaWeighting / 2.0,
                displayValue: String(format: "%.2f", viewModel.betaWeighting),
                color: Color(red: 0.231, green: 0.510, blue: 0.965)
            )
            riskBar(
                label: "Margin Utilization",
                fillFraction: viewModel.marginUtilization,
                displayValue: String(format: "%.0f%%", viewModel.marginUtilization * 100),
                color: Color.fmsPrimary
            )
        }
    }

    @ViewBuilder
    private func riskBar(label: String, fillFraction: Double, displayValue: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Text(displayValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.fmsMuted.opacity(0.15))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * max(0, min(1, fillFraction)), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}
```

**Step 2: Build**

```bash
swift build 2>&1 | tail -10
```
Expected: build succeeds.

**Step 3: Commit**

```bash
git add Sources/FMSYSCore/Features/Portfolio/Views/PortfolioInspectorPanel.swift
git commit -m "feat: add PortfolioInspectorPanel with allocation donut and risk bars"
```

---

### Task 9: `PortfolioView` full rewrite

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/Features/Portfolio/Views/PortfolioView.swift`

**Step 1: Rewrite `PortfolioView.swift`**

```swift
// Sources/FMSYSCore/Features/Portfolio/Views/PortfolioView.swift
import SwiftUI
import Charts

public struct PortfolioView: View {
    @State private var viewModel = PortfolioViewModel()

    public init() {}

    public var body: some View {
        HSplitView {
            mainContent
            PortfolioInspectorPanel(viewModel: viewModel)
                .frame(width: 320)
                .background(Color.fmsSurface.opacity(0.3))
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView(.vertical) {
            VStack(spacing: 24) {
                kpiRow
                performanceCard
                positionsCard
            }
            .padding(24)
        }
        .frame(minWidth: 400)
        .background(Color.fmsBackground)
    }

    // MARK: - KPI Row

    private var kpiRow: some View {
        HStack(spacing: 16) {
            kpiCard(title: "Total Net Liquidity",
                    value: formatted(viewModel.totalNetLiquidity),
                    valueColor: Color.fmsOnSurface)
            kpiCard(title: "Daily P/L",
                    value: "+\(formatted(viewModel.dailyPnL))",
                    subtitle: "(+1.31%)",
                    valueColor: Color.fmsPrimary)
            kpiCard(title: "Buying Power",
                    value: formatted(viewModel.buyingPower),
                    valueColor: Color.fmsOnSurface)
        }
    }

    @ViewBuilder
    private func kpiCard(
        title: String,
        value: String,
        subtitle: String? = nil,
        valueColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)
                .tracking(0.5)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 22, weight: .heavy).monospacedDigit())
                    .foregroundStyle(valueColor)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(valueColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fmsMuted.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Performance Chart

    private var performanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Portfolio Performance")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("Cumulative account value growth")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                rangePicker
            }

            Chart(viewModel.performanceCurve) { point in
                AreaMark(x: .value("Date", point.date), y: .value("Value", point.value))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.fmsPrimary.opacity(0.15), Color.fmsPrimary.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    ))
                LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                    .foregroundStyle(Color.fmsPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.fmsMuted)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 220)
        }
        .padding(20)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fmsMuted.opacity(0.1), lineWidth: 1))
    }

    private var rangePicker: some View {
        HStack(spacing: 2) {
            ForEach(PortfolioRange.allCases, id: \.self) { range in
                Button {
                    viewModel.selectedRange = range
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            viewModel.selectedRange == range
                                ? Color.fmsSurface
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                        .foregroundStyle(Color.fmsOnSurface)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.fmsMuted.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Positions Table

    private var positionsCard: some View {
        VStack(spacing: 0) {
            positionsHeader
            columnHeaders
            VStack(spacing: 0) {
                ForEach(viewModel.positions) { position in
                    positionRow(position)
                    if position.id != viewModel.positions.last?.id {
                        Divider().overlay(Color.fmsMuted.opacity(0.08))
                    }
                }
            }
        }
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fmsMuted.opacity(0.1), lineWidth: 1))
    }

    private var positionsHeader: some View {
        HStack {
            Text("Current Positions")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
            Button("View All Positions") {}
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(red: 0.231, green: 0.510, blue: 0.965))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) { Divider().overlay(Color.fmsMuted.opacity(0.1)) }
    }

    private var columnHeaders: some View {
        HStack {
            Text("Symbol").frame(maxWidth: .infinity, alignment: .leading)
            Text("Qty").frame(width: 80, alignment: .trailing)
            Text("Last Price").frame(width: 100, alignment: .trailing)
            Text("Market Value").frame(width: 110, alignment: .trailing)
            Text("Unrealized P/L").frame(width: 120, alignment: .trailing)
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(Color.fmsMuted)
        .textCase(.uppercase)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.fmsMuted.opacity(0.05))
        .overlay(alignment: .bottom) { Divider().overlay(Color.fmsMuted.opacity(0.1)) }
    }

    @ViewBuilder
    private func positionRow(_ position: PortfolioPosition) -> some View {
        HStack {
            HStack(spacing: 8) {
                symbolBadge(for: position)
                Text(position.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(String(format: position.qty < 1 ? "%.2f" : "%.0f", position.qty))
                .frame(width: 80, alignment: .trailing)
            Text(formatted(position.lastPrice))
                .frame(width: 100, alignment: .trailing)
            Text(formatted(position.marketValue))
                .frame(width: 110, alignment: .trailing)
            Text((position.unrealizedPnL >= 0 ? "+" : "") + formatted(abs(position.unrealizedPnL)))
                .foregroundStyle(position.unrealizedPnL >= 0 ? Color.fmsPrimary : Color.fmsLoss)
                .frame(width: 120, alignment: .trailing)
        }
        .font(.system(size: 12))
        .foregroundStyle(Color.fmsOnSurface)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func symbolBadge(for position: PortfolioPosition) -> some View {
        let badgeColor: Color = switch position.id {
            case "AAPL": Color(red: 1.0,   green: 0.584, blue: 0.0)
            case "MSFT": Color(red: 0.231, green: 0.510, blue: 0.965)
            default:     Color.fmsMuted
        }
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(badgeColor.opacity(0.2))
                .frame(width: 28, height: 28)
            Text(position.id)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(badgeColor)
        }
    }

    // MARK: - Helpers

    private func formatted(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "$"
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}
```

**Step 2: Build and run all tests**

```bash
swift build 2>&1 | tail -5
swift test 2>&1 | tail -5
```
Expected: build succeeds, all tests pass.

**Step 3: Commit**

```bash
git add Sources/FMSYSCore/Features/Portfolio/Views/PortfolioView.swift
git commit -m "feat: rewrite PortfolioView with KPI cards, chart, positions table, and inspector"
```

---

### Task 10: Sidebar context-aware bottom card

The sidebar currently shows a static `equityCard` regardless of selected screen. This task replaces it with a `@ViewBuilder` switch keyed on `selection`.

**Files:**
- Modify: `FMSYSApp/Sources/FMSYSCore/App/SidebarView.swift`

**Step 1: Replace the bottom card in `SidebarView.swift`**

The current `SidebarView.body` ends with:
```swift
equityCard
```
inside the outer `VStack`.

Replace `equityCard` with:
```swift
bottomCard(for: selection)
```

Add these methods replacing the existing `equityCard` computed var:

```swift
@ViewBuilder
private func bottomCard(for screen: AppScreen) -> some View {
    switch screen {
    case .strategyLab:
        strategyLabCard
    case .portfolio:
        portfolioCard
    default:
        equityCard
    }
}

private var equityCard: some View {
    VStack(alignment: .leading, spacing: 4) {
        Text("Total Equity")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Color.fmsMuted)
        Text("$0.00")
            .font(.system(size: 18, weight: .bold).monospacedDigit())
            .foregroundStyle(Color.fmsOnSurface)
        Text("MTD  —")
            .font(.system(size: 11))
            .foregroundStyle(Color.fmsMuted)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.fmsPrimary.opacity(0.3), lineWidth: 1)
    )
    .padding(12)
}

private var strategyLabCard: some View {
    VStack(alignment: .leading, spacing: 4) {
        Text("Active Labs")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Color.fmsPrimary)
            .textCase(.uppercase)
            .tracking(0.5)
        Text("4 Running")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(Color.fmsOnSurface)
        HStack(spacing: 4) {
            Image(systemName: "memorychip")
                .font(.system(size: 10))
            Text("82% CPU Usage")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(Color.fmsPrimary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(
        LinearGradient(
            colors: [Color.fmsPrimary.opacity(0.1), Color.clear],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ),
        in: RoundedRectangle(cornerRadius: 12)
    )
    .overlay(
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.fmsPrimary.opacity(0.2), lineWidth: 1)
    )
    .padding(12)
}

private var portfolioCard: some View {
    VStack(alignment: .leading, spacing: 4) {
        Text("Total Equity")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Color.fmsPrimary)
            .textCase(.uppercase)
            .tracking(0.5)
        Text("$142,500.42")
            .font(.system(size: 18, weight: .bold).monospacedDigit())
            .foregroundStyle(Color.fmsOnSurface)
        HStack(spacing: 4) {
            Image(systemName: "arrow.up")
                .font(.system(size: 10))
            Text("+12.5% MTD")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(Color.fmsPrimary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(
        LinearGradient(
            colors: [Color.fmsPrimary.opacity(0.1), Color.clear],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ),
        in: RoundedRectangle(cornerRadius: 12)
    )
    .overlay(
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.fmsPrimary.opacity(0.2), lineWidth: 1)
    )
    .padding(12)
}
```

**Step 2: Build and run all tests**

```bash
swift build 2>&1 | tail -5
swift test 2>&1 | tail -5
```
Expected: build succeeds, all tests pass.

**Step 3: Commit**

```bash
git add Sources/FMSYSCore/App/SidebarView.swift
git commit -m "feat: context-aware sidebar bottom card for Strategy Lab and Portfolio"
```

---

## Final Verification

After all 10 tasks:

```bash
swift test 2>&1 | tail -5
```
Expected output: `Test run with N tests in M suites passed after X seconds.`
(159 existing + ~17 new = ~176 tests)

Then delete the HTML prototype files:
```bash
rm /Users/stevy/Documents/Git/TLSuite/strategy_lab.html \
   /Users/stevy/Documents/Git/TLSuite/portfolio.html
git add -A
git commit -m "chore: remove strategy_lab.html and portfolio.html prototypes"
```
