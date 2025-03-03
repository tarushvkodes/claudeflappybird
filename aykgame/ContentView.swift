//
//  ContentView.swift
//  aykgame
//
//  Created by Tarushv Kosgi on 3/2/25.
//

import SwiftUI

struct Bird {
    var position: CGPoint
    var velocity: CGFloat = 0
    var size: CGSize = CGSize(width: 40, height: 40)
    
    mutating func applyGravity(deltaTime: TimeInterval) {
        let gravity: CGFloat = 1500
        velocity += gravity * CGFloat(deltaTime)
        position.y += velocity * CGFloat(deltaTime)
    }
    
    mutating func jump() {
        velocity = -500
    }
}

struct Pipe {
    var position: CGPoint
    let width: CGFloat = 60
    let gap: CGFloat = 150
    let height: CGFloat
    
    var topRect: CGRect {
        CGRect(x: position.x, y: 0, width: width, height: position.y - gap/2)
    }
    
    var bottomRect: CGRect {
        CGRect(x: position.x, y: position.y + gap/2, width: width, height: height - (position.y + gap/2))
    }
}

class GameState: ObservableObject {
    @Published var bird: Bird
    @Published var pipes: [Pipe] = []
    @Published var isGameOver = false
    @Published var score = 0
    private var lastUpdateTime: TimeInterval = 0
    
    init() {
        bird = Bird(position: CGPoint(x: 100, y: UIScreen.main.bounds.midY))
        setupPipes()
    }
    
    func setupPipes() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        pipes = (0...2).map { i in
            Pipe(position: CGPoint(x: screenWidth + CGFloat(i * 300), y: CGFloat.random(in: 200...screenHeight-200)),
                 height: screenHeight)
        }
    }
    
    func update(currentTime: TimeInterval) {
        guard !isGameOver else { return }
        
        let deltaTime = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Update bird
        bird.applyGravity(deltaTime: deltaTime)
        
        // Update pipes
        for i in pipes.indices {
            pipes[i].position.x -= 200 * CGFloat(deltaTime)
        }
        
        // Reset pipes that went off screen
        for i in pipes.indices {
            if pipes[i].position.x < -100 {
                pipes[i].position.x = pipes[i].position.x + CGFloat(pipes.count * 300)
                pipes[i].position.y = CGFloat.random(in: 200...UIScreen.main.bounds.height-200)
                score += 1
            }
        }
        
        // Check collisions
        checkCollisions()
    }
    
    func checkCollisions() {
        let birdRect = CGRect(x: bird.position.x - bird.size.width/2,
                            y: bird.position.y - bird.size.height/2,
                            width: bird.size.width,
                            height: bird.size.height)
        
        // Check floor/ceiling collision
        if bird.position.y < 0 || bird.position.y > UIScreen.main.bounds.height {
            isGameOver = true
        }
        
        // Check pipe collisions
        for pipe in pipes {
            if birdRect.intersects(pipe.topRect) || birdRect.intersects(pipe.bottomRect) {
                isGameOver = true
            }
        }
    }
    
    func restart() {
        bird = Bird(position: CGPoint(x: 100, y: UIScreen.main.bounds.midY))
        setupPipes()
        score = 0
        isGameOver = false
        lastUpdateTime = 0
    }
}

struct ContentView: View {
    @StateObject private var gameState = GameState()
    let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.blue.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                
                // Bird
                Circle()
                    .fill(Color.yellow)
                    .frame(width: gameState.bird.size.width, height: gameState.bird.size.height)
                    .position(gameState.bird.position)
                
                // Pipes
                ForEach(gameState.pipes.indices, id: \.self) { index in
                    let pipe = gameState.pipes[index]
                    ZStack {
                        // Top pipe
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: pipe.width, height: pipe.topRect.height)
                            .position(x: pipe.position.x + pipe.width/2, y: pipe.topRect.height/2)
                        
                        // Bottom pipe
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: pipe.width, height: pipe.bottomRect.height)
                            .position(x: pipe.position.x + pipe.width/2, y: pipe.bottomRect.minY + pipe.bottomRect.height/2)
                    }
                }
                
                // Score
                Text("Score: \(gameState.score)")
                    .font(.largeTitle)
                    .position(x: 100, y: 50)
                
                if gameState.isGameOver {
                    VStack {
                        Text("Game Over!")
                            .font(.largeTitle)
                        Button("Restart") {
                            gameState.restart()
                        }
                        .font(.title)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .onTapGesture {
            if !gameState.isGameOver {
                gameState.bird.jump()
            }
        }
        .onReceive(timer) { time in
            gameState.update(currentTime: time.timeIntervalSinceReferenceDate)
        }
    }
}

#Preview {
    ContentView()
}
