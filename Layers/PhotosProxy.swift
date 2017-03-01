//
//  PhotosProxy.swift
//  Layers
//
//  Created by Tal Cohen on 21/02/2017.
//  Copyright © 2017 Tal Cohen. All rights reserved.
//

import Photos

class PhotosProxy {

    static let thumbnailItemSize = CGSize(width: 100, height: 100)
    static let shared = PhotosProxy()

    static let loadingPhotosCompleteEvent = NSNotification.Name("loadingPhotosComplete")
    
    var photos = [String]()
    var photosBucket = [String:Photo]()
    
    func loadPhotos() {
        PHPhotoLibrary.requestAuthorization { (auth) in
            switch auth {
            case .authorized:
                self.fetchPhotos(targetSize: PhotosProxy.thumbnailItemSize, completionBlock: { photos in
                    self.photos = photos
                    NotificationCenter.default.post(name: PhotosProxy.loadingPhotosCompleteEvent, object: nil)
                })
            default:
                break;
            }
        }
    }
    
    func getThumbnail(id : String, completionBlock: ((UIImage?)->())?) {
        self.photosBucket[id]!.getThumbnail(completionBlock: completionBlock)
    }
    
    func getImage(id : String, completionBlock: ((UIImage?)->())?) {
        self.photosBucket[id]!.getImage(completionBlock: completionBlock)
    }
    
    func getPhoto(id : String) -> Photo {
        return self.photosBucket[id]!
    }
    
    fileprivate func fetchPhotos(amount : Int? = nil, targetSize size: CGSize, completionBlock: ((_ photos: [String])->())?){
        var photos = [String]()
        
        let group = DispatchGroup()
        let options = PHFetchOptions()
        if let amount = amount {
            options.fetchLimit = amount
        }
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        options.sortDescriptors = [sortDescriptor]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        fetchResult.enumerateObjects({ (asset, id, bool) in
            if self.photosBucket[asset.localIdentifier] == nil {
                self.photosBucket[asset.localIdentifier] = Photo(asset: asset)
            }
            photos.append(asset.localIdentifier)
        })
        
        for i in 0..<photos.count {
            group.enter()
            self.photosBucket[photos[i]]!.getThumbnail(completionBlock: { (thumbnail) in
                group.leave()
            })
            
        }
        group.notify(queue: DispatchQueue.main, work: DispatchWorkItem(block: { 
            completionBlock?(photos)
        }))
    }
}
