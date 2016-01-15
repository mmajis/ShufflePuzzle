//
//  ViewController.swift
//  ShufflePuzzle
//
//

import UIKit
import SnapKit
import AudioToolbox

class ViewController: UIViewController, UICollectionViewDataSource, GridCellDelegate {

    var grid: UICollectionView!
    var items: [Int] = Array(0 ... 15)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        grid.registerClass(GridCell.self, forCellWithReuseIdentifier: "GridCell")
        
        initGame()
        
    }

    func initGame() {
        items.sortInPlace { (a, b) -> Bool in
            return arc4random_uniform(2) == 0
        }
        grid.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func loadView() {
        super.loadView()
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSizeMake(75, 75)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10)
        
        grid = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        grid.dataSource = self
        
        grid.backgroundColor = .whiteColor()
        
        self.view.addSubview(grid)
        
    }


    override func updateViewConstraints() {
        grid.snp_updateConstraints { (make) -> Void in
            make.width.height.equalTo(320)
            make.center.equalTo(self.view)
        }
        super.updateViewConstraints()
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("GridCell", forIndexPath: indexPath) as! GridCell
        let item = items[indexPath.item]
        if item == 0 {
            cell.label.hidden = true
        } else {
            cell.label.text = String(items[indexPath.item])
            cell.label.hidden = false
        }
        cell.delegate = self
        return cell
    }
    
    func isInArray(index: Int) -> Bool {
        return index >= 0 && index < items.count
    }
    
    func gridCell(gridCell: GridCell, didEndLongPressAtPoint point: CGPoint) {
        if let currentPath = grid.indexPathForCell(gridCell) {
            let convertedPoint = grid.convertPoint(point, fromView: gridCell)
            if let newPath = grid.indexPathForItemAtPoint(convertedPoint) {
                if self.items[newPath.row] == 0 {
                    if ((isInArray(currentPath.row - 1) && self.items[currentPath.row - 1] == 0 ) ||
                        (isInArray(currentPath.row + 1) && self.items[currentPath.row + 1] == 0 ) ||
                        (isInArray(currentPath.row + 4) && self.items[currentPath.row + 4] == 0 ) ||
                        (isInArray(currentPath.row - 4) && self.items[currentPath.row - 4] == 0 )) {
                            grid.performBatchUpdates({ () -> Void in
                                self.grid.moveItemAtIndexPath(currentPath, toIndexPath: newPath)
                                self.grid.moveItemAtIndexPath(newPath, toIndexPath: currentPath)
                                swap(&self.items[currentPath.row], &self.items[newPath.row])
                                }, completion: { someBoolean in
                                    var won = true
                                    let start = self.items[0] == 0 ? 1 : 0
                                    let end = self.items[0] == 0 ? 15 : 14
                                    for i in start ... end {
                                        if self.items[i] != i + 1 {
                                            won = false
                                            break
                                        }
                                    }
                                    if won {
                                        let alertController = UIAlertController(title: "You won!", message: "Congratulations!", preferredStyle: .Alert)
                                        let OKAction = UIAlertAction(title: "Play again", style: .Default) { (action) in
                                            self.initGame()
                                        }
                                        alertController.addAction(OKAction)
                                        AudioServicesPlaySystemSound(SystemSoundID(1025))
                                        self.presentViewController(alertController, animated: true){}
                                    }
                                    
                            })
                    }
                }
            }
        }
        
    }

}

protocol GridCellDelegate: NSObjectProtocol {
    func gridCell(gridCell: GridCell, didEndLongPressAtPoint point: CGPoint)
}

class GridCell: UICollectionViewCell {
    var label =  UILabel()
    weak var delegate: GridCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = UIFont(name: "HelveticaNeue-CondensedBold", size: 30)
        label.textAlignment = .Center
        label.backgroundColor = UIColor(white: 0.95, alpha: 1)
        label.layer.shadowRadius = 1
        label.layer.shadowOpacity = 0.3
        label.layer.shadowOffset = CGSizeZero
        self.contentView.addSubview(label)
        
        let lp = UILongPressGestureRecognizer(target: self, action: "didLongPress:")
        lp.minimumPressDuration = 0
        label.addGestureRecognizer(lp)
        label.userInteractionEnabled = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("This no support coder")
    }
    
    override func updateConstraints() {
        label.snp_updateConstraints { (make) -> Void in
            make.edges.equalTo(self.contentView).inset(UIEdgeInsetsMake(10, 10, 10, 10))
        }
        super.updateConstraints()
    }
    
    func didLongPress(sender: UILongPressGestureRecognizer) {
        if (sender.state == .Began) {
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.label.transform = CGAffineTransformMakeScale(1.05, 1.05)
                self.label.layer.shadowRadius = 2
            })
        } else if (sender.state == .Ended) {
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.label.transform = CGAffineTransformIdentity
                self.label.layer.shadowRadius = 1
            })
            delegate?.gridCell(self, didEndLongPressAtPoint: sender.locationInView(self.contentView))
        }
    }
    
    override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }
    
}
