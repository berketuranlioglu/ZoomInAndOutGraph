//
//  ContentView.swift
//  ZoomInAndOutGraph
//
//  Created by Berke Turanlioglu on 25.12.2023.
//

import SwiftUI

struct SleepDataaa {
    let date: Int
    let level: Double
    
    static let data: [SleepDataaa] = (1...30).map {
        SleepDataaa(date: $0, level: Double.random(in: 0...200))
    }
}

struct ContentView: View {
    
    @State private var scaleCoefficient: Double = 0.0
    
    var body: some View {
        ZStack {
            Color(red: 242/255, green: 242/255, blue: 247/255)
                .edgesIgnoringSafeArea(.all)
            
            ZStack {
                // background of the chart
                VStack(alignment: .leading, spacing: 12) {
                    ChartYLabel(label: "Severe")
                    ChartYLabel(label: "Loud")
                    ChartYLabel(label: "Light")
                    ChartYLabel(label: "Quiet")
                    ChartXAxisRow(label: "Time")
                }
                
                // graph data
                HStack(alignment: .bottom) {
                    ForEach(SleepDataaa.data, id: \.date) { sleep in
                        RoundedRectangle(cornerRadius: 8.0)
                            .foregroundStyle(barColor(value: sleep.level))
                            .frame(width: 2 + scaleCoefficient, height: sleep.level)
                    }
                }
                .offset(x: 0 + scaleCoefficient * 5, y: -30)
            }
            .padding(.all)
            .background(Color.white)
            .gesture(
                MagnificationGesture()
                    .onChanged { newValue in
                        if newValue > 1 {
                            scaleCoefficient += newValue * 0.15
                        } else if scaleCoefficient > 0 {
                            scaleCoefficient -= newValue
                        }
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation {
                    if scaleCoefficient == 0.0 {
                        scaleCoefficient = 10
                    } else {
                        scaleCoefficient = 0.0
                    }
                }
            }
        }
    }
    
    func barColor(value: Double) -> Color {
        if value <= 125 {
            return Color(red: 156/255, green: 202/255, blue: 203/255)
        } else if value <= 150 {
            return Color(red: 128/255, green: 172/255, blue: 224/255)
        } else if value <= 175 {
            return Color(red: 113/255, green: 129/255, blue: 234/255)
        }
        return Color(red: 144/255, green: 127/255, blue: 223/255)
    }
}

struct ChartYLabel: View {
    
    let label: String
    
    var body: some View {
        Group {
            Capsule()
                .foregroundStyle(Color.secondary)
                .frame(width: .infinity, height: 1)
            
            Text(label)
                .font(.system(size: 14))
        }
    }
}

struct ChartXAxisRow: View {
    
    let label: String
    
    var body: some View {
        Group {
            Capsule()
                .foregroundStyle(Color.secondary)
                .frame(width: .infinity, height: 2)
            
            HStack {
                Text("Time")
            }
            .font(.system(size: 14))
        }
    }
}

#Preview {
    ContentView()
}
