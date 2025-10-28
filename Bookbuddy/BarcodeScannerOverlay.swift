//
//  BarcodeScannerOverlay.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 27/10/2025.
//

import SwiftUI

struct BarcodeScannerOverlay: View {
    @State private var animationOffset: CGFloat = 0
    var isScanning: Bool = true

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)

            // Scanning frame
            VStack(spacing: 16) {
                Spacer()

                // Scanning reticle
                ZStack {
                    // Corner brackets
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 280, height: 180)

                    // Corner accents
                    VStack {
                        HStack {
                            CornerBracket()
                            Spacer()
                            CornerBracket()
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        }
                        Spacer()
                        HStack {
                            CornerBracket()
                                .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                            Spacer()
                            CornerBracket()
                                .rotation3DEffect(.degrees(180), axis: (x: 1, y: 1, z: 0))
                        }
                    }
                    .frame(width: 280, height: 180)

                    // Animated scanning line
                    if isScanning {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.green.opacity(0),
                                        Color.green,
                                        Color.green.opacity(0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 260, height: 2)
                            .offset(y: animationOffset)
                            .onAppear {
                                withAnimation(
                                    Animation.linear(duration: 2.0)
                                        .repeatForever(autoreverses: true)
                                ) {
                                    animationOffset = 80
                                }
                                animationOffset = -80
                            }
                    }
                }
                .accessibilityHidden(true)

                // Instruction text
                VStack(spacing: 8) {
                    Text(isScanning ? "Position ISBN barcode in frame" : "Barcode detected!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 4)
                        .accessibilityLabel(isScanning ? "Position ISBN barcode in frame. Found on back cover or inside flap" : "Barcode detected")

                    Text("Found on back cover or inside flap")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.8), radius: 4)
                        .accessibilityHidden(true)
                }
                .padding(.top, 8)

                Spacer()
            }
        }
        .allowsHitTesting(false) // Allow touches to pass through to camera controls
    }
}

// Corner bracket shape
struct CornerBracket: View {
    var body: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .fill(Color.green)
                .frame(width: 30, height: 4)
                .offset(x: -13, y: -13)

            // Vertical line
            Rectangle()
                .fill(Color.green)
                .frame(width: 4, height: 30)
                .offset(x: -13, y: -13)
        }
        .frame(width: 30, height: 30)
    }
}

#Preview("Scanner Overlay - Scanning") {
    ZStack {
        Color.black
        BarcodeScannerOverlay(isScanning: true)
    }
}

#Preview("Scanner Overlay - Detected") {
    ZStack {
        Color.black
        BarcodeScannerOverlay(isScanning: false)
    }
}
