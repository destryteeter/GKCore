#if !os(macOS)
import UIKit
#endif
import SpriteKit
import GameplayKit

public enum GKC {
    public static var version = "1.0"
    
    public enum SK {
    
        open class Scene: SKScene {
            
            // Accessibility
            public var testableNodes: [SKNode] = []
            public var accessibleElements: [UIAccessibilityElement] = []
            
            #if !os(macOS)
            public var viewController: UIViewController?
            #endif
            public var entities = [GKEntity]()
            public var graphs = [String : GKGraph]()
            
            public var stateMachines: [GKStateMachine] = []
            public var stateMachine: GKStateMachine?

            public var player: GKC.SK.AgentNode?
            public var agentSystem: GKComponentSystem<GKComponent>?
            public var trackingAgent: GKAgent2D?
            private var _stopGoal: GKGoal?
            public var stopGoal: GKGoal {
                get {
                    if _stopGoal == nil {
                        _stopGoal = GKGoal.init(toReachTargetSpeed: 0)
                    }
                    return _stopGoal!
                }
            }
            
            private var lastUpdateTime : TimeInterval = 0
            
            override open func update(_ currentTime: TimeInterval) {
                // Called before each frame is rendered
                
                // Initialize _lastUpdateTime if it has not already been
                if (self.lastUpdateTime == 0) {
                    self.lastUpdateTime = currentTime
                }
                
                // Calculate time since last update
                let dt = currentTime - self.lastUpdateTime
                
                // Update entities
                for entity in self.entities {
                    entity.update(deltaTime: dt)
                }
                
                // Update entities
                for stateMachine in self.stateMachines {
                    stateMachine.update(deltaTime: dt)
                }
                
                self.lastUpdateTime = currentTime

                // Update state machine
                stateMachine?.update(deltaTime: dt)
                
                // Update agent system
                self.agentSystem?.update(deltaTime: dt)
            }
        }
        
        open class Node: SKNode {
            
        }
        
        open class AgentNode: GKC.SK.Node, GKAgentDelegate {

            private var _agent: GKAgent2D
            public var agent: GKAgent2D {
                get { return _agent }
            }
            
            public var node: SKNode?
            
            public init(scene: SKScene, node: SKNode, copyNode: Bool = false, position: CGPoint, rotation: Float = 0, maxSpeed: Float = 1000, maxAccelleration: Float = 500, mass: Float = 0.1) {
                _agent = GKAgent2D()
                
                super.init()
                
                self.position = position
                self.zRotation = CGFloat(rotation)
                scene.addChild(self)
                
                _agent.radius = Float(node.frame.size.width / 2.0)
                _agent.position = vector2(Float(position.x), Float(position.y))
                _agent.rotation = rotation
                _agent.maxSpeed = maxSpeed
                _agent.maxAcceleration = maxAccelleration
                _agent.mass = mass
                _agent.delegate = self
                
                if copyNode {
                    if let n = node.copy() as? SKNode {
                        n.position = .zero
                        self.addChild(n)
                    }
                }
                else {
                    self.node = node
                    self.node?.position = position
                }
            }
            
            required public init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            public func agentWillUpdate(_ agent: GKAgent) {
                
            }
            
            public func agentDidUpdate(_ agent: GKAgent) {
                if let agent2D = agent as? GKAgent2D {
                    self.position = CGPoint(x: CGFloat(agent2D.position.x), y: CGFloat(agent2D.position.y))
                    self.zRotation = CGFloat(agent2D.rotation)
                    
                    self.node?.position = self.position
                    self.node?.zRotation = self.zRotation
                }
            }
        }
    }
    
    public enum GK {
        open class State: GKState {
            
            /// A reference to the game scene, used to alter sprites.
            public let game: GKC.SK.Scene
            
            /// The name of the node in the game scene that is associated with this state.
            let associatedNodeName: String
            
            /// Convenience property to get the state's associated sprite node.
            public var associatedNode: SKSpriteNode? {
                return game.childNode(withName: "//\(associatedNodeName)") as? SKSpriteNode
            }
            
            // MARK: Initialization
            
            public init(game: GKC.SK.Scene, associatedNodeName: String) {
                self.game = game
                self.associatedNodeName = associatedNodeName
            }
            
            // MARK: GKState overrides
            
            /// Highlights the sprite representing the state.
            override open func didEnter(from previousState: GKState?) {
                print("\(#function) \(associatedNodeName)")
                guard let associatedNode = associatedNode else { return }
                associatedNode.color = SKColor.darkGray
            }
            
            /// Unhighlights the sprite representing the state.
            override open func willExit(to nextState: GKState) {
                print("\(#function) \(associatedNodeName)")
                guard let associatedNode = associatedNode else { return }
                associatedNode.color = SKColor.clear
            }
        }
    }
}
