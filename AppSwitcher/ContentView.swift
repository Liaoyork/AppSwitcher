import SwiftUI
internal import AppKit


// ring sector w/ animation
struct RingSector: Shape {
    var startAngle: Double
    var endAngle: Double
    var innerRadiusRatio: CGFloat
    var outerRadiusRatio: CGFloat = 1.0
    
    var margin: CGFloat = 13.0

    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, CGFloat> {
        get {
            AnimatablePair(AnimatablePair(startAngle, endAngle), outerRadiusRatio)
        }
        set {
            startAngle = newValue.first.first
            endAngle = newValue.first.second
            outerRadiusRatio = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        
        let baseInnerRadius = maxRadius * innerRadiusRatio
        let baseOuterRadius = baseInnerRadius + (maxRadius - baseInnerRadius) * outerRadiusRatio

        let innerRadius = baseInnerRadius + margin
        let outerRadius = baseOuterRadius - margin

        var path = Path()
        guard outerRadius > innerRadius else { return path }
        
        let midRadius = (innerRadius + outerRadius) / 2
        let angleMargin = Double((margin / midRadius) * (180.0 / .pi))
        
        let actualStartAngle = startAngle + angleMargin
        let actualEndAngle = endAngle - angleMargin
        
        if actualStartAngle < actualEndAngle {
            path.addArc(center: center, radius: outerRadius, startAngle: .degrees(actualStartAngle), endAngle: .degrees(actualEndAngle), clockwise: false)
            
            path.addLine(to: CGPoint(
                x: center.x + innerRadius * cos(CGFloat(Angle.degrees(actualEndAngle).radians)),
                y: center.y + innerRadius * sin(CGFloat(Angle.degrees(actualEndAngle).radians))
            ))
            
            path.addArc(center: center, radius: innerRadius, startAngle: .degrees(actualEndAngle), endAngle: .degrees(actualStartAngle), clockwise: true)
            path.closeSubpath()
        }
        return path
    }
}

// main UI design

struct ContentView: View {

    @StateObject private var store = AppStore()
    @Binding var isShowing: Bool
    var isPreview: Bool = false
    var onIconClick: ((Int) -> Void)? = nil
    
    @AppStorage("ringRadius", store: SharedConfig.defaults) var radius: Double = 300
    @AppStorage("ringOuterMultiplier", store: SharedConfig.defaults) var ringOuterMultiplier: Double = 1.15
    @AppStorage("ringInnerRatio", store: SharedConfig.defaults) var ringInnerRatio: Double = 0.6
    @AppStorage("hepaticFeedback", store: SharedConfig.defaults) var hepaticFeedback: Bool = true
    @State private var highlightGrowth: CGFloat = 1.0
    @State private var hideWorkItem: DispatchWorkItem? = nil
    @AppStorage("appLanguage", store: SharedConfig.defaults) var appLanguage: AppLanguage = .system
    @AppStorage("isUserSet", store: SharedConfig.defaults) var isUserSet: Bool = false
    
    @State private var drawingProgress: Double = 0
    @State private var appearanceScale: CGFloat = 0.0
    @State private var targetStartAngle: Double = 0
    @State private var targetEndAngle: Double = 0
    @State private var highlightOpacity: Double = 0
    @State private var hoverIndex: UUID? = nil
    @State private var lastMouseLocation: CGPoint? = nil	

    var body: some View {
        ZStack {
            backgroundLayer
            iconLayer
            centerTextLayer
            interactionLayer
        }
        .frame(width: radius * 1.2, height: radius * 1.2)
        .scaleEffect(appearanceScale)
        .opacity(drawingProgress)
        .onAppear {
            store.fetchApps()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                drawingProgress = 1.0
                appearanceScale = 1.0
            }
        }
        .onChange(of: hoverIndex) { oldValue, newValue in
            updateHighlight(to: newValue)
        }
        .onChange(of: isUserSet) { _, _ in
            store.fetchApps()
            drawingProgress = 0
            appearanceScale = 0
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                drawingProgress = 1.0
                appearanceScale = 1.0
            }
        }
        // respond to external trigger (hotkey execution)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ExecuteSwitch"))) { _ in
            if let hoverId = hoverIndex, let selectedApp = store.apps.first(where: { $0.id == hoverId }) {
                store.switchApp(to: selectedApp)
            }
            hoverIndex = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MoveToNextApp"))) { _ in
            hoverIndex = store.getNextAppId(after: hoverIndex)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MoveToPreviousApp"))) { _ in
            hoverIndex = store.getPreviousAppId(before: hoverIndex)
        }
    }
        
    
    // create the background layer with glass effect and highlight sector
    private var backgroundLayer: some View {
        ZStack {
            Circle()
                .glassEffect(.clear)
                .padding(-5)
                .environment(\.colorScheme, .light)
                .mask(
                    Circle()
                        .strokeBorder(
                            Color.white,
                            lineWidth: CGFloat(radius) * (ringOuterMultiplier - ringInnerRatio) / 2
                        )
                )
            Rectangle()
                .fill(LinearGradient(colors: [.blue.opacity(0.8), .blue.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                .mask(
                    ZStack {
                        let sector = RingSector(
                            startAngle: targetStartAngle,
                            endAngle: targetEndAngle,
                            innerRadiusRatio: CGFloat(ringInnerRatio / ringOuterMultiplier),
                            outerRadiusRatio: highlightGrowth
                        )
                        
                        // 填滿實心扇形
                        sector.fill(Color.black)
                        
                        sector.stroke(Color.black, style: StrokeStyle(lineWidth: 10, lineJoin: .round))
                    }
                    .compositingGroup() // 合併成一個完整的遮罩
                )
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
            }
        }
        .id("\(store.apps.count)-\(isUserSet)")
    }
    
    private var centerTextLayer: some View {
        Group {
            if let hoverId = hoverIndex, let app = store.apps.first(where: { $0.id == hoverId }) {
                Text(app.name)      
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding()
//                    .foregroundColor(.white)
//                    .blendMode(.difference)
                    .font(.title)
                    .glassEffect(.regular)
            }
        }
    }
    
    private var interactionLayer: some View {
        GeometryReader { geo in
            Circle()
                .fill(Color.white.opacity(0.001))
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        if let app = getHoveredApp(at: location, in: geo.size) {
                            if hoverIndex != app.id { hoverIndex = app.id }
                        } else {
                            hoverIndex = nil
                        }
                    case .ended:
                        hoverIndex = nil
                    }
                }
                .onTapGesture(coordinateSpace: .local) { location in
                    if let app = getHoveredApp(at: location, in: geo.size) {
                        if isPreview {
                            if let index = store.apps.firstIndex(where: { $0.id == app.id }) {
                                onIconClick?(index)
                            }
                        } else {
                            store.switchApp(to: app)
                            isShowing = false
                        }
                    }
                }
        }
        .frame(width: CGFloat(radius) * ringOuterMultiplier, height: CGFloat(radius) * ringOuterMultiplier)
    }
    
    private func getHoveredApp(at location: CGPoint, in size: CGSize) -> AppItem? {
        let total = store.apps.count
        guard total > 0 else { return nil }
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        
        let maxRadius = min(size.width, size.height) / 2
        let innerRadius = maxRadius * CGFloat(ringInnerRatio / ringOuterMultiplier)
        let outerRadius = maxRadius
        
        guard distance >= innerRadius && distance <= outerRadius else {
            return nil	
        }
        
        var angleFromTop = atan2(dx, -dy) * 180 / .pi
        if angleFromTop < 0 { angleFromTop += 360 }
        
        let anglePerApp = 360.0 / Double(total)
        let shiftedAngle = (angleFromTop + anglePerApp / 2).truncatingRemainder(dividingBy: 360)
        let index = Int(shiftedAngle / anglePerApp) % total
        
        return store.apps[index]
    }
    
    private func updateHighlight(to newValue: UUID?) {
        guard !store.apps.isEmpty else { return }
        
        if let hoverId = newValue, let index = store.apps.firstIndex(where: { $0.id == hoverId }) {
            let total = Double(store.apps.count)
            let anglePerApp = 360.0 / total
            let newStart = Double(index) * anglePerApp - (anglePerApp / 2) - 90
            
            let normalizedStart = normalizeDestAngle(current: targetStartAngle, target: newStart)
            let normalizedEnd = normalizedStart + anglePerApp
            
            if (hepaticFeedback) {
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            }
            
            if highlightOpacity == 0 {
                // fisrt time appear
                targetStartAngle = normalizedStart
                targetEndAngle = normalizedEnd
                highlightGrowth = 0.0
                
                withAnimation(.interpolatingSpring(stiffness: 150, damping: 15)) {
                    highlightGrowth = 1.0
                    highlightOpacity = 1.0
                }
            } else {
                // rotation
                withAnimation(.interpolatingSpring(stiffness: 150, damping: 15)) {
                    targetStartAngle = normalizedStart
                    targetEndAngle = normalizedEnd
                    highlightGrowth = 1.0
                    highlightOpacity = 1.0
                }
            }
            
        } else {
            let workItem = DispatchWorkItem {
                withAnimation(.easeOut(duration: 0.2)) {
                    highlightGrowth = 0.0
                    highlightOpacity = 0
                }
            }
            hideWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: workItem)
        }
    }
    private func normalizeDestAngle(current: Double, target: Double) -> Double {
        let diff = (target - current).truncatingRemainder(dividingBy: 360)
        let shortestDiff = (diff + 540).truncatingRemainder(dividingBy: 360) - 180
        return current + shortestDiff
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
    
    
    @State private var isVisible = false
    
    @State private var currentAngle: Double = -Double.pi / 2
    
    var body: some View {
        let innerRadius = CGFloat(radius) * ringInnerRatio / 2.0
        let outerRadius = CGFloat(radius) * ringOuterMultiplier / 2.0
        let radialDistance = innerRadius + (outerRadius - innerRadius) * 0.55
        

        
        VStack {
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                .scaleEffect(isVisible ? (hoverIndex == item.id ? 1.35 : 1.0) : 0.001)
                .opacity(isVisible ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hoverIndex)
        }
        .modifier(CircularPositionModifier(angle: currentAngle, radius: radialDistance, center: center))
        .onAppear {

            let targetAngle = 2 * .pi / Double(totalCount) * Double(index) - .pi / 2
            
            DispatchQueue.main.async {

                withAnimation(.easeOut(duration: 0.2).delay(Double(index) * 0.03)) {
                    isVisible = true
                }
                

                withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.03)) {
                    currentAngle = targetAngle
                }
            }
        }
        .onDisappear {
            isVisible = false
            currentAngle = -Double.pi / 2
        }
    }
}
struct CircularPositionModifier: ViewModifier, Animatable {
    var angle: Double
    var radius: Double
    var center: CGPoint
    
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }
    
    func body(content: Content) -> some View {
        let xOffset = cos(angle) * radius
        let yOffset = sin(angle) * radius
        
        content
            .position(x: center.x + CGFloat(xOffset), y: center.y + CGFloat(yOffset))
    }
}


#Preview {
    ContentView(isShowing: .constant(true))
}

