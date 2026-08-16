import Foundation
import HealthKit

@MainActor
final class HealthEarn: ObservableObject {
    static let shared = HealthEarn()
    private let store = HKHealthStore()
    @Published var status = ""

    private var authorized = false

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
            status = "Health authorization failed: \(error.localizedDescription)"
        }
    }

    /// Credits today's steps and exercise minutes, remembering what was already
    /// credited today so repeated syncs only add the delta.
    func syncToday() async {
        await requestAuth()
        let day = ChoreStore.dayKey()
        let steps = await todaySum(.stepCount, unit: .count())
        let exercise = await todaySum(.appleExerciseTime, unit: .minute())

        let stepMinutes = (steps / 1000.0) * SharedConfig.minutesPer1000Steps
        let stepDelta = creditDelta(key: "health.steps.\(day)", newTotal: stepMinutes)
        if stepDelta >= 1 {
            Wallet.earn(stepDelta.rounded(.down), reason: "Steps (\(Int(steps)) today)")
        }
        let exerciseDelta = creditDelta(key: "health.exercise.\(day)", newTotal: exercise)
        if exerciseDelta >= 1 {
            Wallet.earn(exerciseDelta.rounded(.down), reason: "Exercise minutes")
        }
        status = "Today: \(Int(steps)) steps, \(Int(exercise)) exercise min. Credited +\(Int(stepDelta.rounded(.down)) + Int(exerciseDelta.rounded(.down))) min."
    }

    /// Returns how much of `newTotal` has not been credited yet and advances the marker.
    private func creditDelta(key: String, newTotal: Double) -> Double {
        let credited = SharedConfig.store.double(forKey: key)
        let delta = max(0, newTotal - credited)
        if delta >= 1 {
            SharedConfig.store.set(credited + delta.rounded(.down), forKey: key)
        }
        return delta
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
