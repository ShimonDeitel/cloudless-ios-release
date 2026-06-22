import SwiftUI
import SwiftData

// MARK: - SwiftData Models

@Model
final class WorryEntry {
    var id: UUID
    var date: Date
    var text: String
    var resolved: Bool?
    var cameTrue: Bool?

    init(id: UUID = UUID(), date: Date = Date(), text: String, resolved: Bool? = nil, cameTrue: Bool? = nil) {
        self.id = id
        self.date = date
        self.text = text
        self.resolved = resolved
        self.cameTrue = cameTrue
    }
}

@Model
final class WorryReflection {
    var id: UUID
    var worryId: UUID
    var reviewedOn: Date

    init(id: UUID = UUID(), worryId: UUID, reviewedOn: Date = Date()) {
        self.id = id
        self.worryId = worryId
        self.reviewedOn = reviewedOn
    }
}

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var worries: [WorryEntry] = []
    @Published private(set) var reflections: [WorryReflection] = []

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([WorryEntry.self, WorryReflection.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Fallback to in-memory store
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            if let c = try? ModelContainer(for: schema, configurations: [fallback]) { return c }
            fatalError("Cannot create ModelContainer: \(error)")
        }
    }

    func reload() {
        let ctx = container.mainContext
        let wFetch = FetchDescriptor<WorryEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let rFetch = FetchDescriptor<WorryReflection>(sortBy: [SortDescriptor(\.reviewedOn, order: .reverse)])
        worries = (try? ctx.fetch(wFetch)) ?? []
        reflections = (try? ctx.fetch(rFetch)) ?? []
    }

    func refresh() { reload() }

    // MARK: - Worry CRUD

    /// Returns today's worry entry if one already exists.
    var todaysWorry: WorryEntry? {
        let cal = Calendar.current
        return worries.first { cal.isDateInToday($0.date) }
    }

    func saveWorry(text: String) {
        let ctx = container.mainContext
        // Remove any existing entry for today
        if let existing = todaysWorry {
            ctx.delete(existing)
        }
        let entry = WorryEntry(text: text)
        ctx.insert(entry)
        try? ctx.save()
        reload()
    }

    func dismissWorry(_ entry: WorryEntry) {
        entry.resolved = true
        try? container.mainContext.save()
        reload()
    }

    func markWorry(_ entry: WorryEntry, cameTrue: Bool) {
        entry.resolved = true
        entry.cameTrue = cameTrue
        let ref = WorryReflection(worryId: entry.id)
        container.mainContext.insert(ref)
        try? container.mainContext.save()
        reload()
    }

    // MARK: - Stats

    var thisWeekReleaseCount: Int {
        let cal = Calendar.current
        let now = Date()
        guard let weekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        return worries.filter {
            guard let resolved = $0.resolved, resolved else { return false }
            return $0.date >= weekStart
        }.count
    }

    var totalResolved: Int { worries.filter { $0.resolved == true }.count }
    var totalCameTrue: Int { worries.filter { $0.cameTrue == true }.count }
    var totalNotTrue: Int { worries.filter { $0.resolved == true && $0.cameTrue == false }.count }

    // Pending worries older than 7 days that haven't been reviewed
    var pendingReview: [WorryEntry] {
        let cutoff = Date().addingTimeInterval(-7 * 86400)
        let reviewedIds = Set(reflections.map { $0.worryId })
        return worries.filter {
            $0.date < cutoff && $0.resolved == nil && !reviewedIds.contains($0.id)
        }
    }

    // MARK: - Delete All

    func deleteAllData() {
        let ctx = container.mainContext
        for w in worries { ctx.delete(w) }
        for r in reflections { ctx.delete(r) }
        try? ctx.save()
        reload()
    }
}
