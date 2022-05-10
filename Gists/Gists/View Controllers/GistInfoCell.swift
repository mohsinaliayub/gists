//
//  GistInfoCell.swift
//  Gists
//
//  Created by Mohsin Ali Ayub on 09.05.22.
//

import UIKit
import PINRemoteImage

class GistInfoCell: UITableViewCell {

    private let placeholderImage = UIImage(named: "placeholder")
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func show(with gist: Gist) {
        textLabel?.text = gist.description
        detailTextLabel?.text = gist.owner?.login
        
        if let avatarURL = gist.owner?.avatarURL {
            imageView?.pin_setImage(from: avatarURL, placeholderImage: placeholderImage) { _ in
                self.setNeedsLayout()
            }
        } else {
            imageView?.image = placeholderImage
        }
    }

}
