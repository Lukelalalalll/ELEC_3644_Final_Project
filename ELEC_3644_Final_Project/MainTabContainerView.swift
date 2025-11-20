//
//  MainTabContainerView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/20.
//


import SwiftUI

struct MainTabContainerView: View {
    @State private var selectedTab: Int = 0
    @Namespace private var animation
    
    var body: some View {
        ZStack {
            // 页面内容
            currentPage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 高级毛玻璃底部 TabBar
            VStack {
                Spacer()
                
                HStack(spacing: 0) {
                    TabBarButton(icon: "house.fill", title: "Home", index: 0, selectedTab: $selectedTab, animation: animation)
                    TabBarButton(icon: "square.stack.fill", title: "Posts", index: 1, selectedTab: $selectedTab, animation: animation)
                    TabBarButton(icon: "book.fill", title: "Courses", index: 2, selectedTab: $selectedTab, animation: animation)
                    TabBarButton(icon: "person.circle.fill", title: "Profile", index: 3, selectedTab: $selectedTab, animation: animation)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .background(
                    VisualEffectBlur(blurStyle: .systemThinMaterial)
                        .overlay(
                            Rectangle()
                                .fill(Color.primary.opacity(0.1))
                                .mask(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }
    
    @ViewBuilder
    private var currentPage: some View {
        switch selectedTab {
        case 0: HomeView()
        case 1: PostsView()
        case 2: CoursesView()
        case 3: ProfileView()
        default: HomeView()
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let index: Int
    @Binding var selectedTab: Int
    var animation: Namespace.ID
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    // 选中时的背景动画 - 调整位置和大小
                    if selectedTab == index {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .matchedGeometryEffect(id: "TAB", in: animation)
                            .frame(width: 67, height: 67)
                            .offset(y: 10) // 向上微调位置
                    }
                    
                    // 图标
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedTab == index ? .accentColor : .primary.opacity(0.7))
                        .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                }
                .frame(height: 24)
                
                // 标题 - 确保完整显示
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selectedTab == index ? .accentColor : .primary.opacity(0.7))
                    .fixedSize(horizontal: true, vertical: false) // 防止文字截断
                    .scaleEffect(selectedTab == index ? 1.0 : 0.95)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    MainTabContainerView()
        .preferredColorScheme(.light)
}
