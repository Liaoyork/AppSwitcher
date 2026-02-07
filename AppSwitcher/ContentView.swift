import SwiftUI
import AppKit

// --- 1. 支援動畫的扇形形狀 ---
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
    @State private var hoverIndex: UUID? = nil
    @State private var isVisible = false
    
    // 藍色高亮動畫狀態：這裡會保留上一次的值
    @State private var targetStartAngle: Double = 0
    @State private var targetEndAngle: Double = 0
    @State private var highlightOpacity: Double = 0
    
    let radius: CGFloat = 280
    
    var body: some View {
        ZStack {
            // --- 背景層：Liquid Glass Ring ---
            ZStack {
                Circle()
                    .glassEffect(.clear)
                
                // 藍色液態扇區 (會保留上一次位置進行平滑移動)
                RingSector(
                    startAngle: targetStartAngle,
                    endAngle: targetEndAngle,
                    innerRadiusRatio: 0.54
                )
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(highlightOpacity)
                .shadow(color: Color.blue.opacity(0.4), radius: 15)
                .zIndex(1)
                
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .clear, .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .frame(width: radius * 1.15, height: radius * 1.15)
            .mask(
                ZStack {
                    Circle().glassEffect(.clear)
                    Circle()
                        .fill(Color.black)
                        .frame(width: radius * 0.62, height: radius * 0.62)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
            )
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)

            // --- 中央文字顯示 ---
            if let hoverId = hoverIndex, let app = store.apps.first(where: { $0.id == hoverId }) {
                Text(app.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .transition(.opacity)
            }
            
            // --- App 圖示層 ---
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                
                ForEach(Array(store.apps.enumerated()), id: \.element.id) { index, item in
                    AppIconView(
                        item: item,
                        index: index,
                        totalCount: store.apps.count,
                        radius: radius,
                        center: center,
                        hoverIndex: $hoverIndex,
                        isVisible: isVisible,
                        onTap: {
                            store.switchApp(to: item)
                            withAnimation(.easeIn(duration: 0.15)) { isVisible = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                NSApp.terminate(nil)
                            }
                        }
                    )
                }
            }
        }
        .frame(width: radius * 2, height: radius * 2)
        .background(Color.clear)
        .onChange(of: hoverIndex) { oldValue, newValue in
            updateHighlight(to: newValue)
        }
        .onAppear {
            store.fetchApps()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
    
    // 處理藍色高亮滑動邏輯：它會從上一次的角度直接滑向新角度
    private func updateHighlight(to newValue: UUID?) {
        if let hoverId = newValue,
           let index = store.apps.firstIndex(where: { $0.id == hoverId }) {
            
            let total = Double(store.apps.count)
            let anglePerApp = 360.0 / total
            let newStart = Double(index) * anglePerApp - (anglePerApp / 2) - 90
            let newEnd = Double(index) * anglePerApp + (anglePerApp / 2) - 90
            
            // 觸覺回饋：當移動到新的 App 時發出微弱震動
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            
            withAnimation(.interpolatingSpring(stiffness: 150, damping: 15)) {
                targetStartAngle = newStart
                targetEndAngle = newEnd
                highlightOpacity = 1.0
            }
        } else {
            // 滑鼠離開環狀區時，淡出但保留角度，這樣下次進來才會「從上次的地方出發」
            withAnimation(.easeOut(duration: 0.2)) {
                highlightOpacity = 0
            }
        }
    }
}

// --- 3. App 圖示子元件 ---
struct AppIconView: View {
    let item: AppItem
    let index: Int
    let totalCount: Int
    let radius: CGFloat
    let center: CGPoint
    @Binding var hoverIndex: UUID?
    let isVisible: Bool
    let onTap: () -> Void
    
    var body: some View {
        let angle = 2 * .pi / Double(totalCount) * Double(index) - .pi / 2
        let xOffset = cos(angle) * (radius / 2.22)
        let yOffset = sin(angle) * (radius / 2.22)
        
        VStack {
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 65, height: 65)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                .scaleEffect(hoverIndex == item.id ? 1.35 : 1.0)
                .scaleEffect(isVisible ? 1 : 0.5)
                .opacity(isVisible ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.03), value: isVisible)
                .animation(.interactiveSpring(), value: hoverIndex)
                .onHover { isHovering in
                    if isHovering {
                        hoverIndex = item.id
                    } else if hoverIndex == item.id {
                        hoverIndex = nil
                    }
                }
                .onTapGesture {
                    onTap()
                }
        }
        .position(x: center.x + xOffset, y: center.y + yOffset)
    }
}
#Preview{
    ContentView()
}
