import UIKit
import Swollama
final class ModelListViewController: UIViewController {

    private let viewModel = ModelListViewModel()
    private var dataSource: UITableViewDiffableDataSource<Section, String>!
    private var modelsMap: [String: ModelListEntry] = [:]

    private enum Section {
        case main
    }

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.setupForAutoLayout()
        table.delegate = self
        table.register(ModelCell.self, forCellReuseIdentifier: ModelCell.reuseIdentifier)
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 80
        return table
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return refresh
    }()

    private let loadingView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.setupForAutoLayout()
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.setupForAutoLayout()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()

    private lazy var chatButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Start Chat"
        config.image = UIImage(systemName: "message.fill")
        config.imagePadding = 8
        config.cornerStyle = .large
        config.baseBackgroundColor = .systemBlue

        let button = UIButton(configuration: config)
        button.setupForAutoLayout()
        button.addTarget(self, action: #selector(chatButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDiffableDataSource()
        observeViewModel()
        loadModels()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if modelsMap.isEmpty {
            loadModels()
        }
    }

    private func setupUI() {
        title = "Models"
        view.backgroundColor = .systemBackground

        navigationController?.navigationBar.prefersLargeTitles = true

        view.addSubviews(tableView, loadingView, errorLabel, chatButton)

        tableView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: chatButton.topAnchor, constant: -16),

            chatButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            chatButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            chatButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            chatButton.heightAnchor.constraint(equalToConstant: 50),

            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    private func configureDiffableDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, String>(
            tableView: tableView
        ) { [weak self] tableView, indexPath, digest in
            guard let self = self,
                  let model = self.modelsMap[digest] else {
                return UITableViewCell()
            }

            let cell = tableView.dequeueReusableCell(
                withIdentifier: ModelCell.reuseIdentifier,
                for: indexPath
            ) as! ModelCell

            let isSelected = self.viewModel.selectedModel?.fullName == model.name
            cell.configure(with: model, isSelected: isSelected)

            return cell
        }
    }

    private func observeViewModel() {
        Task { @MainActor in
            for await state in viewModel.$state.values {
                handleStateChange(state)
            }
        }

        Task { @MainActor in
            for await selectedModel in viewModel.$selectedModel.values {
                chatButton.isEnabled = selectedModel != nil
                reconfigureAllCells()
            }
        }
    }

    private func loadModels() {
        Task {
            await viewModel.loadModels()
        }
    }

    @objc private func handleRefresh() {
        Task {
            await viewModel.loadModels()
            refreshControl.endRefreshing()
        }
    }

    @MainActor
    private func handleStateChange(_ state: ModelListViewModel.State) {
        switch state {
        case .idle:
            loadingView.stopAnimating()
            errorLabel.isHidden = true
            tableView.isHidden = false

        case .loading:
            if modelsMap.isEmpty {
                loadingView.startAnimating()
                tableView.isHidden = true
            }
            errorLabel.isHidden = true

        case .loaded(let models):
            loadingView.stopAnimating()
            errorLabel.isHidden = true
            tableView.isHidden = false
            updateSnapshot(with: models)

        case .error(let message):
            loadingView.stopAnimating()
            errorLabel.text = "⚠️ \(message)\n\nPull down to retry"
            errorLabel.isHidden = false
            tableView.isHidden = modelsMap.isEmpty
        }
    }

    private func updateSnapshot(with models: [ModelListEntry]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.main])

        modelsMap = Dictionary(uniqueKeysWithValues: models.map { ($0.digest, $0) })
        snapshot.appendItems(models.map(\.digest), toSection: .main)

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func reconfigureAllCells() {
        var snapshot = dataSource.snapshot()
        let allItems = snapshot.itemIdentifiers
        guard !allItems.isEmpty else { return }

        snapshot.reconfigureItems(allItems)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    @objc private func chatButtonTapped() {
        guard viewModel.selectedModel != nil else { return }

        let chatVC = ChatViewController()
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

extension ModelListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let digest = dataSource.itemIdentifier(for: indexPath),
              let model = modelsMap[digest] else { return }

        viewModel.selectModel(model)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
