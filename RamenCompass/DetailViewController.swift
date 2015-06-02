//
//  DetailViewController.swift
//  RamenCompass
//
//  Created by Ian Parker on 5/17/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit
import RealmSwift

@objc
protocol DetailViewControllerDelegate {
    func addressDirectionButtonPressed()
}


class DetailViewController: UIViewController {
    
    @IBOutlet weak var tableview: UITableView!
    let leadingLabels: [String] = ["TRY THIS", "ADDRESS", "HOURS"]
    var delegate: DetailViewControllerDelegate?
    var detailSelectedRamen: Venue?
    @IBOutlet weak var pictureIV: UIImageView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableview.delegate = self
        tableview.dataSource = self

        NSNotificationCenter.defaultCenter().addObserver(self, selector:"reload:", name: "selectedRamenChanged", object: nil)

    }
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func reload( notification: NSNotification){
        
        let userInfo = notification.userInfo as! [String: AnyObject]
        detailSelectedRamen = userInfo["selectedRamen"] as! Venue?
        println("detail reload notif \(detailSelectedRamen)")
        tableview.reloadData()
        pictureIV.sd_setImageWithURL(NSURL(string: self.detailSelectedRamen!.photoUrl))
    }
    
    @IBAction func addressButtonPressed(sender: AnyObject) {
        delegate?.addressDirectionButtonPressed()
    }
    
}

extension DetailViewController: UITableViewDataSource, UITableViewDelegate{
    

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return leadingLabels.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("detail", forIndexPath: indexPath) as! DetailTableViewCell
        
        cell.leadingLabel.text = leadingLabels[indexPath.row]
        if (indexPath.row == leadingLabels.indexOfObject("TRY THIS")){
            cell.descriptionLabel.text = (detailSelectedRamen?.tips == "") ? "Get the ramen, duhhh! Apparently it's pretty tasty here." : detailSelectedRamen?.tips
        }
        else if (indexPath.row == leadingLabels.indexOfObject("ADDRESS")){
            cell.descriptionLabel.text = detailSelectedRamen?.location.formattedAddress
        }
        else if (indexPath.row == leadingLabels.indexOfObject("HOURS")){
            cell.descriptionLabel.text = (detailSelectedRamen?.hours == "") ? "Shhh...No one knows. It's a secret. Show up sometime and maybe you'll get lucky." : detailSelectedRamen?.hours
        }
        
        return cell
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.row == leadingLabels.indexOfObject("ADDRESS")){
            addressButtonPressed(self)
        }
    }
    
}

class DetailTableViewCell: UITableViewCell{
    
    @IBOutlet weak var leadingLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}

extension Array {
    
    func indexOfObject<T:Equatable>(object: T) -> Int {
        var searchIndex = NSNotFound
        for (counter, item) in enumerate(self) {
            if item as! T == object {
                searchIndex = counter
                break
            }
        }
        return searchIndex
    }
    
    mutating func removeObject<T:Equatable>(object: T) -> T {
        for (counter, item) in enumerate(self) {
            if item as! T == object {
                self.removeAtIndex(counter)
            }
        }
        return object
    }
    
    
}
