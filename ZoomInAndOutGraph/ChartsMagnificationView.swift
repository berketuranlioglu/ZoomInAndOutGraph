//
//  ChartsMagnificationView.swift
//  ZoomInAndOutGraph
//
//  Created by Berke Turanlioglu on 26.12.2023.
//

import SwiftUI
import Charts

struct ChartsMagnificationView: View {
    
    @StateObject var viewModel = MainViewModel()
    @State private var previousScale: CGFloat = 1.0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            if !viewModel.isLoading {
                List {
                    Chart(viewModel.sleepNewModelData, id: \.date) { sleep in
                        AreaMark(
                            x: .value("Time", sleep.date, unit: .minute),
                            y: .value("Chill", sleep.chill ?? 0)
                        )
                        .foregroundStyle(Color.green.opacity(0.4))
                        
                        BarMark(
                            x: .value("Time", sleep.date, unit: .minute),
                            y: .value("Snore level", sleep.max_snore_db ?? 0)
                        )
                        .foregroundStyle(viewModel.categoryColor(for: sleep.category))
                    }
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .onTapGesture { location in
                                    viewModel.doSelection(at: location, proxy: proxy, geometry: geometry)
                                }
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = value.magnitudeSquared
                                            viewModel.zoomGesture(scale: scale, previousScale: previousScale, value: value)
                                            previousScale = scale
                                        }
                                        .simultaneously(with: DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                            .onChanged { value in
                                                viewModel.dragGesture(value: value)
                                            })
                                )
                        }
                    }
                    .chartXAxis {
                        AxisMarks(preset: .aligned, stroke: StrokeStyle(lineWidth: 0))
                    }
                    .chartXAxisLabel(position: .bottomLeading) {
                        Text("Time")
                            .offset(x: 4, y: -20)
                    }
                    .chartXScale(domain: [
                        viewModel.sleepNewModelData[viewModel.minTime].date,
                        viewModel.sleepNewModelData[viewModel.minTime + viewModel.maxTimeInterval].date
                    ])
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [10, 30, 50, 70]) {
                            let value = $0.index
                            AxisValueLabel {
                                Text(["Quiet", "Light", "Loud", "Epic"][value])
                            }
                        }
                        AxisMarks(values: [10, 30, 50, 70]) {
                            AxisGridLine()
                        }
                    }
                    .frame(height: 400)
                    
                    Text(viewModel.setSelectedTimeText())
                }
                .scrollDisabled(true)
            }
        }
        .onAppear {
            viewModel.decodeJSON()
        }
    }
}

#Preview {
    ChartsMagnificationView()
}

