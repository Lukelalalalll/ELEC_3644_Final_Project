import SwiftUI

struct WelcomeView: View {
    @State private var showLogin = false
    @State private var showRegister = false
    @State private var showMainApp = false
    @State private var isShowingContent = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .offset(y: isShowingContent ? 0 : UIScreen.main.bounds.height)
            .opacity(isShowingContent ? 1.0 : 0.0)
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .scaleEffect(isShowingContent ? 1.0 : 0.8)
                        .opacity(isShowingContent ? 1.0 : 0.0)
                    
                    Text("Welcome to Campus Compass App")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(isShowingContent ? 1.0 : 0.0)
                    
                    Text("Your university journey starts here")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(isShowingContent ? 1.0 : 0.0)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.spring()) {
                            showLogin = true
                        }
                    }) {
                        Text("Login")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .opacity(isShowingContent ? 1.0 : 0.0)
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            showRegister = true
                        }
                    }) {
                        Text("Register")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .opacity(isShowingContent ? 1.0 : 0.0)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .offset(y: isShowingContent ? 0 : UIScreen.main.bounds.height * 0.3)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
                isShowingContent = true
            }
        }
        .onDisappear {
            withAnimation(.easeOut(duration: 0.5)) {
                isShowingContent = false
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView(showMainApp: $showMainApp)
        }
        .fullScreenCover(isPresented: $showRegister) {
            RegisterView(showMainApp: $showMainApp)
        }
        .fullScreenCover(isPresented: $showMainApp) {
            MainTabContainerView()
        }
    }
}

#Preview {
    WelcomeView()
}
