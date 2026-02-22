import SwiftUI
internal import AppKit


// ring sector w/ animation
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

// main UI design

struct ContentView: View {

    @StateObject private var store = AppStore()
    @Binding var isShowing: Bool
    
    @AppStorage("ringRadius", store: SharedConfig.defaults) var radius: Double = 280
    @AppStorage("ringOuterMultiplier", store: SharedConfig.defaults) var ringOuterMultiplier: Double = 1.15
    @AppStorage("ringInnerRatio", store: SharedConfig.defaults) var ringInnerRatio: Double = 0.6
    @AppStorage("hepaticFeedback", store: SharedConfig.defaults) var hepaticFeedback: Bool = true
    
    @AppStorage("appLanguage", store: SharedConfig.defaults) var appLanguage: AppLanguage = .system
    
    @State private var drawingProgress: Double = 0
    @State private var appearanceScale: CGFloat = 0.0
    @State private var targetStartAngle: Double = 0
    @State private var targetEndAngle: Double = 0
    @State private var highlightOpacity: Double = 0
    @State private var hoverIndex: UUID? = nil

    var body: some View {
        ZStack {
            backgroundLayer
            iconLayer
            centerTextLayer
        }
        .frame(width: radius * 2, height: radius * 2)
        .scaleEffect(appearanceScale)
        .opacity(drawingProgress)
        .onAppear {
            store.fetchApps()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                drawingProgress = 1.0
                appearanceScale = 1.0
            }
        }
        .onChange(of: hoverIndex) { oldValue, newValue in
            updateHighlight(to: newValue)
        }
        // respond to external trigger (hotkey execution)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ExecuteSwitch"))) { _ in
            if let hoverId = hoverIndex, let selectedApp = store.apps.first(where: { $0.id == hoverId }) {
                store.switchApp(to: selectedApp)
            }
        }
    }
        
    
    // create the background layer with glass effect and highlight sector
    
    private var backgroundLayer: some View {
        ZStack {
            Circle()
                .glassEffect(.clear)
            
            RingSector(startAngle: targetStartAngle, endAngle: targetEndAngle, innerRadiusRatio: 0.01)
                .fill(LinearGradient(colors: [.blue.opacity(0.8), .blue.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                .opacity(highlightOpacity * drawingProgress)
                .zIndex(1)
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
                    store: store,
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
                    .foregroundColor(.white)
                    .blendMode(.difference)
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

// App Icon element
struct AppIconView: View {
    @ObservedObject var store: AppStore
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

        let innerRadius = CGFloat(radius) * ringInnerRatio / 2.0
        let outerRadius = CGFloat(radius) * ringOuterMultiplier / 2.0
        
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
        .position(x: center.x + CGFloat(xOffset), y: center.y + CGFloat(yOffset))
        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.8), value: radialDistance)
    }
}

#Preview {
    ContentView(isShowing: .constant(true))
}
