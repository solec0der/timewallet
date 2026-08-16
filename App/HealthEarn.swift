import Foundation
import HealthKit

@MainActor
final class HealthEarn: ObservableObject {
    static let shared = HealthEarn()
    private let store = HKHealthStore()

    @Published var todaySteps: Double = 0
    @Published var creditedSteps: Double = 0
    let stepsGoal: Double = 8000

    private var authorized = false

    var pendingSteps: Double { max(0, todaySteps - creditedSteps) }

    /// Refreshes today's numbers and silently credits new exercise minutes 1:1.
    func refresh() async {
        await requestAuth()
        let day = DayKey.today()
        todaySteps = await todaySum(.stepCount, unit: .count())
        creditedSteps = SharedConfig.store.double(forKey: "health.stepsCredited.\(day)")

        let exercise = await todaySum(.appleExerciseTime, unit: .minute())
        let exerciseKey = "health.exerciseCredited.\(day)"
        let exerciseCredited = SharedConfig.store.double(forKey: exerciseKey)
        let delta = (exercise - exerciseCredited).rounded(.down)
        if delta >= 1 {
            SharedConfig.store.set(exerciseCredited + delta, forKey: exerciseKey)
            Wallet.earn(delta, reason: "Exercise")
        }
    }

    /// Converts uncredited steps into wallet minutes.
    func collectSteps() {
        let pending = pendingSteps.rounded(.down)
        guard pending >= 1 else { return }
        let day = DayKey.today()
        SharedConfig.store.set(creditedSteps + pending, forKey: "health.stepsCredited.\(day)")
        creditedSteps += pending
        let minutes = ((pending / 1000.0 * SharedConfig.minutesPer1000Steps) * 10).rounded() / 10
        if minutes > 0 {
            Wallet.earn(minutes, reason: "\(Int(pending)) Steps")
        }
    }

    private func requestAuth() async {
        guard !authorized, HKHealthStore.isHealthDataAvailable() else { return }
        let types: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.appleExerciseTime),
        ]
        do {
            try await store.requestAuthorization(toShare: [], read: types)
            authorized = true
        } catch {
            print("Health authorization failed: \(error)")
        }
    }

    private func todaySum(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        await withCheckedContinuation { continuation in
            let start = Calendar.current.startOfDay(for: Date())
            let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
            let query = HKStatisticsQuery(
                quantityType: HKQuantityType(id),
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }
}
