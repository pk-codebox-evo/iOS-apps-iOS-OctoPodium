//
//  StarChecker.swift
//  OctoPodium
//
//  Created by Nuno Gonçalves on 29/03/16.
//  Copyright © 2016 Nuno Gonçalves. All rights reserved.
//

extension GitHub {
    
    struct StarChecker : Getter {
        
        let repoOwner: String
        let repoName: String
        
        init(repoOwner: String, repoName: String) {
            self.repoOwner = repoOwner
            self.repoName = repoName
        }
        
        var httpMethod = HTTPMethod.GET
        
        var headers: HeadParams? = [
            "Authorization" : "token \(GithubToken.instance.token ?? "")"
        ]
        
        var bodyParams: BodyParams? = nil
        
        func getUrl() -> String {
            return kUrls.githubStarredRepoUrl(repoOwner, repoName)
        }
        
        func getDataFrom(dictionary: NSDictionary) -> Bool {
            return true
        }
        
        func checkIfIsStar(success success: Bool -> (), failure: ApiResponse -> ()) {
            call(
                success: { starred -> () in
                    success(starred)
                }, failure: { apiResponse in
                    if apiResponse.status == .NotFound {
                        success(false)
                    } else {
                        failure(apiResponse)
                    }
                }
            )
        }

    }
    
}
