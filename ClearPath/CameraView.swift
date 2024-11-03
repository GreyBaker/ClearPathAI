//
//  CameraView.swift
//  ClearPath
//
//  Created by Sathyashri.Muruganandam on 2024-11-02.
//

import SwiftUI
import AVFAudio

struct CameraView: View {
    private let model = DataModel()
    @State private var isRecording = false
    @State private var started = false
    @State private var photoTaken = false
    @State private var boxes: [CGRect] = []
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    private var player: AVAudioPlayer?
    private let detector = ObjectDetector()
    private let generator = UINotificationFeedbackGenerator()
    
    init() {
        guard let soundURL = Bundle.main.url(forResource: "beep", withExtension: "wav") else {
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            player = try AVAudioPlayer(contentsOf: soundURL)
        } catch {
            print("Failed to load the sound: \(error)")
        }
        
        generator.prepare()
    }
    
    var body: some View {
        @Bindable var model = model
        VStack(spacing: 12) {
            if !started && horizontalSizeClass == .compact && verticalSizeClass == .regular {
                Image("summary")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            ViewfinderView(image: $model.viewfinderImage)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(alignment: .center)  {
                    if photoTaken {
                        Color.white
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    photoTaken = false
                                }
                            }
                    }
                    
                    if !boxes.isEmpty {
                        ZStack {
                            Color.red.opacity(0.3)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            Image(systemName: "exclamationmark.triangle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150)
                                .foregroundStyle(Color.yellow)
                                .opacity(0.5)
                                .offset(y: -20)
                        }
                        .allowsHitTesting(false)
                    }
                }
                .overlay(alignment: .top) {
                    if started {
                        HStack {
                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundStyle(Color.red)
                                Text("Monitoring")
                                    .font(.headline)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Capsule().fill(Material.thin))
                            .padding()
                            Spacer()
                            Button {
                                withAnimation(.snappy) {
                                    started = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.title)
                                    .padding()
                            }
                        }
                    }
                }
                .overlay(content: {
                    ForEach(boxes, id: \.hashValue) { box in
                        GeometryReader { geometry in
                            Rectangle()
                                .path(in: CGRect(
                                    x: box.minX * geometry.size.width,
                                    y: box.minY * geometry.size.height,
                                    width: box.width * geometry.size.width * 0.9,
                                    height: box.height * geometry.size.height * 0.9))
                                .stroke(Color.red, lineWidth: 2.0)
                                .padding()
                        }
                    }
                })
                .overlay(alignment: .bottom) {
                    buttonsView
                }
        }
        .padding()
        .task {
            await model.camera.start()
        }
        .onReceive(detector.detectionPublisher, perform: { coordinates in
            withAnimation(.snappy) {
                boxes = coordinates
            }
            if !coordinates.isEmpty {
                playSound()
            }
        })
        .onReceive(timer, perform: { _ in
            if started {
                guard let image = model.cgImage else { return }
                detector.detect(in: image)
            }
        })
    }
    
    var buttonsView: some View {
        HStack {
            Spacer()
            if started {
                Button {
                    withAnimation {
                        photoTaken = true
                    }
                    model.camera.takePhoto()
                } label: {
                    Image(systemName: "camera.circle.fill")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundColor(.white)
                        .padding()
                }
                
                Button {
                    if isRecording {
                        model.camera.stopRecordingVideo()
                        isRecording = false
                    } else {
                        model.camera.startRecordingVideo()
                        isRecording = true
                    }
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(.white, lineWidth: 3)
                            .frame(width: 62, height: 62)
                        if isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.red)
                                .frame(width: 25, height: 25)
                        } else {
                            Circle()
                                .fill(.white)
                                .frame(width: 50, height: 50)
                        }
                    }
                    .padding()
                }
                
                Button {
                    model.camera.switchCaptureDevice()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundColor(.white)
                        .padding()
                }
            } else {
                Button {
                    withAnimation(.snappy) {
                        started = true
                    }
                } label: {
                    Text("Start Live Drive")
                        .font(.headline)
                        .bold()
                        .padding()
                        .foregroundStyle(Color.black)
                        .background(Capsule().fill(Color.white))
                }
                .padding()
            }
            Spacer()
        }
        .buttonStyle(.plain)
        .toolbar(started ? .hidden : .visible, for: .navigationBar)
        .toolbar(started ? .hidden : .visible, for: .tabBar)
    }
    
    func playSound() {
        player?.play()
        generator.notificationOccurred(.error)
    }
}
