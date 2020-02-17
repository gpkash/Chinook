//
//  ViewController.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-01.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import UIKit
import Chinook

class ViewController: UITableViewController {
    
    // MARK: Private Properties
    
    private let queue = OperationQueue()
    private let numberOfRandomSites = 20
    private var randomSiteDatas: [SiteData] = []
    
    private lazy var citySiteDataOperationCompletionHandler: (_ result: Result<Any, Error>) -> Void = { [weak self] result in
        switch result {
        case .success(let siteData):
            guard let self = self else { return }
            
            let siteData = siteData as! SiteData
            let indexPath = IndexPath(row: self.randomSiteDatas.count, section: 0)

            self.tableView.beginUpdates()
            
            // update the datsource.
            self.randomSiteDatas.append(siteData)

            self.tableView.insertRows(at: [indexPath], with: .automatic)
            self.tableView.endUpdates()

        case .failure(let error):
            self?.showAlert(forError: error)
        }
    }

    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        tableView.delegate = self
        tableView.dataSource = self

        let fetchCityPageWeatherSiteListOperation = FetchCityPageWeatherSiteListOperation()
        
        fetchCityPageWeatherSiteListOperation.completionHandler = { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let siteList):
                let siteList = siteList as! SiteList
                print("\(siteList.site.count) sites fetched.")
                
                self.loadRandomSiteData(siteList)
                
            case .failure(let error):
                self.showAlert(forError: error)
            }
        }
        
        queue.maxConcurrentOperationCount = 10
        queue.addOperation(fetchCityPageWeatherSiteListOperation)
    }
    
    
    // MARK: - Private Functions
    
    private func loadRandomSiteData(_ siteList: SiteList) {
        // fetch random sites, for fun!
        let randomSites = siteList.snag(someRandomSites: numberOfRandomSites)
        
        randomSites.forEach { site in
            let fetchCityPageWeatherSiteDataOperation = FetchCityPageWeatherSiteDataOperation(site: site)
            fetchCityPageWeatherSiteDataOperation.completionHandler = citySiteDataOperationCompletionHandler
            queue.addOperation(fetchCityPageWeatherSiteDataOperation)
        }
    }

    
    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return randomSiteDatas.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let siteData = randomSiteDatas[indexPath.row]
        
        if let temperature = siteData.currentConditions?.temperature.value {
            cell.textLabel!.text = "\(temperature)C, \(siteData.fullName)"
        }
        else {
            cell.textLabel!.text = "N/A, \(siteData.fullName)"
        }

        return cell
    }
}
