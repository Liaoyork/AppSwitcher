import SwiftUI
import AppKit

// --- 1. 支援動畫的扇形 ---
struct RingSector: Shape {
    var startAngle: Double
    var endAngle: Double
    var innerRadiusRatio: CGFloat
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle, endAngle) }
        set {
            startAngle = newValue.first
            endAngle = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * innerRadiusRatio
        
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: .degrees(startAngle), endAngle: .degrees(endAngle), clockwise: false)
        path.addLine(to: CGPoint(
            x: center.x + innerRadius * cos(CGFloat(Angle.degrees(endAngle).radians)),
            y: center.y + innerRadius * sin(CGFloat(Angle.degrees(endAngle).radians))
        ))
        path.addArc(center: center, radius: innerRadius, startAngle: .degrees(endAngle), endAngle: .degrees(startAngle), clockwise: true)
        path.closeSubpath()
        return path
    }
}

// --- 2. 主視圖 ---
struct ContentView: View {
    @StateObject private var store = AppStore()
    @Binding var isShowing: Bool // 解決傳參報錯
    
    @State private var hoverIndex: UUID? = nil
    @State private var drawingProgress: Double = 0
    @State private var targetStartAngle: Double = 0
    @State private var targetEndAngle: Double = 0
    @State private var highlightOpacity: Double = 0
    
    let radius: CGFloat = 280
    
    var body: some View {
        ZStack {
            // --- 背景層 ---
            ZStack {
                Circle()
                    .glassEffect(.clear) // 使用你程式碼中的正確名稱
                
                RingSector(startAngle: targetStartAngle, endAngle: targetEndAngle, innerRadiusRatio: 0.54)
                    .fill(LinearGradient(colors: [.blue.opacity(0.8), .blue.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                    .opacity(highlightOpacity * drawingProgress)
                    .zIndex(1)
                
                Circle()
                    .trim(from: 0, to: drawingProgress)
                    .stroke(LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: radius * 1.15, height: radius * 1.15)
            .mask(
                ZStack {
                    Circle().glassEffect(.clear) // 修正截圖中這裡的報錯
                    Circle().fill(Color.black).frame(width: radius * 0.62, height: radius * 0.62).blendMode(.destinationOut)
                }.compositingGroup()
            )
            
            // --- App 圖示 ---
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                ForEach(Array(store.apps.enumerated()), id: \.element.id) { index, item in
                    let threshold = Double(index) / Double(store.apps.count)
                    AppIconView(item: item, index: index, totalCount: store.apps.count, radius: radius, center: center, hoverIndex: $hoverIndex)
                        .opacity(drawingProgress > threshold ? 1 : 0)
                        .scaleEffect(drawingProgress > threshold ? 1 : 0.5)
                }
            }
        }
        .scaleEffect(drawingProgress) // 隨生長進度縮放
        .opacity(drawingProgress)
        .onAppear {
            store.fetchApps()
            // 使用 spring 動態讓彈出更有活力
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                drawingProgress = 1.0
            }
        }
        .frame(width: radius * 2, height: radius * 2)
        .onAppear {
            store.fetchApps()
            withAnimation(.easeInOut(duration: 0.5)) { drawingProgress = 1.0 }
        }
        // 修正 macOS 14 警告
        .onChange(of: hoverIndex) { oldValue, newValue in
            updateHighlight(to: newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("KeyReleased"))) { _ in
            if let hoverId = hoverIndex, let selectedApp = store.apps.first(where: { $0.id == hoverId }) {
                store.switchApp(to: selectedApp)
            }
        }
    }
    
    private func updateHighlight(to newValue: UUID?) {
        guard !store.apps.isEmpty else { return }
        if let hoverId = newValue, let index = store.apps.firstIndex(where: { $0.id == hoverId }) {
            let total = Double(store.apps.count)
            let anglePerApp = 360.0 / total
            let newStart = Double(index) * anglePerApp - (anglePerApp / 2) - 90
            let newEnd = Double(index) * anglePerApp + (anglePerApp / 2) - 90
            
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            
            withAnimation(.interpolatingSpring(stiffness: 150, damping: 15)) {
                targetStartAngle = newStart; targetEndAngle = newEnd; highlightOpacity = 1.0
            }
        } else {
            withAnimation(.easeOut(duration: 0.2)) { highlightOpacity = 0 }
        }
    }
}

// --- App Icon 元件 ---
struct AppIconView: View {
    let item: AppItem
    let index: Int
    let totalCount: Int
    let radius: CGFloat
    let center: CGPoint
    @Binding var hoverIndex: UUID?
    
    var body: some View {
        let angle = 2 * .pi / Double(totalCount) * Double(index) - .pi / 2
        let xOffset = cos(angle) * (radius / 2.22)
        let yOffset = sin(angle) * (radius / 2.22)
        
        VStack {
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                .scaleEffect(hoverIndex == item.id ? 1.35 : 1.0)
                .animation(.interactiveSpring(), value: hoverIndex)
                .onHover { isHovering in
                    if isHovering { hoverIndex = item.id }
                    else if hoverIndex == item.id { hoverIndex = nil }
                }
        }
        .position(x: center.x + xOffset, y: center.y + yOffset)
    }
}
