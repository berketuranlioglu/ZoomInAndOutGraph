//
//  MainViewModel.swift
//  ZoomInAndOutGraph
//
//  Created by Berke Turanlioglu on 26.12.2023.
//

import Foundation
import SwiftUI
import Charts

class MainViewModel: ObservableObject {
    
    @Published var isLoading: Bool = true
    // @Published var sleepModelData: [SleepModel] = []
    @Published var sleepNewModelData: [SleepNewModel] = []
    @Published var shownXAxis: [String] = [] {
        didSet {
            print("shownXAxis: \(shownXAxis)")
        }
    }
    @Published var minTime: Int = 0
    @Published var maxTimeInterval: Int = 0
    @Published var selectedTime: String?
    @Published var selectedLevel: Int?
    @Published var selectedCategory: String?
    
    private var sleepData: [SleepData] = []
    private let fileDirectory = "dump_graph"
    private let maxZoomBarCount: Int = 39
    
    func decodeJSON() {
        isLoading = true
        if let url = Bundle.main.url(forResource: fileDirectory, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let jsonData = try decoder.decode([SleepData].self, from: data)
                sleepData = jsonData
                // convertToSleepModel()
                convertToSleepNewModel()
                updateXAxis()
            } catch {
                fatalError("error:\(error)")
            }
        } else {
            fatalError("No file found!")
        }
    }
    
    /*
     private func convertToSleepModel() {
     for datum in sleepData {
     var dummyDate = datum.datetime
     dummyDate.removeLast(4)
     dummyDate += "+00:00"
     if let convertedDate = ISO8601DateFormatter().date(from: dummyDate) {
     let newDatum = SleepModel(max_db: datum.max_db, datetime: convertedDate, category: datum.category)
     sleepModelData.append(newDatum)
     } else {
     fatalError("Date conversion error, aborted")
     }
     }
     maxTimeInterval = sleepModelData.count - 1
     isLoading = false
     }
     */
    
    private func convertToSleepNewModel() {
        for datum in sleepData {
            var dummyDate = datum.datetime
            dummyDate.removeLast(4)
            dummyDate += "+00:00"
            if let convertedDate = ISO8601DateFormatter().date(from: dummyDate) {
                let calendar = Calendar.current
                let corrHour = calendar.component(.hour, from: convertedDate)
                let hour = corrHour < 10 ? "0\(corrHour)" : "\(corrHour)"
                let corrMinute = calendar.component(.minute, from: convertedDate)
                let minute = corrMinute < 10 ? "0\(corrMinute)" : "\(corrMinute)"
                let dateStr = "\(hour):\(minute)"
                let newDatum = SleepNewModel(max_snore_db: datum.max_snore_db, date: convertedDate, datetime: dateStr, category: datum.category)
                sleepNewModelData.append(newDatum)
            } else {
                fatalError("Date conversion error, aborted")
            }
        }
        print(sleepNewModelData)
        maxTimeInterval = sleepNewModelData.count - 1
        isLoading = false
    }
    
    func categoryColor(for category: String) -> Color {
        if category == "Quiet" {
            return Color.green
        } else if category == "Light" {
            return Color.yellow
        } else if category == "Loud" {
            return Color.orange
        }
        return Color.red
    }
    
    // MARK: - Dynamic Values for the chart
    func updateXAxis() {
        if maxTimeInterval == maxZoomBarCount {
            shownXAxis = (0...maxZoomBarCount).map { sleepNewModelData[minTime+$0].datetime }
        } else {
            let step = maxTimeInterval / 4
            shownXAxis = [
                sleepNewModelData[minTime].datetime,
                sleepNewModelData[minTime+step].datetime,
                sleepNewModelData[minTime+step*2].datetime,
                sleepNewModelData[minTime+step*3].datetime,
                sleepNewModelData[minTime+maxTimeInterval].datetime,
            ]
        }
    }
    
    func updateShownData() -> [String] {
        return sleepNewModelData[minTime..<minTime+maxTimeInterval].map { $0.datetime }
    }
    
    // MARK: - Tap Gesture
    /*
     func doSelection(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
     let origin = geometry[proxy.plotAreaFrame].origin
     if let datePos = proxy.value(atX: location.x - origin.x, as: Date.self) {
     let calendar = Calendar.current
     let corrHour = calendar.component(.hour, from: datePos)
     let hour = corrHour < 10 ? "0\(corrHour)" : "\(corrHour)"
     let corrMinute = calendar.component(.minute, from: datePos)
     let minute = corrMinute < 10 ? "0\(corrMinute)" : "\(corrMinute)"
     if let index = sleepModelData.firstIndex(where: {
     calendar.component(.hour, from: $0.datetime) == corrHour &&
     calendar.component(.minute, from: $0.datetime) == corrMinute
     }) {
     selectedTime = "\(hour):\(minute)"
     selectedLevel = Int(sleepModelData[index].max_db)
     selectedCategory = sleepModelData[index].category
     } else {
     print("no index found")
     }
     }
     }
     */
    func doSelection(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let origin = geometry[proxy.plotAreaFrame].origin
        if let datePos = proxy.value(atX: location.x - origin.x, as: String.self) {
            if let index = sleepNewModelData.firstIndex(where: {
                $0.datetime == datePos
            }) {
                selectedTime = datePos
                selectedLevel = Int(sleepNewModelData[index].max_snore_db)
                selectedCategory = sleepNewModelData[index].category
            } else {
                print("no index found")
            }
        }
    }
    
    // MARK: - Zoom Gesture
    func zoomGesture(scale: CGFloat, previousScale: CGFloat, value: CGFloat) {
        if scale > previousScale {
            withAnimation {
                zoomIn(value: value)
            }
        } else {
            withAnimation {
                zoomOut(value: value)
            }
        }
    }
    
    private func zoomIn(value: CGFloat) {
        let newMin = minTime + Int(value)
        let newMax = (sleepNewModelData.count - 1) - newMin * 2
        if newMin < sleepNewModelData.count {
            if newMax >= maxZoomBarCount {
                minTime = newMin
                maxTimeInterval = newMax
                updateXAxis()
            }
        }
    }
    
    private func zoomOut(value: CGFloat) {
        if minTime - abs(Int(value * 4)) > 0 {
            minTime -= abs(Int(value * 4))
            let newMaxTime = maxTimeInterval + abs(Int(value * 4))
            if newMaxTime < sleepNewModelData.count {
                maxTimeInterval = newMaxTime
                updateXAxis()
            } else {
                maxTimeInterval = (sleepNewModelData.count - 1)
                updateXAxis()
            }
        }
    }
    
    // MARK: - Drag Gesture
    func dragGesture(value: DragGesture.Value) {
        if value.translation.width < 0 {
            dragLeft(value: value)
        }
        else {
            dragRight(value: value)
        }
    }
    
    private func dragLeft(value: DragGesture.Value) {
        let newMax: Int = abs(Int(value.translation.width)) / 50
        if minTime + maxTimeInterval + newMax < sleepNewModelData.count {
            minTime += newMax
            updateXAxis()
        } else {
            minTime = sleepNewModelData.count - maxTimeInterval - 1
            updateXAxis()
        }
    }
    
    private func dragRight(value: DragGesture.Value) {
        let newMin: Int = -(Int(value.translation.width) / 50)
        if minTime + newMin > 0 {
            minTime += newMin
            updateXAxis()
        } else {
            minTime = 0
            updateXAxis()
        }
    }
    
    // MARK: - Conditional Strings
    func setSelectedTimeText() -> String {
        if selectedTime != nil {
            return "Selected time: \(selectedTime!)\nLoudness: \(selectedCategory!)"
        }
        return "No time is selected"
    }
}
