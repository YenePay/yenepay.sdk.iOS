//
//  CartContentsTableViewController.swift
//  YenePaySDKSampleApp
//
//  Created by Ahmed Mohammed Abdurahman on 1/21/21.
//

import UIKit

class CartContentsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.register(Value1TableViewCell.self, forCellReuseIdentifier: "Value1TableViewCell")
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return (ShoppingCart.shared.items.count == 0) ? 0 : 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return ShoppingCart.shared.items.count      // items
        case 1: return 1    // total price
        case 2: return 2    // cehckout, clear cart
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CartItemTableViewCell", for: indexPath) as! CartItemTableViewCell
            cell.selectionStyle = .none
            
            let (item, count) = ShoppingCart.shared.items[indexPath.row]
            cell.itemImageView?.image = UIImage(named: item.imageName)
            cell.nameLabel?.text = item.name
            cell.priceLabel?.text = item.price.formattedAmount + " Br"
            cell.quantityLabel?.text = "x \(count)"
            
            cell.quantityStepper?.minimumValue = 0.0
            cell.quantityStepper?.value = Double(count)
            cell.quantityStepper?.maximumValue = 1000.0
            cell.quantityChangeHandler = { [weak self] (cell) in
                guard let self = self else { return }
                guard let indexPath = self.tableView.indexPath(for: cell) else { return }
                let count = ShoppingCart.shared.items[indexPath.row].count
                if Int(cell.quantityStepper!.value) > count {
                    ShoppingCart.shared.add(item: item)
                } else if Int(cell.quantityStepper!.value) < count {
                    ShoppingCart.shared.remove(item: item, keepRowIfZero: true)
                }
                self.tableView.reloadRows(at: [indexPath, IndexPath(row: 0, section: 1)], with: .automatic)
            }
            
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Value1TableViewCell", for: indexPath)
            cell.selectionStyle = .none
            cell.textLabel?.textAlignment = .natural
            cell.textLabel?.text = "Cart Total"
            cell.detailTextLabel?.text = ShoppingCart.shared.totalPrice.formattedAmount + " Br"
            cell.textLabel?.textColor = UIColor.label
            return cell
        } // else...
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.selectionStyle = .default
        switch indexPath.row {
        case 0:
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.text = "CHECKOUT"
            cell.textLabel?.textColor = UIColor.label
        case 1:
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.text = "CLEAR CART"
            cell.textLabel?.textColor = UIColor.systemRed
        default:
            break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return indexPath.section == 0 ? .delete : .none
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && (indexPath.section == 0) {
            ShoppingCart.shared.removeAllItems(withId: ShoppingCart.shared.items[indexPath.row].item.id)
            if ShoppingCart.shared.items.count > 0 {
                tableView.performBatchUpdates({
                    tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }, completion: nil)
            } else {
                tableView.reloadData()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 2 {
            if indexPath.row == 0 {
                AppDelegate.checkout(presentingViewController: self) { [weak self] (paymentCompleted) in
                    if paymentCompleted {
                        self?.emptyCartAndDismiss()                        
                    }
                }
            } else {
                emptyCartAndDismiss()
            }
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


class CartItemTableViewCell: UITableViewCell {
    @IBOutlet weak var itemImageView: UIImageView?
    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var priceLabel: UILabel?
    @IBOutlet weak var quantityLabel: UILabel?
    @IBOutlet weak var quantityStepper: UIStepper?
    
    var quantityChangeHandler: ((CartItemTableViewCell)->Void)?
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let imageView = self.itemImageView {
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 0.5 * min(imageView.frame.size.width, imageView.frame.size.height)
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = UIColor.black.withAlphaComponent(0.2).cgColor
        }
    }
    
    @IBAction func quantityStepperValueDidChange() {
        if let quantityChangeHandler = quantityChangeHandler {
            quantityChangeHandler(self)
        }
    }
}

class Value1TableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
