//
//  ItemListTableViewController.swift
//  YenePaySDKSampleApp
//
//  Created by Ahmed Mohammed Abdurahman on 1/21/21.
//

import UIKit
import QuartzCore

class ItemListTableViewController: UITableViewController {
    private let items = [
        StoreItem(id: "1", imageName: "Item1", name: "Fikir Esike Mekabir",
                  description: "Book - Fikir esike mekabir by Haddis Alemayehu", price: 250),
        
        StoreItem(id: "2", imageName: "Item2", name: "Women's Shoes",
                  description: "Quality women's shoes - black, size 36", price: 400),
        
        StoreItem(id: "3", imageName: "Item3", name: "Nike Sneakers",
                  description: "Nike sneakers - white, size 42", price: 1500),
        
        StoreItem(id: "4", imageName: "Item4", name: "Port Wrist Watch",
                  description: "Original Port wrist watch - black", price: 700),
        
        StoreItem(id: "5", imageName: "Item5", name: "Electric Stove",
                  description: "Electric cooking stove 220 watt", price: 190.5),
        
        StoreItem(id: "6", imageName: "Item6", name: "Women's Hand Bag",
                  description: "Leather women's hand bag - grey", price: 250),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 84.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        ShoppingCart.shared.removeAllZeroQuantityItems()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell", for: indexPath) as! ItemTableViewCell
        cell.itemImageView?.image = UIImage(named: item.imageName)
        cell.nameLabel?.text = item.name
        cell.descriptionLabel?.text = item.description
        cell.priceLabel?.text = item.price.formattedAmount + " Br"
        return cell
    }


    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueId = segue.identifier else { return }
                
        if segueId == "showItem" {
            guard let selectedIndexPath = tableView.indexPathForSelectedRow else { return }
            let destination = segue.destination as! ItemDetailTableViewController
            destination.item = items[selectedIndexPath.row]
        }
    }

    @IBAction private func unwindAction(unwindSegue: UIStoryboardSegue) {
        
    }
}


class ItemTableViewCell: UITableViewCell {
    @IBOutlet weak var itemImageView: UIImageView?
    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var priceLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let imageView = self.itemImageView {
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 0.5 * min(imageView.frame.size.width, imageView.frame.size.height)
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = UIColor.black.withAlphaComponent(0.2).cgColor
        }
    }
}
