//
//  TableView.swift
//  GithubIssues
//
//  Created by Chris Eidhof on 28/02/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import UIKit

func tableViewController<A>(configuration: TableViewConfiguration<A>) -> Screen<[A],A> {
    return asyncTableViewController({ $1($0) }, configuration)
}

func standardCell<A>(f: A -> String) -> TableViewConfiguration<A> {
    var config: TableViewConfiguration<A> = TableViewConfiguration()
    config.render = { cell, a in
        cell.textLabel?.text = f(a)
    }
    return config
}

private func twoTextCell<A>(style: UITableViewCellStyle)(_ f: A -> (title: String, subtitle: String)) -> TableViewConfiguration<A> {
    return TableViewConfiguration(render: { (cell: UITableViewCell, a: A) in
        let (title, subtitle) = f(a)
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = subtitle
        }, style: style)
}

func value1Cell<A>(f: A -> (title: String, subtitle: String)) -> TableViewConfiguration<A> {
    return twoTextCell(.Value1)(f)
}

func subtitleCell<A>(f: A -> (title: String, subtitle: String)) -> TableViewConfiguration<A> {
    return twoTextCell(.Subtitle)(f)
}

func value2Cell<A>(f: A -> (title: String, subtitle: String)) -> TableViewConfiguration<A> {
    return twoTextCell(.Value2)(f)
}


func simpleTableViewController<A>(render: A -> String) -> Screen<[A], A> {
    return tableViewController(standardCell(render))
}

struct TableViewConfiguration<A> {
    var render: (UITableViewCell, A) -> () = { _ in }
    var style: UITableViewCellStyle = UITableViewCellStyle.Default
}


func asyncTableViewController<A,I>(loadData: (I, [A] -> ()) -> (), configuration: TableViewConfiguration<A>) -> Screen<I, A> {
    return Screen({ (input: I, callback: A -> ()) -> UIViewController  in
        var myTableViewController = MyViewController(style: UITableViewStyle.Plain)
        loadData(input, { (items: [A]) in
            myTableViewController.items = items.map { Box($0) }
            return ()
        })
        myTableViewController.cellStyle = configuration.style
        myTableViewController.items = nil // items.map { Box($0) }
        myTableViewController.configureCell = { cell, obj in
            if let boxed = obj as? Box<A> {
                configuration.render(cell, boxed.unbox)
            }
            return cell
        }
        myTableViewController.callback = { x in
            if let boxed = x as? Box<A> {
                callback(boxed.unbox)
            }
        }
        return myTableViewController
    })
}

class MyViewController: UITableViewController {
    var cellStyle: UITableViewCellStyle = .Default
    var items: NSArray? = [] {
        didSet {
            self.navigationItem.title = items == nil ? "Loading..." : ""
            self.tableView.reloadData()
        }
    }
    var callback: AnyObject -> () = { _ in () }
    var configureCell: (UITableViewCell, AnyObject) -> UITableViewCell = { $0.0 }
    
    override func viewDidLoad() {
        println("load")
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell : UITableViewCell = UITableViewCell(style: cellStyle, reuseIdentifier: nil) // todo dequeue
        var obj: AnyObject = items![indexPath.row]
        return configureCell(cell, obj)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var obj: AnyObject = items![indexPath.row]
        callback(obj)
    }
}
