//
//  VenueViewController.swift
//  Ramen Compass
//
//  Created by Ian Parker on 2/27/15.
//  Copyright (c) 2015 Tumbleweed. All rights reserved.
//

import UIKit

class VenueViewController: UIViewController {
    
    var fsqpage = ""
    @IBOutlet weak var webView : UIWebView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    override func viewWillAppear(animated: Bool) {
        let requesturl = NSURL(string: "https://foursquare.com/v/foursquare-hq/\(fsqpage)")
        println(requesturl)
        let request = NSURLRequest(URL: requesturl!)
        webView?.loadRequest(request)
        

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
