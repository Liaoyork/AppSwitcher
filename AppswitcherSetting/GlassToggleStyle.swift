import SwiftUI

struct GlassToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            // 開關的文字標籤 (例如 "登入時啟動")
            configuration.label
            
            Spacer()
            
            // --- 核心：液態玻璃開關本體 ---
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    configuration.isOn.toggle()
                }
            }) {
                ZStack {
                    // 1. 軌道 (Track)
                    Capsule()
                        .fill(configuration.isOn ? Color.blue.opacity(0.6) : Color.black.opacity(0.1))
                        .background(
                            Capsule()
                                .glassEffect(.clear) // 套用你的玻璃特效
                        )
                        // 內陰影效果 (模擬凹槽)
                        .overlay(
                            Capsule()
                                .stroke(LinearGradient(colors: [.black.opacity(0.2), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                        )
                        .frame(width: 44, height: 24)
                    
                    // 2. 旋鈕 (Knob) - 像一顆水珠
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1) // 陰影增加立體感
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                        )
                        .padding(2)
                        .offset(x: configuration.isOn ? 10 : -10) // 左右移動動畫
                }
            }
            .buttonStyle(.plain) // 移除按鈕預設點擊背景
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                configuration.isOn.toggle()
            }
        }
    }
}
