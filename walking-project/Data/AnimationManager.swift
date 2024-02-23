//
//  AnimationManager.swift
//  walking-project
//
//  Created by CGM on 2/23/24.
//

import UIKit
import CoreData

class EmojiShowerViewController: UIViewController {
    let emojiEmitter = CAEmitterLayer()
    let viewContext = DataManager.shared.viewContext
    let emojiDict: [String : String] = [
        "HEARTEYES" : "😍",
        "TAUNTFACE" : "😜",
        "WOWFACE" : "😯"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let emotes = try? viewContext.fetch(Emotes.fetchRequest()) {
            createEmojiShower(emoteList: emotes)
        }
    }
    
    // Function to create the emoji shower effect
    func createEmojiShower(emoteList: [Emotes], duration: CGFloat = 5.0) {
        emojiEmitter.emitterPosition = CGPoint(x: view.center.x, y: -700)
        emojiEmitter.emitterShape = .line
        emojiEmitter.emitterSize = CGSize(width: view.frame.size.width, height: 1)
        
        var emojiCells = [CAEmitterCell]()

        for emote in emoteList {
            let cell = makeEmojiEmitterCell(emoji: emojiDict[emote.emote ?? "HEARTEYES"] ?? "", totalCount: emoteList.count)
            emojiCells.append(cell)
        }
        
        // Set the emitter cells for the emoji emitter
        emojiEmitter.emitterCells = emojiCells
        
        // Add the emoji emitter to the view's layer
        view.layer.addSublayer(emojiEmitter)
        
        let emojiDel = NSBatchDeleteRequest(fetchRequest: Emotes.fetchRequest())
        try! viewContext.executeAndMergeChanges(using: emojiDel)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.endEmojiShower()
        }
    }
    
    // Function to create an emitter cell for a specific emoji
    func makeEmojiEmitterCell(emoji: String, totalCount: Int) -> CAEmitterCell {
        let cell = CAEmitterCell()
        
        // Set the birth rate (how frequently emojis appear) and lifetime (how long they last)
        cell.birthRate = 24.0/Float(totalCount) > 8.0 ? 24.0/Float(totalCount) : 8.0
        cell.lifetime = Float.random(in: 10.0...15.0)
        cell.lifetimeRange = 0
        
        // Set the initial velocity and velocity range for the emojis
        cell.velocity = CGFloat.random(in: 300...500)
        cell.velocityRange = -50
        
        // Configure the direction and range of emoji emission
        cell.emissionLongitude = -CGFloat.pi
        cell.emissionRange = CGFloat.pi
        
        // Set rotation and scale properties for emojis
        cell.spin = 1
        cell.spinRange = 3
        cell.scaleRange = 0.5
        cell.scaleSpeed = -0.05
        cell.alphaSpeed = -0.05
        
        // Create the emoji image from the text
        if let emojiImage = imageFrom(emoji: emoji) {
            cell.contents = emojiImage.cgImage
        }
        
        return cell
    }
    
    // Function to create an image from emoji text
    func imageFrom(emoji: String) -> UIImage? {
        let nsString = emoji as NSString
        let font = UIFont.systemFont(ofSize: 30) // you can change your font size here
        let stringAttributes = [NSAttributedString.Key.font: font]
        let imageSize = nsString.size(withAttributes: stringAttributes)
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0) //  begin image context
        UIColor.clear.set() // clear background
        UIRectFill(CGRect(origin: CGPoint(), size: imageSize)) // set rect size
        nsString.draw(at: CGPoint.zero, withAttributes: stringAttributes) // draw text within rect
        let image = UIGraphicsGetImageFromCurrentImageContext() // create image from context
        UIGraphicsEndImageContext() //  end image context
        
        return image ?? UIImage()
    }
    
    func startEmojiShower() {
        emojiEmitter.birthRate = 1
    }
    
    func endEmojiShower() {
        emojiEmitter.birthRate = 0
    }
}
