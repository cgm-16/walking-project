//
//  AnimationManager.swift
//  walking-project
//
//  Created by CGM on 2/23/24.
//

import UIKit
import CoreData

enum Direction {
    case up, down
}

class EmojiShowerViewControllerManager: ObservableObject {
    @Published var emojiShowerViewController = EmojiShowerViewController()
}

class EmojiShowerViewController: UIViewController {
    let emojiShower = CAEmitterLayer()
    let emojiBubble = CAEmitterLayer()
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
        createEmojiBubble()
    }
    
    func startEmojiBubble(emoteType: EmoteType, duration: CGFloat = 3) {
        emojiBubble.emitterCells = [
            makeEmojiEmitterCell(
            emoji: emojiDict[emoteType.text] ?? "",
            totalCount: 1,
            direction: .up)
        ]
        
        emojiBubble.birthRate = 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.endEmojiBubble()
        }
    }
    
    private func createEmojiBubble() {
        emojiBubble.emitterPosition = CGPoint(x: view.center.x, y: 1000)
        emojiBubble.emitterShape = .line
        emojiBubble.emitterSize = CGSize(width: view.frame.size.width, height: 1)
        
        view.layer.addSublayer(emojiBubble)
    }
    
    // Function to create the emoji shower effect
    private func createEmojiShower(emoteList: [Emotes], duration: CGFloat = 5.0) {
        emojiShower.emitterPosition = CGPoint(x: view.center.x, y: -1000)
        emojiShower.emitterShape = .line
        emojiShower.emitterSize = CGSize(width: view.frame.size.width, height: 1)
        
        var emojiCells = [CAEmitterCell]()

        for emote in emoteList {
            let cell = makeEmojiEmitterCell(
                emoji: emojiDict[emote.emote ?? "HEARTEYES"] ?? "",
                totalCount: emoteList.count,
                direction: .down
            )
            emojiCells.append(cell)
        }
        
        // Set the emitter cells for the emoji emitter
        emojiShower.emitterCells = emojiCells
        
        // Add the emoji emitter to the view's layer
        view.layer.addSublayer(emojiShower)
        
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
    private func makeEmojiEmitterCell(emoji: String, totalCount: Int, direction: Direction) -> CAEmitterCell {
        let cell = CAEmitterCell()
        
        // Set the birth rate (how frequently emojis appear) and lifetime (how long they last)
        cell.birthRate = 24.0/Float(totalCount) > 8.0 ? 24.0/Float(totalCount) : 8.0
        cell.lifetime = 5
        cell.lifetimeRange = 0
        
        // Set the initial velocity and velocity range for the emojis
        cell.velocity = 1000
        cell.velocityRange = 200
        
        // Configure the direction and range of emoji emission
        cell.emissionLongitude = direction == .down ? -CGFloat.pi : 0
        cell.emissionRange = 0
        
        // Set rotation and scale properties for emojis
        cell.spin = 0
        cell.spinRange = 0
        cell.scaleRange = 0
        cell.alphaSpeed = 0
        
        // Create the emoji image from the text
        if let emojiImage = imageFrom(emoji: emoji) {
            cell.contents = emojiImage.cgImage
        }
        
        return cell
    }
    
    // Function to create an image from emoji text
    private func imageFrom(emoji: String) -> UIImage? {
        let nsString = emoji as NSString
        let font = UIFont.systemFont(ofSize: 20) // you can change your font size here
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

    private func endEmojiShower() {
        emojiShower.birthRate = 0
    }
    
    private func endEmojiBubble() {
        emojiBubble.birthRate = 0
    }
}
