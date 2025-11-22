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
    @State private var hasRefreshedOnAppear = false
    
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
                .padding(.horizontal, 0)
                .padding(.vertical, 26)
                .background(
                    VisualEffectBlur(blurStyle: .systemThinMaterial)
                        .overlay(
                            Rectangle()
                                .fill(Color.primary.opacity(0.05))
                                .mask(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal, 16)
                // 移除负的底部间距，使用安全区域
                .padding(.bottom, 0)
            }
            // 忽略安全区域，让 TabBar 延伸到屏幕底部
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .onAppear {
            // 应用启动时强制刷新数据
            if !hasRefreshedOnAppear {
                Task {
                    await refreshAllData()
                    hasRefreshedOnAppear = true
                }
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // 切换到 Posts 标签时刷新数据
            if newValue == 1 {
                Task {
                    await refreshPostsData()
                }
            }
        }
    }
    
    @ViewBuilder
    private var currentPage: some View {
        switch selectedTab {
        case 0: HomeView()
        case 1: PostsFeedView()
        case 2: CoursesView()
        case 3: ProfileView()
        default: HomeView()
        }
    }
    
    // 刷新所有数据
    private func refreshAllData() async {
        print("应用启动，开始刷新所有数据...")
        await refreshPostsData()
        // 可以在这里添加刷新课程数据等其他刷新逻辑
    }
    
    // 刷新帖子数据
    private func refreshPostsData() async {
        print("刷新帖子数据...")
        // 设置强制刷新标志，PostsFeedView 会在 onAppear 时检测这个标志
        UserDefaults.standard.set(true, forKey: "forceRefreshPosts")
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
                    // 液态玻璃选中效果
                    if selectedTab == index {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .matchedGeometryEffect(id: "TAB", in: animation)
                            .frame(width: 70, height: 70)
                            .offset(y: 4)
                    }
                    
                    // 图标
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(selectedTab == index ? .accentColor : .primary.opacity(0.7))
                        .scaleEffect(selectedTab == index ? 1.6 : 1.0)
                        .offset(y: -5)
                }
                .frame(height: 24)
                
                // 标题 - 确保完整显示
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selectedTab == index ? .accentColor : .primary.opacity(0.7))
                    .fixedSize(horizontal: true, vertical: false)
                    .scaleEffect(selectedTab == index ? 1.0 : 0.95)
                    .offset(y: 0)
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
