//
//  HomeView.swift
//  ClearPath
//
//  Created by Sathyashri.Muruganandam on 2024-11-02.
//

import SwiftUI
import AVFoundation
import AVKit

struct HomeView: View {
    let player = AVPlayer(url:  Bundle.main.url(forResource: "drives", withExtension: "mov")!)
    
    init() {
        let appearance = UITabBarAppearance()
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationStack {
            TabView {
                CameraView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                            .environment(\.symbolVariants, .none)
                    }
                
                ScrollView {
                    VideoPlayer(player: player)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .onAppear {
                            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { _ in
                                player.seek(to: .zero)
                                player.play()
                            }
                            player.play()
                        }
                        .ignoresSafeArea()
                        .disabled(true)
                }
                .tabItem {
                    Label("Past Drives", systemImage: "map")
                        .environment(\.symbolVariants, .none)
                }
                
                Text("")
                    .tabItem {
                        Label("Profile", systemImage: "person")
                            .environment(\.symbolVariants, .none)
                    }
            }
            .navigationTitle("Clear Path")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "bell")
                    }
                }
            }
        }
    }
}
