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

let π = CGFloat(M_PI)
let π2 = CGFloat(2.0 * M_PI)

class VisualizationViewController : UIViewController, FFTProcessorDelegate, PlayerStreamProcessor
{
    private var _sceneView:      SCNView?
    private var _icosphereScene: WireframeIcosphereScene = WireframeIcosphereScene()
    private var _levelsScene:    LevelMeterScene = LevelMeterScene(size: CGSizeZero)
    private var _fftProcessor:   FFTProcessor = FFTProcessor()
    
    var levelMetersCenter: CGPoint = CGPointZero
    {
        didSet
        {
            let sceneSize = _levelsScene.size
            let sceneCenter = CGPoint(x: levelMetersCenter.x, y: sceneSize.height - levelMetersCenter.y)
            _levelsScene.center = sceneCenter
        }
    }
    
    // MARK: API
    
    func setLevelMetersVisible(visible: Bool, animated: Bool)
    {
        if (animated) {
            var fadeAction: SKAction? = nil
            if (visible) {
                fadeAction = SKAction.fadeInWithDuration(0.5)
            } else {
                fadeAction = SKAction.fadeInWithDuration(0.5)
            }
            _levelsScene.runAction(fadeAction!)
        } else {
            _levelsScene.alpha = 0.0
        }
    }
    
    // MARK: UIViewController
    
    override func loadView()
    {
        _sceneView = SCNView(frame: UIScreen.mainScreen().bounds)
        _sceneView?.backgroundColor = UIColor.blackColor()
        _sceneView?.scene = _icosphereScene
        _sceneView?.overlaySKScene = _levelsScene
        
        self.view = _sceneView
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        _fftProcessor.delegate = self
        _sceneView?.play(nil)
    }
    
    override func viewDidDisappear(animated: Bool)
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
        _levelsScene.center = CGPoint(x: CGRectGetMidX(bounds), y: CGRectGetMidY(bounds))
    }
    
    // MARK: AudioStreamDelegate
    
    func playerStreamDidDecodeAudioData(player: Player, data: NSData, framesCount: UInt)
    {
        _fftProcessor.processAudioData(data, withFramesCount: framesCount)
    }
    
    // MARK: FFTProcessorDelegate
    
    func processor(processor: FFTProcessor, didProcessFrequencyData data: NSData)
    {
        _levelsScene.updateFrequency(data)
    }
}

internal class WireframeIcosphereScene : SCNScene
{
    private var _sceneView:   SCNView?
    private var _cameraNode:  SCNNode = SCNNode()
    private var _sphereNode:  SCNNode = SCNNode()
    
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
            let icosphereSceneURL = NSBundle.mainBundle().URLForResource("wireframe_uvsphere",
                                                                         withExtension: "dae",
                                                                         subdirectory: "3DAssets.scnassets")
            let icosphereScene = try SCNScene(URL: icosphereSceneURL!, options: nil)
            
            if let icosphereNode = icosphereScene.rootNode.childNodeWithName("Sphere", recursively: false) {
                let material = SCNMaterial()
                material.diffuse.contents = UIColor(red: 0.08, green: 0.41, blue: 0.55, alpha: 0.8)
                material.doubleSided = true
                
                let geometry = icosphereNode.geometry
                geometry?.firstMaterial = material
                
                _sphereNode.addChildNode(icosphereNode)
                self.rootNode.addChildNode(_sphereNode)
            } else {
                print("could not find icosphere node in scene file")
            }
        } catch {
            print("error loading scene from file")
        }
    }
    
    internal func _setupAnimations()
    {
        let rotationAction = SCNAction.rotateByAngle(2.0 * π, aroundAxis: SCNVector3Make(0.0, 1.0, 0.0), duration: 150.0)
        let permanentAction = SCNAction.repeatActionForever(rotationAction)
        _sphereNode.runAction(permanentAction)
    }
}

internal class LevelMeterScene : SKScene
{
    private var _levelNodes: [SKSpriteNode] = []
    private var _filters:    [LowPassFilter] = []
    
    private let _kLevelsCount:  UInt = 50
    private let _kFilterLength: UInt = 1
    private let _kFFTScale:     Float = 15.0
    
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
    
    func updateFrequency(frequencySignalData: NSData)
    {
        let ptr = UnsafePointer<Float>(frequencySignalData.bytes)
        let freqValuesCount = frequencySignalData.length / sizeof(Float)
        let buffer = UnsafeBufferPointer<Float>(start: ptr, count: freqValuesCount)
        
        let filtersCount = _filters.count
        for (filterIdx, filter) in _filters.enumerate() {
            let r = Float(filterIdx) / Float(filtersCount)
            let bufferIdx = Int(r * Float(freqValuesCount))
            let val = buffer[bufferIdx] * (_kFFTScale * Float(self.size.width))
            filter.updateWithSignalValue(val)
        }
    }
    
    // MARK: Overrides
    
    override func update(currentTime: NSTimeInterval)
    {
        super.update(currentTime)
        
        for (levelIdx, levelNode) in _levelNodes.enumerate() {
            let filter = _filters[levelIdx]
            let height = CGFloat(filter.movingAverage())
            
            if (!height.isNaN) {
                let act = SKAction.resizeToHeight(height, duration: 0.05)
                levelNode.runAction(act)
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
            let color = UIColor.whiteColor()
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
        _filters = filters
    }
}
