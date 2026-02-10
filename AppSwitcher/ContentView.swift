import SwiftUI
internal import AppKit


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
    @Binding var isShowing: Bool
    
    @AppStorage("ringRadius", store: SharedConfig.defaults) var radius: Double = 280
    @AppStorage("ringOuterMultiplier", store: SharedConfig.defaults) var ringOuterMultiplier: Double = 1.15
    @AppStorage("ringInnerRatio", store: SharedConfig.defaults) var ringInnerRatio: Double = 0.62
    @AppStorage("hepaticFeedback", store: SharedConfig.defaults) var hepaticFeedback: Bool = true
    
    @State private var drawingProgress: Double = 0
    @State private var targetStartAngle: Double = 0
    @State private var targetEndAngle: Double = 0
    @State private var highlightOpacity: Double = 0
    @State private var hoverIndex: UUID? = nil

    var body: some View {
        ZStack {
            // 背景層：玻璃環與藍色選取區
            backgroundLayer

            // 圖示層：拆分以減少編譯器壓力
            iconLayer

            // 中央文字層
            centerTextLayer
        }
//        .environment(\.controlActiveState, .key)
        .frame(width: radius * 2, height: radius * 2)
        .scaleEffect(0.85 + (drawingProgress * 0.15))
        .opacity(drawingProgress)
        .onAppear {
            store.fetchApps()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                drawingProgress = 1.0
            }
        }
        // 修正 macOS 14 警告
        .onChange(of: hoverIndex) { oldValue, newValue in
            updateHighlight(to: newValue)
        }
        // 監聽按鍵放開執行切換
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ExecuteSwitch"))) { _ in
            if let hoverId = hoverIndex, let selectedApp = store.apps.first(where: { $0.id == hoverId }) {
                store.switchApp(to: selectedApp)
            }
        }
    }
        
    
    // --- 子視圖拆分 ---
    
    private var backgroundLayer: some View {
        ZStack {
            Circle()
                .glassEffect(.clear)
            
            RingSector(startAngle: targetStartAngle, endAngle: targetEndAngle, innerRadiusRatio: 0.01)
                .fill(LinearGradient(colors: [.blue.opacity(0.8), .blue.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                .opacity(highlightOpacity * drawingProgress)
                .zIndex(1)
            
            Circle()
                .trim(from: 0, to: drawingProgress)
                .stroke(LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: CGFloat(radius) * ringOuterMultiplier, height: CGFloat(radius) * ringOuterMultiplier)
        .mask(
            ZStack {
                Circle().glassEffect(.clear)
                Circle().fill(Color.white).frame(width: CGFloat(radius) * ringInnerRatio, height: CGFloat(radius) * ringInnerRatio).blendMode(.destinationOut)
            }.compositingGroup()
        )
    }
    
    private var iconLayer: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ForEach(Array(store.apps.enumerated()), id: \.element.id) { index, item in
                let threshold = Double(index) / Double(store.apps.count)
                AppIconView(
                    store: store, // 傳入 store 解決 "Cannot find 'store' in scope"
                    item: item,
                    index: index,
                    totalCount: store.apps.count,
                    radius: radius,
                    center: center,
                    isShowing: $isShowing,
                    hoverIndex: $hoverIndex
                )
                .opacity(drawingProgress > threshold ? 1 : 0)
            }
        }
    }
    
    private var centerTextLayer: some View {
        Group {
            if let hoverId = hoverIndex, let app = store.apps.first(where: { $0.id == hoverId }) {
                Text(app.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding()
                    .foregroundColor(.white) // 先給一個基礎色
                    .blendMode(.difference)   // ✨ 魔法：它會根據背後的顏色自動計算反色
                    .font(.title)
                    .glassEffect(.clear)
                    
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
            if (hepaticFeedback) {
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            }
            withAnimation(.interpolatingSpring(stiffness: 150, damping: 15)) {
                targetStartAngle = newStart; targetEndAngle = newEnd; highlightOpacity = 1.0
            }
        } else {
            withAnimation(.easeOut(duration: 0.2)) { highlightOpacity = 0 }
        }
    }
}

// --- 3. App Icon 元件 ---
struct AppIconView: View {
    @ObservedObject var store: AppStore // 接收傳入的 store
    @AppStorage("iconSize", store: SharedConfig.defaults) var iconSize: Double = 60
    @AppStorage("ringOuterMultiplier", store: SharedConfig.defaults) var ringOuterMultiplier: Double = 1.15
    @AppStorage("ringInnerRatio", store: SharedConfig.defaults) var ringInnerRatio: Double = 0.62
    let item: AppItem
    let index: Int
    let totalCount: Int
    let radius: Double
    let center: CGPoint
    @Binding var isShowing: Bool
    @Binding var hoverIndex: UUID?
    
    var body: some View {
        let angle = 2 * .pi / Double(totalCount) * Double(index) - .pi / 2
        // --- 改為根據背景圈的內徑與外徑計算圖示半徑位置 ---
        // 與 backgroundLayer 使用的常數對齊：
        // outer circle frame width = radius * ringOuterMultiplier  -> outer radius = (radius * ringOuterMultiplier) / 2
        // inner hole frame width  = radius * ringInnerRatio       -> inner radius = (radius * ringInnerRatio) / 2
        let innerRadius = CGFloat(radius) * ringInnerRatio / 2.0
        let outerRadius = CGFloat(radius) * ringOuterMultiplier / 2.0
        // 放在內外徑之間（這裡用中點，也可以用 0...1 的參數調整偏移）
        let radialDistance = innerRadius + (outerRadius - innerRadius) * 0.5

        let xOffset = cos(angle) * Double(radialDistance)
        let yOffset = sin(angle) * Double(radialDistance)
        
        VStack {
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                .scaleEffect(hoverIndex == item.id ? 1.35 : 1.0)
                .animation(.interactiveSpring(), value: hoverIndex)
                .onHover { isHovering in
                    if isHovering { hoverIndex = item.id }
                    else if hoverIndex == item.id { hoverIndex = nil }
                }
                .onTapGesture {
                    store.switchApp(to: item)
                    isShowing = false
                }
        }
        // 使用 position 與由 inner/outer 計算出的 radialDistance
        .position(x: center.x + CGFloat(xOffset), y: center.y + CGFloat(yOffset))
        // 確保當 radius / radialDistance 變動時有平滑動畫
        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.8), value: radialDistance)
    }
}

// 修正 Preview 報錯：傳入必要的 Binding
#Preview {
    ContentView(isShowing: .constant(true))
}
