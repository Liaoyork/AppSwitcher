import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppStore()
    @State private var hoverIndex: UUID? = nil
    @State private var isVisible = false // 用於進場動畫
    
    let radius: CGFloat = 280
    
    var body: some View {
        ZStack {
            // --- 1. 原生 Glass Effect 液態中空環 ---
            ZStack {
                // 使用系統級玻璃特效
                Circle()
                    .fill(.clear)
                    .glassEffect()
                
                // 增加液態邊緣高光
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
            // 關鍵：使用 mask 達成中空
            .mask(
                ZStack {
                    Circle()
                    Circle()
                        .fill(Color.black)
                        .frame(width: radius * 0.62, height: radius * 0.62)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
            )
//            .scaleEffect(isVisible ? 1 : 0.8)
//            .opacity(isVisible ? 1 : 0)

            // --- 2. 中央文字顯示 ---
            if let hoverId = hoverIndex, let app = store.apps.first(where: { $0.id == hoverId }) {
                Text(app.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
            }
            
            // --- 3. App 圖示佈局 ---
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
                            // 液態退出動畫
                            withAnimation(.easeIn(duration: 0.15)) {
                                isVisible = false
                            }
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
        .onAppear {
            store.fetchApps()
            // 進場動畫：玻璃環彈出
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

// 子元件：負責單個 App 圖示的渲染與動畫
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
        // 計算每個圖示的角度與偏移
        let angle = 2 * .pi / Double(totalCount) * Double(index) - .pi / 2
        // 2.22 這個參數確保圖示正好在環的寬度中間
        let xOffset = cos(angle) * (radius / 2.22)
        let yOffset = sin(angle) * (radius / 2.22)
        
        VStack {
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 65, height: 65)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                // 懸停放大效果
                .scaleEffect(hoverIndex == item.id ? 1.35 : 1.0)
                // 進場延遲動畫，產生一個接一個彈出的感覺
                .scaleEffect(isVisible ? 1 : 0.5)
                .opacity(isVisible ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.03), value: isVisible)
                .animation(.interactiveSpring(), value: hoverIndex)
                .onHover { isHovering in
                    hoverIndex = isHovering ? item.id : nil
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
