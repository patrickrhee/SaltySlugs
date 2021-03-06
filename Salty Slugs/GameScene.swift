//
//  GameScene.swift
//  Salty Slugs
//
//  Created by Patrick Rhee on 1/3/20.
//  Copyright © 2020 Rhee Family. All rights reserved.
//

import SpriteKit
import UIKit
import GameplayKit

extension SKSpriteNode {
    func drawBorder(color: UIColor, width: CGFloat) {
        let shapeNode = SKShapeNode(rect: frame)
        shapeNode.fillColor = .clear
        shapeNode.strokeColor = color
        shapeNode.lineWidth = width
        addChild(shapeNode)
    }
}

class GameScene: SKScene{
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    // Create a camera to follow our slug player
    private var cam = SKCameraNode();
    
    // Create our player slug character
    private var player = SKSpriteNode();
    private var playerWalkFrames : [SKTexture] = [];
    
    // Create our salt particle
    private var saltParticle = SKSpriteNode();
    
    // Keep track of last touch position for player slug to go to.
    private var touchPos : CGPoint?
    
    // Keep track of if the slug animation is player
    private var walkAnimOn = false;
    
    // Function to create slug player sprite and put it in the SKScene
    func buildPlayerSlug()
    {
        // Build a texture atlas with our .atlas folder as input, then copy it
        // into the temp walkFrames SKTexture array, which is then copied into
        // our global SKTexture array variable.
        let playerSlugWalkAnimatedAtlas = SKTextureAtlas(named: "player_walk");
        var walkFrames: [SKTexture] = [];
        
        // For every SKTexture in the atlas, append it to our walkFrames array
        let numImages = playerSlugWalkAnimatedAtlas.textureNames.count;
        for i in 0...(numImages-1)
        {
            let playerWalkTextureName = "player_walk_\(i)"
            
            walkFrames.append(playerSlugWalkAnimatedAtlas.textureNamed(playerWalkTextureName))
        }
        
        // Global array is equal to local temp array.
        playerWalkFrames = walkFrames;
        
        // Set the player sprite with first texture/image.
        let firstFrameTexture = playerWalkFrames[0];
        player = SKSpriteNode(texture: firstFrameTexture);
        player.position = CGPoint(x: 0, y: 0); // Set sprite to cords (0,0)
        player.size = CGSize(width: 400, height: 280)
        addChild(player); // Add player sprite to the scene
        
    }
    
    // Function to animate player slug
    func animatePlayerSlug()
    {
        player.run(SKAction.repeatForever(SKAction.animate(with: playerWalkFrames, timePerFrame: 0.15, resize:false, restore: true)), withKey:"walkingInPlaceSlug");
        // The withKey attribute identifies this SKAction with a name, so
        // if this func is called again, we just restart this action, not create
        // a new one.
    }
    
    // Creates the particle of salt to rain on slug character
    func initializeSaltParticle()
    {
        saltParticle = SKSpriteNode(texture: SKTexture(imageNamed: "salt_static"));
        saltParticle.size = CGSize(width:100, height: 100);
        saltParticle.position = CGPoint(x:0, y:0);
        
        // Create sequence of SKActions for salt particle to follow whenever spawned.
        saltParticle.run(SKAction.sequence([
            SKAction.moveBy(x: 0, y: -500, duration: 3),
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ]));
    }
    
    func startSaltRain()
    {
        let createSaltGrain = SKAction.run {
            // Create a copy of salt particle
            let saltGrain = self.saltParticle.copy() as! SKSpriteNode;
            // Place salt grain in random place near the player.
            var randomCGFloatY = CGFloat.random(in: -200 ... 400);
            if(randomCGFloatY > -130 && randomCGFloatY < 0)
            {
                randomCGFloatY -= 130;
            }
            else if(randomCGFloatY < 130 && randomCGFloatY >= 0)
            {
                randomCGFloatY += 130;
            }
            var randomCGFloatX = CGFloat.random(in: -400 ... 400);
            if(randomCGFloatX > -100 && randomCGFloatX < 0)
            {
                randomCGFloatX -= 100;
            }
            else if(randomCGFloatX < 100 && randomCGFloatX >= 0)
            {
                randomCGFloatX += 100;
            }
            self.saltParticle.position = CGPoint(x:self.player.position.x+randomCGFloatX, y:self.player.position.y+randomCGFloatY);
            // Add the salt particle into scene
            self.addChild(saltGrain);
        }
        // Wait for a certain (possibly random) amount of time before next salt grain falls.
        let wait = SKAction.wait(forDuration: 1.0);
        // Combine all of this stuff into a sequence
        let saltGenerationSequence = SKAction.sequence([createSaltGrain,wait]);
        // Run the salt spawning action sequence forever.
        run(SKAction.repeatForever(saltGenerationSequence), withKey: "saltRainLoop");
    }
    
    func stopSaltRain()
    {
        // Remove the forever running function with key "saltRainLoop"
        removeAction(forKey: "saltRainLoop");
    }
    
    override func didMove(to view: SKView) {
        // Create a background color for the scene.
        backgroundColor = SKColor.init(red: 185/255, green: 235/255, blue: 145/255, alpha: 1.0);
        
        // Make "cam" the camera for our skScene
        self.camera = cam;
        
        // Set player slug sprite in scene
        buildPlayerSlug();
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
        
        // Initialize salt particle so we can create copies of it.
        initializeSaltParticle();
        startSaltRain();
    }
    
    func touchDown(atPoint pos : CGPoint) {
        touchPos = pos;
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        touchPos = pos;
    }
    
    func touchUp(atPoint pos : CGPoint) {
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    var i = 0;
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        // move the player's position towards x and y direction by 2 everytime touchMoved fires.
        if(touchPos != nil)
        {
            let xDiff = touchPos!.x - player.position.x;
            let yDiff = touchPos!.y - player.position.y;
            let distDiff : CGFloat = (sqrt((xDiff*xDiff)+(yDiff*yDiff)));
            
            if(distDiff > 4)
            {
                // If animation is off, turn it on
                if(!walkAnimOn)
                {
                    animatePlayerSlug();
                    walkAnimOn = true;
                }
                // Move the slug to appropriate position
                if(xDiff < -2)
                {
                    player.position.x += (xDiff * 2/distDiff);
                    player.xScale = abs(player.xScale);
                }
                else if(xDiff > 2)
                {
                    player.position.x += (xDiff * 2/distDiff);
                    player.xScale = abs(player.xScale) * -1;
                }
                
                if(yDiff < -2)
                {
                    player.position.y += (yDiff * 2/distDiff);
                }
                else if(yDiff > 2)
                {
                    player.position.y += (yDiff * 2/distDiff);
                }
            }else
            {
                // If animation is on, turn it off
                if(walkAnimOn)
                {
                    player.removeAllActions();
                    walkAnimOn = false;
                }
            }
        }
        cam.position = player.position;
    }
}
