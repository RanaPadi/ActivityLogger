import SwiftUI
import Combine

struct ContentView: View {
    @State private var currentActivity: String?
    @State private var activityStartTime: Date?
    @State private var logs: [ActivityLog] = []
    @State private var timerDisplay: String = "00:00:00"
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
    @State private var timerCancellable: AnyCancellable?

    var body: some View {
        VStack {
            Text("Activity Logger")
                .font(.largeTitle)
                .padding()

            Picker("Select Activity:", selection: $currentActivity) {
                Text("Eating/Drinking").tag("Eating_Drinking" as String?)
                Text("Talking").tag("Talking" as String?)
                Text("Others").tag("Others" as String?)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Button(activityStartTime == nil ? "Start Activity" : "Stop Activity") {
                toggleActivity()
            }
            .padding()
            .background(activityStartTime == nil ? Color.green : Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.bottom, 5)

            Text("Timer: \(timerDisplay)")
                .font(.headline)
                .padding()

            Button("Export CSV") {
                saveCSV()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.bottom, 20)
        }
        .frame(width: 400)
        .padding()
        .onReceive(timer) { _ in
            updateTimerDisplay()
        }
    }

    func toggleActivity() {
        if let startTime = activityStartTime {
            let endTime = Date()
            let log = ActivityLog(activity: currentActivity ?? "Unknown", startTime: startTime, endTime: endTime)
            logs.append(log)
            activityStartTime = nil
            timerDisplay = "00:00:00"
            timerCancellable?.cancel()  // Stop the timer
        } else {
            activityStartTime = Date()
            timerCancellable = timer.autoconnect().sink(receiveValue: { _ in
                updateTimerDisplay()
            })
        }
    }

    func updateTimerDisplay() {
        guard let startTime = activityStartTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        let hours = Int(elapsed) / 3600
        let minutes = Int(elapsed) / 60 % 60
        let seconds = Int(elapsed) % 60
        timerDisplay = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    func saveCSV() {
        let header = "Activity,Start_Date,Start_Time,End_Date,End_Time,Duration\n"
        let csvContent = logs.map { log -> String in
            let duration = Int(log.endTime.timeIntervalSince(log.startTime))
            return "\(log.activity),\(formatDate(log.startTime, includeMilliseconds: false)),\(formatTime(log.startTime)),\(formatDate(log.endTime, includeMilliseconds: false)),\(formatTime(log.endTime)),\(duration) seconds"
        }.joined(separator: "\n")
        let csvText = header + csvContent

        // Get the current date and time for the file name
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        // Create the file name with the timestamp
        let fileName = "ActivityLog_\(timestamp).csv"

        // Specify the directory and full file path
        let customDirectory = URL(fileURLWithPath: "/Users/ranapadi/CIT/MATLAB")
        let fileURL = customDirectory.appendingPathComponent(fileName)

        do {
            try FileManager.default.createDirectory(at: customDirectory, withIntermediateDirectories: true, attributes: nil)
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
            print("CSV saved successfully at \(fileURL.path)")
        } catch {
            print("Failed to save CSV: \(error)")
        }
    }

    func formatDate(_ date: Date, includeMilliseconds: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"  // Format for YYYYMMDD
        return formatter.string(from: date)
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmmssSSS"  // Format for HHmmssSSS (HoursMinutesSecondsMilliseconds)
        return formatter.string(from: date)
    }
}

struct ActivityLog {
    var activity: String
    var startTime: Date
    var endTime: Date
}

