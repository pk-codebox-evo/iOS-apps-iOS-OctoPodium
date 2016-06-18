//
//  TrendingController.swift
//  OctoPodium
//
//  Created by Nuno Gonçalves on 29/01/16.
//  Copyright © 2016 Nuno Gonçalves. All rights reserved.
//

import UIKit
import ARSPopover

class TrendingController : UIViewController {

    @IBOutlet weak var repositoriesTable: UITableView!
    @IBOutlet weak var loadingView: GithubLoadingView!
    
    private var trendingScopes = TrendingScope.enumerateElements
    private var selectedTrendingScope = TrendingScope.Day
    
    private var languagesPopoverController: LanguagesPopoverController!
    private var popoverController: ARSPopover?
    
    private var languageButton: UIButton!
    private let languageImageView = LanguageImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    
    private var repositories: [Repository] = []
    private var selectedRepository: Repository?
    
    private var trendingDataSource: TrendingDataSource!
    
    private var language = ""
    private var isSearching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Analytics.SendToGoogle.enteredScreen(String(TrendingController))
        
        setUpUIComponents()
        
        searchTrendingRepos()
    }
    
    private func setUpUIComponents() {
        buildSegmentedControl()
        setupRepositoriesTable()
        
        buildLanguageButton()
        
        updateLanguageIcon()
        buildPopoverElements()
    }
    
    private func buildSegmentedControl() {
        let segmentedControl = UISegmentedControl(items: trendingScopes.map { $0.rawValue })
        segmentedControl.selectedSegmentIndex = 0
        
        segmentedControl.addTarget(self, action: #selector(updateTrendingScope(_:)), for: .valueChanged)
        self.navigationItem.titleView = segmentedControl
    }
    
    @objc private func updateTrendingScope(_ control: UISegmentedControl) {
        selectedTrendingScope = trendingScopes[control.selectedSegmentIndex]
        trendingDataSource.trendingScope = selectedTrendingScope
        searchTrendingRepos()
    }
    
    private func setupRepositoriesTable() {
        setupDataSource()

        repositoriesTable.registerReusableCell(TrendingRepositoryCell)
        repositoriesTable.estimatedRowHeight = 95.0
        repositoriesTable.rowHeight = UITableViewAutomaticDimension
    }
    
    private func setupDataSource() {
        trendingDataSource = TrendingDataSource(tableView: repositoriesTable)
        trendingDataSource.userClicked = userClicked
        trendingDataSource.repositoryCellClicked = repositoryCellClicked
        trendingDataSource.gotRepositories = updateAfterResponse
    }
    
    private func buildLanguageButton() {
        languageButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        languageButton.addTarget(self, action: #selector(clickedLanguage), for: .touchUpInside)
    }
    
    @objc private func clickedLanguage() {
        if !isSearching {
            showPopover()
        }
    }
    
    private func updateLanguageIcon() {
        languageImageView.language = language
        let image = LanguageImage.loadForOr(language, orLanguageImageView: languageImageView).withRenderingMode(.alwaysOriginal)
        languageButton.setBackgroundImage(image, for: UIControlState())
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: languageButton)
    }
    
    private func buildPopoverElements() {
        let sb = UIStoryboard.main()
        languagesPopoverController = sb.languagesPopoverController()
        languagesPopoverController.modalPresentationStyle = .popover
        languagesPopoverController.languageSelectorDelegate = self
    }
    
    
    private func showPopover() {
        popoverController = ARSPopover()
        popoverController!.sourceView = languageButton
        popoverController!.sourceRect = CGRect(x: (languageButton.bounds).midX, y: (languageButton.bounds).maxY, width: 0, height: 0)
        popoverController!.contentSize = CGSize(width: view.width - 50, height: 300)
        popoverController!.arrowDirection = .Up;
        
        presentViewController(popoverController!, animated: true) { [weak self] in
            self?.popoverController!.insertContentIntoPopover({ [weak self] (popover, _, _) in
                guard let s = self else { return }
                popover.view.addSubview(s.languagesPopoverController.view)
            })
        }
    }
    
    private func searchTrendingRepos() {
        repositoriesTable.hide()
        loadingView.show()
        loadingView.setLoading()
        
        trendingDataSource.language = language
        isSearching = true
        trendingDataSource.search()
    }
    
    private func updateAfterResponse() {
        loadingView.hide()
        repositoriesTable.show()
        isSearching = false
        languageButton.isEnabled = true
    }
    
    private func userClicked(_ user: String) {
        performSegue(withIdentifier: kSegues.trendingToUserDetailsSegue, sender: user)
    }
    
    private func repositoryCellClicked(_ repository: Repository) {
        selectedRepository = repository
        performSegue(withIdentifier: kSegues.showTrendingRepositoryDetailsSegue, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kSegues.trendingToUserDetailsSegue {
            let vc = segue.destinationViewController as! UserDetailsController
            let user = User(login: sender as! String, avatarUrl: "")
            vc.userPresenter = UserPresenter(user: user)
        }
        
        if segue.identifier == kSegues.showTrendingRepositoryDetailsSegue {
            let vc = segue.destinationViewController as! TrendingRepositoryDetailsController
            vc.repository = selectedRepository
        }
    }
}

extension TrendingController : LanguageSelectedProtocol {
    func didSelectLanguage(_ language: Language) {
        popoverController?.dismissViewControllerAnimated(true, completion: nil)
        
        if self.language == language { return }
        
        self.language = language == "All Languages" ? "" : language.replace(" ", with: "-")
        
        updateLanguageIcon()
        searchTrendingRepos()
    }
    
    func noLanguagesAvailable() {
        popoverController?.dismissViewControllerAnimated(true, completion: nil)
        NotifyError.display("No Languages to select. Check your internet connection")
    }
}

private extension UIStoryboard {
    
    static func main() -> UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
    }
    
    func languagesPopoverController() -> LanguagesPopoverController {
        return instantiateViewController(withIdentifier: String(LanguagesPopoverController)) as! LanguagesPopoverController
    }
}
