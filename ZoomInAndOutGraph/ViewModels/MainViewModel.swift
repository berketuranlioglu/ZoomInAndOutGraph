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
    @Published var sleepNewModelData: [SleepNewModel] = []
    @Published var shownXAxis: [String] = []
    @Published var minTime: Int = 0
    @Published var maxTimeInterval: Int = 0
    @Published var selectedTime: Date?
    @Published var selectedLevel: Int?
    @Published var selectedCategory: String?
    
    private var sleepData: [SleepChillData] = []
    private let fileDirectory = "snore-and-chill-data"
    private let maxZoomBarCount: Int = 39
    
    func decodeJSON() {
        isLoading = true
        if let url = Bundle.main.url(forResource: fileDirectory, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode([SleepChillData].self, from: data)
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
    
    private func convertToSleepNewModel() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH-mm-ss"
        for datum in sleepData {
            var dummyDate = datum.rowLabels
            if let convertedDate = dateFormatter.date(from: dummyDate) {
                var max_snore_db: Double? = nil
                var category: String? = nil
                if let epic = datum.epic {
                    max_snore_db = epic
                    category = "Epic"
                } else if let light = datum.light {
                    max_snore_db = light
                    category = "Light"
                } else if let loud = datum.loud {
                    max_snore_db = loud
                    category = "Loud"
                } else if let quiet = datum.quiet {
                    max_snore_db = quiet
                    category = "Quiet"
                }
                let newDatum = SleepNewModel(max_snore_db: max_snore_db, chill: datum.chill, date: convertedDate, datetime: nil, category: category)
                sleepNewModelData.append(newDatum)
            } else {
                fatalError("Date conversion error, aborted")
            }
        }
        maxTimeInterval = sleepNewModelData.count - 1
        isLoading = false
    }
    
    func categoryColor(for category: String?) -> Color {
        if category == nil {
            return Color.clear
        } else if category == "Quiet" {
            return Color.blue.opacity(0.5)
        } else if category == "Light" {
            return Color.yellow
        } else if category == "Loud" {
            return Color.orange
        }
        return Color.red
    }
    
    // MARK: - Dynamic Values for the chart
    func updateXAxis() {
        /*
        if maxTimeInterval == 7 {
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
         */
    }
    
    func updateShownData() -> [String] {
        return sleepNewModelData[minTime..<minTime+maxTimeInterval].map { $0.datetime ?? "" }
    }
    
    // MARK: - Tap Gesture
    func doSelection(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let origin = geometry[proxy.plotAreaFrame].origin
        if let datePos = proxy.value(atX: location.x - origin.x, as: Date.self) {
            let calendar = Calendar.current
            if let index = sleepNewModelData.firstIndex(where: {
                calendar.component(.hour, from: $0.date) == calendar.component(.hour, from: datePos)
                && calendar.component(.minute, from: $0.date) == calendar.component(.minute, from: datePos)
            }) {
                selectedTime = datePos
                selectedLevel = Int(sleepNewModelData[index].max_snore_db ?? 0)
                selectedCategory = sleepNewModelData[index].category
            } else {
                print("no index found")
            }
        } else {
            print("datePos error")
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
        if selectedTime != nil && selectedCategory != nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let strDate = dateFormatter.string(from: selectedTime!)
            return "Selected time: \(strDate)\nLoudness: \(selectedCategory!)"
        }
        return "No time is selected"
    }
}
