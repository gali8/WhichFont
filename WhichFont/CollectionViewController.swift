//
//  CollectionViewController.swift
//  WhichFont
//
//  Created by Daniele on 25/07/17.
//  Copyright © 2017 nexor. All rights reserved.
//

import UIKit

class FontCell: UICollectionViewCell {
    @IBOutlet weak var lblFont: UILabel!
}

extension ViewController {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fontFamilies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FontCell", for: indexPath) as! FontCell
        cell.backgroundColor = self.currentIndexPath != indexPath ? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0) : #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)
        
        let item = self.fontFamilies[indexPath.row]
        cell.lblFont.adjustsFontSizeToFitWidth = true
        cell.lblFont.text = item
        
        let font = UIFont(name: item, size: 15) //autoadjust size
        cell.lblFont.font = font
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.fontFamilies[indexPath.row]
        let font = UIFont(name: item, size: 24) //autoadjust size
        self.currentFont = font
        self.currentIndexPath = indexPath
        self.cvFontFamilies.reloadData()
    }
}
