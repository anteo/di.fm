//
//  VisualizationViewController.swift
//  DigitallyImportedVisualizer
//
//  Created by Charles Magahern on 6/26/16.
//  Copyright © 2016 zanneth. All rights reserved.
//

import Darwin
import SceneKit
import SpriteKit
import UIKit

let π = CGFloat.pi
let π2 = CGFloat.pi * 2.0

class VisualizationViewController : UIViewController, FFTProcessorDelegate, PlayerStreamProcessor
{
    fileprivate var _sceneView:      SCNView?
    fileprivate var _icosphereScene: WireframeIcosphereScene = WireframeIcosphereScene()
    fileprivate var _levelsScene:    LevelMeterScene = LevelMeterScene(size: CGSize.zero)
    fileprivate var _fftProcessor:   FFTProcessor = FFTProcessor()
    
    var levelMetersCenter: CGPoint = CGPoint.zero
    {
        didSet
        {
            let sceneSize = _levelsScene.size
            let sceneCenter = CGPoint(x: levelMetersCenter.x, y: sceneSize.height - levelMetersCenter.y)
            _levelsScene.center = sceneCenter
        }
    }
    
    // MARK: API
    
    func setLevelMetersVisible(_ visible: Bool, animated: Bool)
    {
        if (animated) {
            var fadeAction: SKAction? = nil
            if (visible) {
                fadeAction = SKAction.fadeIn(withDuration: 0.5)
            } else {
                fadeAction = SKAction.fadeIn(withDuration: 0.5)
            }
            _levelsScene.run(fadeAction!)
        } else {
            _levelsScene.alpha = 0.0
        }
    }
    
    // MARK: UIViewController
    
    override func loadView()
    {
        // can't use Metal because it's crashy
        _sceneView = SCNView(frame: UIScreen.main.bounds, options: [SCNView.Option.preferredRenderingAPI.rawValue : SCNRenderingAPI.openGLES2.rawValue])
        _sceneView?.backgroundColor = UIColor.black
        _sceneView?.scene = _icosphereScene
        _sceneView?.overlaySKScene = _levelsScene
        
        self.view = _sceneView
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        _fftProcessor.delegate = self
        _sceneView?.play(nil)
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        _sceneView?.pause(nil)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        let bounds = self.view.bounds
        _levelsScene.size = bounds.size
        _levelsScene.radius = bounds.size.width / 8.0
        _levelsScene.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    // MARK: AudioStreamDelegate
    
    func playerStreamDidDecodeAudioData(_ player: Player, data: Data, framesCount: UInt)
    {
        _fftProcessor.processAudioData(data, withFramesCount: framesCount)
    }
    
    // MARK: FFTProcessorDelegate
    
    func processor(_ processor: FFTProcessor, didProcessFrequencyData data: Data)
    {
        _levelsScene.updateFrequency(data)
    }
}

internal class WireframeIcosphereScene : SCNScene
{
    fileprivate var _sceneView:   SCNView?
    fileprivate var _cameraNode:  SCNNode = SCNNode()
    fileprivate var _sphereNode:  SCNNode = SCNNode()
    
    override init()
    {
        super.init()
        _setupCamera()
        _setupModel()
        _setupAnimations()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Internal
    
    internal func _setupCamera()
    {
        let camera = SCNCamera()
        camera.zNear = 0.001
        
        _cameraNode.camera = camera
        _cameraNode.position = SCNVector3Zero
        self.rootNode.addChildNode(_cameraNode)
    }
    
    internal func _setupModel()
    {
        // load sphere model from file
        do {
            let icosphereSceneURL = Bundle.main.url(forResource: "wireframe_uvsphere",
                                                                         withExtension: "dae",
                                                                         subdirectory: "3DAssets.scnassets")
            let icosphereScene = try SCNScene(url: icosphereSceneURL!, options: nil)
            
            if let icosphereNode = icosphereScene.rootNode.childNode(withName: "Sphere", recursively: false) {
                let material = SCNMaterial()
                material.diffuse.contents = UIColor(red: 0.08, green: 0.41, blue: 0.55, alpha: 0.8)
                material.isDoubleSided = true
                
                let geometry = icosphereNode.geometry
                geometry?.firstMaterial = material
                
                _sphereNode.addChildNode(icosphereNode)
                self.rootNode.addChildNode(_sphereNode)
            } else {
                #if DEBUG
                print("could not find icosphere node in scene file")
                #endif
            }
        } catch {
            #if DEBUG
            print("error loading scene from file")
            #endif
        }
    }
    
    internal func _setupAnimations()
    {
        let rotationAction = SCNAction.rotate(by: 2.0 * π, around: SCNVector3Make(0.0, 1.0, 0.0), duration: 200.0)
        let permanentAction = SCNAction.repeatForever(rotationAction)
        _sphereNode.runAction(permanentAction)
    }
}

internal class LevelMeterScene : SKScene
{
    fileprivate var _levelNodes:    [SKSpriteNode] = []
    fileprivate var _currentLevels: [Float] = []
    
    fileprivate let _kLevelsCount:  UInt = 50
    fileprivate let _kFilterLength: UInt = 1
    
    override init(size: CGSize)
    {
        super.init(size: size)
        _generateLevels()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: API
    
    var center: CGPoint = CGPoint()
    {
        didSet
        {
            _generateLevels()
        }
    }
    
    var radius: CGFloat = 1.0
    {
        didSet
        {
            _generateLevels()
        }
    }
    
    func updateFrequency(_ frequencySignalData: Data)
    {
        let ptr = (frequencySignalData as NSData).bytes.bindMemory(to: Float.self, capacity: frequencySignalData.count)
        let freqValuesCount = frequencySignalData.count / MemoryLayout<Float>.size
        let buffer = UnsafeBufferPointer<Float>(start: ptr, count: freqValuesCount)
        
        /* FUNNY MATH AHEAD! */
        
        let count = _levelNodes.count
        var values = Array<Float>(repeating: 0.0, count: count)
        var sum: Float = 0.0
        
        for i in 0 ..< count {
            let r = Float(i) / Float(count)
            let bufferIdx = Int(r * Float(freqValuesCount))
            let val = buffer[bufferIdx] * 2000.0
            values[i] = val
            sum += val
        }
        
        let avg = sum / Float(count)
        for (idx, value) in values.enumerated() {
            let x = avg - value
            let mul = pow(x, 3.0) + 1.0
            let scaledValue = max(value * mul, 0.0) * 80.0
            _currentLevels[idx] = scaledValue
        }
    }
    
    // MARK: Overrides
    
    override func update(_ currentTime: TimeInterval)
    {
        super.update(currentTime)
        
        for (levelIdx, levelNode) in _levelNodes.enumerated() {
            let level = CGFloat(_currentLevels[levelIdx])
            let maxHeight = self.radius * 0.75
            let height = min(level, maxHeight)
            
            if (!height.isNaN) {
                let act = SKAction.resize(toHeight: height, duration: 0.05)
                levelNode.run(act)
            }
        }
    }
    
    override var size: CGSize
    {
        didSet
        {
            _generateLevels()
        }
    }
    
    // MARK: Internal
    
    internal func _generateLevels()
    {
        let levelsTexture = SKTexture(imageNamed: "levels_texture")
        let levelsWidth = CGFloat(self.size.width) / CGFloat(_kLevelsCount)
        var levelNodes: [SKSpriteNode] = []
        var filters: [LowPassFilter] = []
        
        let center = self.center
        let radius = self.radius
        
        for i in 0 ..< _kLevelsCount {
            let a = CGFloat(i) / CGFloat(_kLevelsCount)
            let sz = CGSize(width: levelsWidth, height: 20.0)
            let color = UIColor.white
            let node = SKSpriteNode(color: color, size: sz)
            node.texture = levelsTexture
            
            let θ = a * π2
            let x = radius * cos(θ)
            let y = radius * sin(θ)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            node.position = CGPoint(x: center.x + x, y: center.y + y)
            node.zRotation = (θ - π / 2.0)
            
            self.addChild(node)
            levelNodes.append(node)
            filters.append(LowPassFilter(length: _kFilterLength))
        }
        
        _levelNodes.forEach { $0.removeFromParent() }
        _levelNodes = levelNodes
        _currentLevels = Array<Float>(repeating: 0.0, count: levelNodes.count)
    }
}
