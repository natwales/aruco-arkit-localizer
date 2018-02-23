//
//  ObjectStoreService.swift
//  ARUcoTest
//
//  Created by Nat Wales on 2/22/18.
//  Copyright © 2018 HHCC. All rights reserved.
//

import Foundation

struct ObjectStoreService {
    
    private static let keyname = "scene_objects";
    
    static func saveSceneObjects(objects:[CodableSceneObject]) -> Bool {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(objects) {
            UserDefaults.standard.set(encoded, forKey: ObjectStoreService.keyname)
            print("seemed to work")
            return true
        } else {
            print("nope, that didn't work.")
            return false
        }
    }
    
    static func loadSceneObjects() -> [CodableSceneObject]? {
        let decoder = JSONDecoder()
        guard let arrayData = UserDefaults.standard.data(forKey: ObjectStoreService.keyname), let loadedArray = try? decoder.decode([CodableSceneObject].self, from: arrayData) else {
            print("No luck decoding")
            return nil
        }

        if loadedArray.count > 0 {
            return loadedArray
        }
        return nil
    }
    
}
