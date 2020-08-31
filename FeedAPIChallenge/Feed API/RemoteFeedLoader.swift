//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient
	
	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
		
	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
	
	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                do {
                    if response.statusCode != 200 {
                        completion(.failure(Error.invalidData))
                    } else {
                        let images = try FeedRemoteImageMapper.map(data)
                        completion(.success(images))
                    }
                } catch {
                    completion(.failure(Error.invalidData))
                }
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}

private class FeedRemoteImageMapper {
    private struct RootItem: Decodable {
        let items: [Image]
    }
    
    private struct Image: Decodable {
        let image_id: UUID
        let image_desc: String?
        let image_loc: String?
        let image_url: URL
        
        var image: FeedImage {
            return FeedImage(id: image_id,
                             description: image_desc,
                             location: image_loc,
                             url: image_url)
        }
    }
    
    static func map(_ data: Data) throws -> [FeedImage] {
        return try JSONDecoder().decode(RootItem.self, from: data)
            .items
            .map{ $0.image }
    }
}
