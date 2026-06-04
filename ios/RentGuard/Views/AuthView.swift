//
//  AuthView.swift
//  RentGuard
//
//  Premium sign-in screen — Google & Apple OAuth
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(AuthManager.self) private var auth

    @State private var logoPulse = false

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo section
                VStack(spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.18, green: 0.82, blue: 0.78),
                                        Color(red: 0.09, green: 0.62, blue: 0.74)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .scaleEffect(logoPulse ? 1.05 : 1.0)
                            .shadow(
                                color: Color(red: 0.18, green: 0.82, blue: 0.78).opacity(0.5),
                                radius: 20, x: 0, y: 8
                            )

                        Image(systemName: "building.2.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text("RentGuard")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("AI-powered property command center")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                // Sign-in buttons
                VStack(spacing: 14) {
                    if auth.isSigningIn {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                            .padding(.bottom, 8)
                    }

                    // Google Sign-In
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.prepare()
                        impact.impactOccurred()
                        Task { await auth.signIn(provider: "google") }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 22))
                            Text("Sign in with Google")
                                .font(.headline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .foregroundStyle(.black)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(auth.isSigningIn)
                    .buttonStyle(PressableButtonStyle())

                    // Apple Sign-In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { _ in
                        Task { await auth.signIn(provider: "apple") }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .disabled(auth.isSigningIn)
                    .overlay {
                        if auth.isSigningIn {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.black.opacity(0.3))
                        }
                    }

                    Text("Your data is stored securely on-device and synced per account.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                logoPulse = true
            }
        }
        .alert("Error", isPresented: Binding(get: { auth.showError }, set: { auth.showError = $0 })) {
            Button("OK") {}
        } message: {
            Text(auth.errorMessage)
        }
    }
}

#Preview {
    AuthView()
        .environment(AuthManager())
}
