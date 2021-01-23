//
//  ItemDetailTableViewController.swift
//  YenePaySDKSampleApp
//
//  Created by Ahmed Mohammed Abdurahman on 1/23/21.
//

import UIKit

class ItemDetailTableViewController: UITableViewController {

    var item: StoreItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "SubtitleTableViewCell")
        self.tableView.register(Value1TableViewCell.self, forCellReuseIdentifier: "Value1TableViewCell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 2
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SubtitleTableViewCell", for: indexPath)
                cell.imageView?.image = UIImage(named: item.imageName)
                cell.textLabel?.text = item.name
                cell.detailTextLabel?.text = item.description
                cell.selectionStyle = .none
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Value1TableViewCell", for: indexPath)
                cell.textLabel?.text = "Price"
                cell.detailTextLabel?.text = item.price.formattedAmount + " Br"
                cell.selectionStyle = .none
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.selectionStyle = .default
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = .label
            if indexPath.row == 0 {
                if ShoppingCart.shared.countOf(item: item) == 0 {
                    cell.textLabel?.text = "ADD TO CART"
                } else {
                    cell.textLabel?.text = "REMOVE FROM CART"
                    cell.textLabel?.textColor = .systemRed
                }
            } else {
                cell.textLabel?.text = "CHECKOUT"
            }
            return cell
        }                
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                if ShoppingCart.shared.countOf(item: item) == 0 {
                    ShoppingCart.shared.add(item: item)
                } else {
                    ShoppingCart.shared.removeAllItems(withId: item.id)
                }
            } else {
                if ShoppingCart.shared.countOf(item: item) == 0 {
                    ShoppingCart.shared.add(item: item)
                }
                
                AppDelegate.checkout(presentingViewController: self) { [weak self] (paymentCompleted) in
                    if paymentCompleted {
                        self?.emptyCartAndDismiss()
                    }
                }
            }
            
            tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
        }
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    private func emptyCartAndDismiss() {
        ShoppingCart.shared.removeAllItems()
        self.tableView.reloadData()
        self.performSegue(withIdentifier: "dismiss", sender: nil)
    }
}


class SubtitleTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
