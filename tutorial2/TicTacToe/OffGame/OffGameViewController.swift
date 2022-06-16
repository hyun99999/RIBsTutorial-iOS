//
//  OffGameViewController.swift
//  TicTacToe
//
//  Created by kimhyungyu on 2022/06/14.
//  Copyright © 2022 Uber. All rights reserved.
//

import RIBs
//import RxCocoa
import RxSwift
import SnapKit
import UIKit

protocol OffGamePresentableListener: class {
    // business logic, such as signIn(). This protocol is implemented by the corresponding
    // interactor class.
    func startGame()
}

final class OffGameViewController: UIViewController, OffGamePresentable, OffGameViewControllable {
    var uiviewController: UIViewController {
        return self
    }

    weak var listener: OffGamePresentableListener?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Method is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yellow
        buildStartButton()
    }

    // MARK: - Private

    private func buildStartButton() {
        let startButton = UIButton()
        view.addSubview(startButton)
        startButton.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.center.equalTo(self.view.snp.center)
            maker.leading.trailing.equalTo(self.view).inset(40)
            maker.height.equalTo(100)
        }
        startButton.setTitle("Start Game", for: .normal)
        startButton.setTitleColor(UIColor.white, for: .normal)
        startButton.backgroundColor = UIColor.black
        startButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.listener?.startGame()
            })
            .disposed(by: disposeBag)
    }

    private let disposeBag = DisposeBag()
}
