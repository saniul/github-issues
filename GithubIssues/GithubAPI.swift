//
//  GithubAPI.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 28/02/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation

struct User {
    let login: String
    let avatarURL: NSURL?
}

struct Repository {
    let name: String
    let owner: User
    let description_: String
    let url: NSURL
}

struct Organization {
    let login: String
    let reposURL: NSURL
}

enum IssueState: String {
    case Open = "open"
    case Closed = "closed"
}

struct Issue {
    let state: IssueState
    let title: String
    let body: String?
    let assignee: User?
    let creator: User
    let milestone: Milestone?
}

struct Milestone {
    let title: String
    
    static func parse(input: AnyObject) -> Milestone? {
        if let dict = input as? JSONDictionary,
            title = input["title"] as? String
        {
            return Milestone(title: title)
        }
        return nil
    }
}


extension Repository {
    static func parse(input: AnyObject) -> Repository? {
        if let dict = input as? JSONDictionary,
            name = dict["name"] as? String,
            owner = User.parse(dict["owner"]),
            description = dict["description"] as? String,
            urlString = dict["html_url"] as? String,
            url = NSURL(string: urlString)
        {
            return Repository(name: name, owner: owner, description_: description, url: url)
        }
        return nil
        
    }
    
    var issuesResource: Resource<[Issue]> {
        let path = "/repos/\(owner.login)/\(name)/issues"
        return jsonResource(path, .GET, [:], array(Issue.parse))
    }
}

extension Organization {
    static func parse(input: AnyObject) -> Organization? {
        if let dict = input as? JSONDictionary,
            name = dict["login"] as? String,
            reposURLString = dict["repos_url"] as? String,
            reposURL = NSURL(string: reposURLString)
        {
            return Organization(login: name, reposURL: reposURL)
        }
        return nil
        
    }
    
    var reposResource: Resource<[Repository]> {
        return jsonResource(reposURL.path!, .GET, [:], array(Repository.parse))
    }
}

extension User {
    static func parse(input: AnyObject?) -> User? {
        if let dict = input as? JSONDictionary,
           login = dict["login"] as? String,
           urlString = dict["avatar_url"] as? String
        {
            return User(login: login, avatarURL: NSURL(string: urlString))
        }
        return nil
    }
}

extension Issue {
    static func parse(input: AnyObject?) -> Issue? {
        if let dict = input as? JSONDictionary,
               title = dict["title"] as? String,
               stateString = dict["state"] as? String,
               state = IssueState(rawValue: stateString),
            creator = User.parse(dict["user"])
        {
            let assignee = User.parse(dict["assignee"])
            let body = dict["body"] as? String
            var milestone: Milestone? = nil
            if let milestoneObj: AnyObject = dict["milestone"]
            {
                milestone = Milestone.parse(milestoneObj)
            }
            return Issue(state: state, title: title, body: body, assignee: assignee, creator: creator, milestone: milestone)
        }
        return nil
    }
}

func repositories(user: String?) -> Resource<[Repository]> {
    let path: String
    if let username = user {
        path = "/users/\(username)/repos"
    } else {
        path = "/user/repos"
    }
    return jsonResource(path, .GET, [:], array(Repository.parse))
}


func organizations() -> Resource<[Organization]> {
    return jsonResource("/user/orgs", .GET, [:], array(Organization.parse))
}

func array<A>(element: AnyObject -> A?)(input: AnyObject) -> [A]? {
    if let theArray = input as? [AnyObject] {
        var result: [A] = []
        for el in theArray {
            if let x = element(el) {
                result.append(x)
            } else {
                return nil
            }
        }
        return result
    }
    return nil
}

let baseURL = NSURL(string: "https://api.github.com")!

func addToken(r: NSMutableURLRequest) {
    r.setValue("token \(githubToken)", forHTTPHeaderField: "Authorization")
}

func request<A>(resource: Resource<A>, completion: A? -> ()) -> () {
    apiRequest(addToken, baseURL, resource, { (reason, data) -> () in
        if let theData = data, str = NSString(data: theData, encoding: NSUTF8StringEncoding) {
            println(str)
        }
        println("Reason: \(reason)")
        completion(nil)
        }, { progress in
            ()
        }, { success in completion(success)})
}