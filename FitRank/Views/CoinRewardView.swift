//
//  CoinRewardView.swift
//  FitRank
//
//  Simple notification shown when user earns coins
//

import SwiftUI

struct CoinRewardView: View {
    let amount: Int
    @Binding var isShowing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("+\(amount) Coins!")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.12, blue: 0.2))
                .shadow(color: .yellow.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [.yellow.opacity(0.5), .orange.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
        )
    }
}

// View modifier to show coin rewards
struct CoinRewardModifier: ViewModifier {
    @Binding var isShowing: Bool
    let amount: Int
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                VStack {
                    CoinRewardView(amount: amount, isShowing: $isShowing)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 50)
                    
                    Spacer()
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isShowing)
    }
}

extension View {
    func coinReward(isShowing: Binding<Bool>, amount: Int) -> some View {
        self.modifier(CoinRewardModifier(isShowing: isShowing, amount: amount))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        CoinRewardView(amount: 100, isShowing: .constant(true))
    }
}
