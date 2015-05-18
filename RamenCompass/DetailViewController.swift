//
//  DetailViewController.swift
//  RamenCompass
//
//  Created by Ian Parker on 5/17/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit

@objc
protocol DetailViewControllerDelegate {
    func addressDirectionButtonPressed()
}


class DetailViewController: UIViewController {
    
    @IBOutlet weak var addressButton : PopButton!
    @IBOutlet weak var tipLabel : UILabel!
    @IBOutlet weak var hoursLabel : UILabel!
    @IBOutlet weak var photoIView : UIImageView!
    @IBOutlet weak var tableview: UITableView!
    
    var delegate: DetailViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func addressButtonPressed(sender: AnyObject) {
        delegate?.addressDirectionButtonPressed()
    }
    

}

extension DetailViewController: UITableViewDataSource{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("detail", forIndexPath: indexPath) as! UITableViewCell
        
        
        return cell
    }
}

extension DetailViewController: UITableViewDelegate{
    
}
