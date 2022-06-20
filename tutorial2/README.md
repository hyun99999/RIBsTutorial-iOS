[https://github.com/uber/RIBs](https://github.com/uber/RIBs)

### 내용

- RIBs 튜토리얼 2 를 진행하겠습니다!
- 본 **글은 RIBs tutorial 2 를 번역 및 궁금한 내용들을 추가하여 작성하였습니다.**

[iOS Tutorial 2 · uber/RIBs Wiki](https://github.com/uber/RIBs/wiki/iOS-Tutorial-2)

Note: If you haven't completed [tutorial 1](https://github.com/uber/RIBs/wiki/iOS-Tutorial-1) yet, we encourage you to do so before jumping into this tutorial.

## Goals

---

이전 튜토리얼에서 `LoggedOut` RIB 로 구동되는 login form 을 포함하는 앱을 만들었습니다. 이번에는 로그인한 후 게임필드를 표시하도록 앱을 확장할 것입니다. 마지막에는 RIBs 를 unit test 하는 방법을 간력하게 설명하겠습니다.

주요 목표는 다음 개념들을 이해하는 것입니다.

- Having a child RIB communicate with its parent RIB.
(자식 RIB 와 부모 RIB 의 통신)
- Attaching/detaching a child RIB when the parent interactor decides to do so.
(부모 interactor 가 결정할 때 자식 RIB 의 연결/분리)
- Creating a view-less RIB.
(view-less RIB 생성)
    - Cleaning up view modifications when a viewless RIB is detached.
    (viewless RIB 가 분리될 때 view modifications 를 정리합니다.)
- Attaching a child RIB when the parent RIB first loads up.
(부모 RIB 가 처음 로드될 때 자식 RIB 를 연결합니다.)
    - Understanding the lifecycle of a RIB.
    (RIB 의 수명주기 이해)
- Unit testing a RIB.
(RIB 단위 테스트)

## Project structure

---

이전 튜토리얼을 완료한 후, `Root` 와 `LoggedOut` 두가지 RIBs 로 구성된 앱을 만들었습니다. 이번 튜토리얼에서는 `LoggedIn`, `OffGame` 그리고 `TicTacToe` 라는 세가지 RIBs 를 구현할 것 입니다.

<img src="https://user-images.githubusercontent.com/69136340/174247881-513c2592-908a-4487-89e0-4dec7a0f7eaf.png" width ="600">

`LoggedIn` RIB 는 viewless 입니다. 유일한 목적은 `TicTacToe` 와 `OffGame` RIB 사이를 전환하는 것 입니다. 다른 RIBs 는 자체 뷰 컨트롤러가 포함되어있고 화면에 뷰를 표시할 수 있습니다. `OffGame` RIB 는 플레이어가 새 게임을 시작할 수 있도록 하며 “Start Game” 버튼이 있는 인터페이스를 포함합니다. `TicTacToe` RIB 는 게임 필드를 표시하고 플레이어가 이동할 수 있도록 합니다.

## Communicating with a parent RIB

---

사용자가 플레이어 이름을 입력하고 “Login” 버튼을 탭하고, “Start game” 뷰로 이동해야 합니다. 이를 지원하기 위해서 active `LoggedOut` RIB 는 `Root` RIB 에 로그인 액션을 알려야 합니다.  그 후, root router 는 `LoggedOut` RIB 에서 `LoggedIn` RIB 로 제어를 넘겨줍니다. viewless `LoggedIn` RIB 는 `OffGame` RIB 를 로드하고 화면에 뷰 컨트롤러를 표시합니다.

`Root` RIB 는 `LoggedOut` RIB 의 부모이므로 해당 라우터는 `LoggedOut` interactor 의 listener 로 구성됩니다. 이 listener interface 로 `LoggedOut` RIB 에서 `Root` RIB 로 로그인 이벤트를 전달해야 합니다.

먼저, `LoggedOutListener` 를 업데이트해서 플레이어들이 로그인했음을 `LoggedOut` RIB 가 `Root` RIB 에 알릴 수 있도록 하는 메서드를 추가합니다.

```swift
protocol LoggedOutListener: class {
    func didLogin(withPlayer1Name player1Name: String, player2Name: String)
}
```

이것은 `LoggedOut` RIB 의 모든 부모 RIB 가 `didLogin` 함수를 구현하도록 하고 컴파일러가 부모와 자식 간의 계약을 수행합니다.

새로 선언된 리스너 호출을 추가하려면 LoggedOutInteractor 내부의 login 함수 구현을 변경하세요.

```swift
func login(withPlayer1Name player1Name: String?, player2Name: String?) {
    let player1NameWithDefault = playerName(player1Name, withDefaultName: "Player 1")
    let player2NameWithDefault = playerName(player2Name, withDefaultName: "Player 2")
    listener?.didLogin(withPlayer1Name: player1NameWithDefault, player2Name: player2NameWithDefault)
}
```

이러한 변화로 사용자가 RIB 의 뷰 컨트롤러에서 “Login” 버튼을 탭한 후 `LoggedOut` RIB 의 리스너에 알려집니다.

## Routing to `LoggedIn` RIB

---

위의 다이어그램에서 볼 수 있듯이, 사용자가 로그인한 후, `Root` RIB 는 `LoggedOut` RIB 에서 `LoggedIn` RIB 로 전환되어야 합니다. 이를 지원하기 위해서 routing 코드를 작성해 보겠습니다.

`RootRouting` 프로토콜을 업데이트하여 `LoggedIn` RIB 로 라우팅하는 방법을 추가하겠습니다.

```swift
protocol RootRouting: ViewableRouting {
    func routeToLoggedIn(withPlayer1Name player1Name: String, player2Name: String)
}
```

이것은 RootInteractor 와 라우터인 RootRouter 사이의 계약을 설정합니다.

`RootInteractor` 에서 `RootRouting` 을 호출하여 `LoggedOutListener` 프로토콜을 구현하여 `LoggedIn` RIB 로 라우팅합니다. LoggedOut RIB 의 부모이기 때문에 Root RIB 는 리스너 인터페이스를 구현해야 합니다.

```swift
// MARK: - LoggedOutListener

func didLogin(withPlayer1Name player1Name: String, player2Name: String) {
    router?.routeToLoggedIn(withPlayer1Name: player1Name, player2Name: player2Name)
}
```

이렇게 하면 사용자가 로그인할 때마다 `Root` RIB 가 `LoggedIn` RIB 로 라우팅 됩니다. 하지만, 아직 `LoggedIn` RIB 가 구현되지 않았으며 `Root` RIB 에서 전환할 수 없습니다. 누락된 RIB 를 구현해 보겠습니다.

`LoggedIn` 그룹에서 `DELETE\_ME.swift` 파일을 삭제합니다.(이것은 구현하려는 클래스를 stub 하는 데만 필요했습니다.)

그런 다음, Xcode 템플릿을 사용하여 viewless RIB 로 `LoggedIn` RIB 를 만듭니다. “Owns Corresponding view” 를 체크해제하고 `LoggedIn` 그룹에 만듭니다. TicTacToe target 에 만든 파일이 추가되었는지 확인하세요.

<img width="500" alt="2" src="https://user-images.githubusercontent.com/69136340/174248000-79910a77-5501-42ab-a5ad-52db398219df.png">

## 사용자가 로그인 시 viewless `LoggedIn` RIB attach(연결) 및 `LoggedOut` RIB detach(분리)

---

새로 만든 RIB 를 연결하려면, root router 가 build 할 수 있어야 합니다. LoggedInBuildable 프로토콜을 constructor injection(생성자 주입)을 통해 RootRouter 에 전달하여 가능하게 할 것입니다. RootRouter 의 생성자를 다음과 같이 수정합니다.

```swift
init(interactor: RootInteractable,
     viewController: RootViewControllable,
     loggedOutBuilder: LoggedOutBuildable,
     loggedInBuilder: LoggedInBuildable) {
    self.loggedOutBuilder = loggedOutBuilder
    self.loggedInBuilder = loggedInBuilder
    super.init(interactor: interactor, viewController: viewController)
    interactor.router = self
}
```

또한, `RootRouter` 에 대한 `private loggedInBuilder` 상수를 추가해야 합니다.

```swift
// MARK: - Private

    private let loggedInBuilder: LoggedInBuildable

    ...
```

그런 다음, `RootBuilder` 를 업데이트하여 `LoggedInBuilder` concrete class(추상 클래스가 아닌 구현 클래스 모두를 칭할 수 있음.) 를 인스턴스화하고, RootRouter 에 inject 합니다. 다음과 같이 RootBuilder 의 build 함수를 수정합니다.

```swift
func build() -> LaunchRouting {
    let viewController = RootViewController()
    let component = RootComponent(dependency: dependency,
                                  rootViewController: viewController)
    let interactor = RootInteractor(presenter: viewController)

    let loggedOutBuilder = LoggedOutBuilder(dependency: component)
    let loggedInBuilder = LoggedInBuilder(dependency: component)
    return RootRouter(interactor: interactor,
                      viewController: viewController,
                      loggedOutBuilder: loggedOutBuilder,
                      loggedInBuilder: loggedInBuilder)
}
```

방금 수정한 코드를 보면 생성자 주입을 사용하여 `loggedInBuilder` 에 대한 dependency 로 `RootComponent` 를 전달합니다. 이 작업은 [tutorial 3](https://github.com/uber/RIBs/wiki/iOS-Tutorial-3) 에서 다룰 것입니다.

`RootRouter` 는 구체적인 `LoggedInBuilder` 클래스 대신 `LoggedBuildable` 프로토콜에 의존합니다. 이를 통해 `RootRouter` 를 단위 테스트할 때 `LoggedInBuildeable` 에 대한 test mock 을 전달 할 수 있습니다. 이것은 swizzling 기반의 mocking 이 불가능한 Swift 의 제약 조건입니다. 동시에 프로토콜 기반 프로그래밍 원칙을 따르므로 `RootRouter` 와 `LoggedInBuilder` 가 밀접하게 결합되지 않도록 합니다.

*(프로토콜을 사용함으로써 DIP(의존성 역전 원칙)을 따를 수 있게 되었다.)*

### Swizzling 이란?

뒤섞다라는 뜻인데, 런타임 시점에 기존 메서드를 다른 메서드로 바꾸어 실행하는 것을 method swizzling 이라고 부르는데 swizzling 기반의 mocking 역시 런타임시에 test mock 으로 바꾸는 것으로 이해하면 될 것 같다. 즉, 위의 내용은 Swift 에서는 swizzling 기반의 mocking 이 불가능하기 때문에 test mock 을 프로토콜을 사용해서 전달한다는 것이다.

### Swift 에서 swizzling 기반의 mocking 이 왜  불가능할까?

swizzling 은 NSObject 및 기타 c 클래스와 같은 Objective-C 런타임에 액세스 할 수 있는 경우에만 가능하다고 합니다. 순수한 Swift object 와 value 는 swizzling 을 허용하지 않는다고 합니다.

구글링을 해보니 swizzling 을 위해서는 NSObject 를 채택한 클래스를 만들거나 Swift 에서 Objective-C 런타임을 사용가능한 dynamic 키워드를 붙이는 등의 사용하고 있었습니다. 또한, swizzling 의 기본적인 구현으로써 selector 를 사용하거나 `class_getInstanceMethod`, `method_exchangeImplementations` 같은 Objective-C 런타임을 지원하는 메서드를 사용해야 했습니다. 즉, Swift 에서는 허용하지 않기 때문에 Objective-C 를 사용하는 것을 알 수 있었습니다.

참고: 

- [Swift) Method Swizzling을 알아보자](https://babbab2.tistory.com/76)

- [Practical Swift](https://books.google.co.kr/books?id=RbaiDQAAQBAJ&pg=PA146&lpg=PA146&dq=swift+swizzle+mock&source=bl&ots=FQjPexZ-nz&sig=ACfU3U22Z7SQDtfEbuTQR8pSDuqSfwFnBA&hl=ko&sa=X&ved=2ahUKEwie5aTQ4af4AhWxn2MGHUfvAtMQ6AF6BAgvEAM#v=onepage&q=swift%20swizzle%20mock&f=false)
---

**다시 돌아와서!**

`LoggedIn` RIB 에 대한 모든 boilerplate code 를 작성했으며 `Root` RIB 가 이것을 인스턴스화할 수 있도록 하였습니다. 이제 `RootRouter` 에서 `routeToLoggedIn` 메서드를 구현할 수 있습니다.

추가하기 좋은 위치는 `// MARK: - Private` 섹션 앞입니다.

```swift
// MARK: - RootRouting

func routeToLoggedIn(withPlayer1Name player1Name: String, player2Name: String) {
    // Detach LoggedOut RIB.
    if let loggedOut = self.loggedOut {
        detachChild(loggedOut)
        viewController.dismiss(viewController: loggedOut.viewControllable)
        self.loggedOut = nil
    }

    let loggedIn = loggedInBuilder.build(withListener: interactor)
    attachChild(loggedIn)
}
```

위의 코드에서 볼 수 있듯이 제어를 자식 RIB 로 전환하려면 부모 RIB 가 기존 자식(=loggedOut)을 분리하고 새 자식 RIB(=loggedIn) 를 만들고 연결해야 합니다. RIB 아키텍처에서 부모 라우터는 항상 자식 라우터를 연결합니다.

RIB 와 뷰 사이의 일관성을 유지하는 것도 부모 RIB 의 책임입니다. 자식 RIB 가 뷰 컨트롤러를 가진 경우, 부모 RIB 는 자식 RIB 가 분리되거나 연결되 때 자식 뷰 컨트롤러를 dismiss 하거나 present 해야합니다. 뷰 컨트롤러를 소유한 RIB 를 연결하는 방법을 이해하려면  `routeToLoggedOut` 메소드의 구현을 확인하면 된다.

(아래와 같이 오류를 확인할 수 있다. 이하의 내용은 지금 이것을 해결해 보겠다는 이야기이다.)

<img width="500" alt="3" src="https://user-images.githubusercontent.com/69136340/174248207-f787c4ec-1c74-4219-88df-2914eb3d9c51.png">

새로 생성된 `LoggedIn` RIB 에서 이벤트를 수신할 수 있도록 `Root` RIB 는 interactor 를 `LoggedIn` RIB 의 리스너로써 구성합니다. 이것은 `Root` RIB 가 위의 코드에서 자식 RIB 를 빌드할 때 발생합니다. 그러나, 이 시점에서 `Root` RIB 는 `LoggedIn` RIB 의 요청에 응답할 수 있는 프로토콜을 아직 구현하지 않았습니다.

RIBs는 프로토콜 기반이므로 리스너 인터페이스를 준수할 때 관대합니다. 다른 implicit observation methods 대신 프로토콜을 사용하므로 부모가 런타임에 silently failing(알리지 않는 런타임상의 모든 오류) 대신 자식의 모든 이벤트를 구현하지 않을 때 컴파일러에서 오류를 반환합니다.(그래서 현재 프로토콜을 구현하지 않았기 때문에 컴파일러에서 오류를 확인할 수 있는 것이다.)

이제 `RootInteractable` 을 loggedInBuilders 의 build 메서드에 대한 리스너로 전달하므로 `RootInteractable` 은 `LoggedInListener` 프로토콜을 준수해야 합니다. 이 준수성을 `RootInteractable` 에 추가해 보겠습니다. 

```swift
protocol RootInteractable: Interactable, LoggedOutListener, LoggedInListener {
    weak var router: RootRouting? { get set }
    weak var listener: RootListener? { get set }
}
```

LoggedOut RIB 를 분리하고 뷰를 dismiss 할 수 있으려면 RootViewControllable 프로토콜에 새로운 dismiss 메서드를 추가해야 합니다. 즉, 아래의 오류를 해결해보겠다는 이야기 입니다.

<img width="500" alt="4" src="https://user-images.githubusercontent.com/69136340/174248253-1566fb9a-3177-46f0-95b6-cf75155e7830.png">

프로토콜을 다음과 같이 수정해줍니다.

```swift
protocol RootViewControllable: ViewControllable {
    func present(viewController: ViewControllable)
    func dismiss(viewController: ViewControllable)
}
```

프로토콜에 dimiss 메서드를 추가하려면 RootViewController 에서 구현해야 합니다. present 메서드에 다음의 코드를 추가하면 됩니다.

```swift
func dismiss(viewController: ViewControllable) {
    if presentedViewController === viewController.uiviewController {
        dismiss(animated: true, completion: nil)
    }
}
```

이제 RootRouter 는 이전에 구현한 routeToLoggedIn 메서드를 사용해서 LoggedIn RIB 로 라우팅할 때 LoggedOut RIB 를 올바르게 분리하고 뷰 컨트롤러를 dismiss 할 수 있습니다.(즉, 오류가 해결됐습니당!)

## 생성하는 대신 `LoggedInViewControllable` 을 전달

---

`LoggedIn` RIB 는 viewless 이지만 여전히 자식 RIBs 의 뷰를 표시할 수 있어야 하므로 LoggedIn RIB 는 상위 뷰에 액세스해야 합니다. 이 튜토리얼의 경우 `LoggedIn` RIB 의 부모 RIB 인 `Root` RIB 에서 제공해야 합니다.

파일 끝에 extension 을 추가하여 `LoggedInViewControllable` 을 준수하도록 `RootViewController` 를 업데이트합니다.

```swift
// MARK: LoggedInViewControllable

extension RootViewController: LoggedInViewControllable {
}
```

`LoggedInViewContorllable` 인스턴스를 `LoggedIn` RIB 에 주입해야 합니다. [[tutorial 3](https://github.com/uber/RIBs/wiki/iOS-Tutorial-3)](https://github.com/uber/RIBs/wiki/iOS-Tutorial-3) 에서 다루게 될 것이기 때문에 지금 당장은 하지 않을 것입니다. 

이제 `LoggedIn` RIB 는 `Root` RIB 의해 구현된 `LoggedInViewControllable` 에서 메소드를 호출하여 자식 RIBs 뷰를 표시하거나 숨길 수 있습니다.

## `LoggedIn` RIB 로드할 때 `OffGame` RIB 를 연결

---

앞서 언급했듯이 `LoggedIn` RIB 는 뷰가 없으며 RIB 간의 전환만 가능합니다. 이번 순서에서는 첫 번째 자식 RIB 인 `OffGame` RIB 를 만들어서 “Start Game” 버튼을  표시하고 탭을 처리해봅시다.

OffGame 새 그룹을 만들어서 RIB 를 만들고, OffGameViewController 클래스에서 UI 를 구해봅시다. [제공된 구현](https://raw.githubusercontent.com/uber/ribs/assets/tutorial_assets/ios/tutorial2-composing-ribs/source/source2.swift)을 사용할 수 있습니다.

<img width="800" alt="스크린샷 2022-06-17 오후 4 29 50" src="https://user-images.githubusercontent.com/69136340/174248385-0e941309-5443-48c3-b35a-a641fc638524.png">

*(제공된 링크와 동일한 코드입니다.)*

```swift
import RIBs
import SnapKit
import UIKit

protocol OffGamePresentableListener: class {
    // TODO: Declare properties and methods that the view controller can invoke to perform
    // business logic, such as signIn(). This protocol is implemented by the corresponding
    // interactor class.
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
    }
}
```

이제 새로 생성된 `OffGame` RIB 를 부모 `LoggedIn` 과 연결해 보겠습니다. `LoggedIn` RIB 는 `OffGame` RIB  를 빌드하고 자식으로 attach(연결)할 수 있어야 합니다.

`LoggedInRouter` 의 생성자를 변경하여 `OffGameBuildable` 인스턴스에 대한 dependency 를 선언합니다.

```swift
init(interactor: LoggedInInteractable,
     viewController: LoggedInViewControllable,
     offGameBuilder: OffGameBuildable) {
    self.viewController = viewController
    self.offGameBuilder = offGameBuilder
    super.init(interactor: interactor)
    interactor.router = self
}
```

또한, `offGameBuilder` 에 대한 참조를 유지하기 위해 새로운 private 상수를 선언해야 합니다.

```swift
// MARK: - Private

...

private let offGameBuilder: OffGameBuildable
```

이제 `LoggedInBuilder` 를 업데이트하여 `OffGameBuilder` concrete 클래스를 인스턴스화하고, `LoggedInRouter` 인스턴스를 주입합니다. `build` 함수를 다음과 같이 수정합니다.

```swift
func build(withListener listener: LoggedInListener) -> LoggedInRouting {
    let component = LoggedInComponent(dependency: dependency)
    let interactor = LoggedInInteractor()
    interactor.listener = listener

    let offGameBuilder = OffGameBuilder(dependency: component)
    return LoggedInRouter(interactor: interactor,
                          viewController: component.loggedInViewController,
                          offGameBuilder: offGameBuilder)
}
```

OffGameBuilder 의 dependency 을 만족시키기 위해서 OffGameComponent 에 준수하도록 LoggedInComponent 클래스를 수정합니다.(RIB dependencies and components 는 tutorial 3 에서 자세히 다루겠습니다.)

<img width="500" alt="5" src="https://user-images.githubusercontent.com/69136340/174248705-ce101569-a2ae-45e8-a6b6-b47cab89b36d.png">

```swift
final class LoggedInComponent: Component<LoggedInDependency>, OffGameDependency {
    
    fileprivate var loggedInViewController: LoggedInViewControllable {
        return dependency.loggedInViewController
    }
}
```

사용자가 로그인한 후에 `OffGame` RIB 로 구동되는 시작 화면을 보여주겠습니다. 즉, `LoggedIn` RIB 가 로드되는 즉시 `OffGame` RIB 를 연결해야 합니다. `LoggedInRouter` 의 `didLoad` 메서드를 오버라이드하여 `OffGame` RIB 를 로드해보겠습니다.

```swift
override func didLoad() {
    super.didLoad()
    attachOffGame()
}
```

`attachOffGame` 은 `OffGame` RIB 를 빌드 및 연결하고 뷰 컨트롤러를 표시하는데 사용되는 `LoggedInRouter` 클래스의 private 메서드입니다. 이 메서드의 구현을 `LoggedInRouter` 클래스의 끝에 추가합니다.

```swift
// MARK: - Private

private var currentChild: ViewableRouting?

private func attachOffGame() {
    let offGame = offGameBuilder.build(withListener: interactor)
    self.currentChild = offGame
    attachChild(offGame)
    viewController.present(viewController: offGame.viewControllable)
}
```

`attachOffGame` 메서드 내에서 `OffGameBuilder` 를 인스턴스화하려면 `LoggedInInteractable` 인스턴스를 주입해야 합니다. 이 `interactor` 는 부모가 자식 RIB 에서 오는 이벤트를 수신하고 해석할 수 있도록 하는 `OffGame` 의 리스너 인터페이스 역할을 합니다.

`OffGame` RIB 이벤트를 수신하려면 `LoggedInInteractable` 이 `OffGameListener` 프로토콜을 준수해야 합니다. 지금은 그렇지 않기 때문에 아래와 같은 에러가 나옵니다.

<img width="500" alt="6" src="https://user-images.githubusercontent.com/69136340/174248811-b7085dde-30ba-4a83-ae90-d3efc1aa0ddc.png">

```swift
protocol LoggedInInteractable: Interactable, OffGameListener {
    weak var router: LoggedInRouting? { get set }
    weak var listener: LoggedInListener? { get set }
}
```

이제 `LoggedIn` RIB 는 로드 후에 `OffGame` RIB 를 연결하고 발생하는 이벤트를 수신할 수 있습니다.

## Loggedin RIB 가 detach 될 때 attach 된 뷰 cleaning

---

`LoggedIn` RIB 는 viewless 이고 오히려 부모의 뷰 hierarchy 를 수정하기 때문에 `Root` RIB 는 `LoggedIn` RIB 가 수행했을 수 있는 view modifications 를 자동으로 제거할 방법이 없습니다. 다행히도 viewless `LoggedIn` RIB 를 생성하는데 사용한 Xcode 템플릿은 `LoggedIn` RIB 가 detach 될 때 view modifications 을 정리할 수 있는 hook 를 이미 제공합니다. 

`LoggedInViewControllable` 프로토콜에서 present 와 dismiss 선언:

(다음의 에러를 해결할 수 있다.)

<img width="500" alt="7" src="https://user-images.githubusercontent.com/69136340/174248905-43fb44e2-2936-4b7b-8416-5bb1f49dcbd5.png">

```swift
protocol LoggedInViewControllable: ViewControllable {
    func present(viewController: ViewControllable)
    func dismiss(viewController: ViewControllable)
}
```

다른 프로토콜 선언과 유사하게, 이 선언은 `LoggedIn` RIB 에 `ViewControllabe` 을 dismiss 하는 기능이 필요함을 선언합니다.

그런 다음 `LoggedInRouter` 의 `cleanupViews` 메서드를 업데이트하여 현재 자식 RIB 의 뷰 컨트롤러를 dismiss 합니다.

```swift
func cleanupViews() {
    if let currentChild = currentChild {
        viewController.dismiss(viewController: currentChild.viewControllable)
    }
}
```

`cleanupViews` 메서드는 부모 RIB 가 `LoggedIn` RIB 를 detach 하기로 결정할 때 `LoggedInInteractor` 에 의해서 호출됩니다. cleanupViews 에서 presented 뷰 컨트롤러를 해제함으로써 LoggedIn RIB 가 detach 된 후 view hierarchy 에 뷰를 남기지 않도록 보장합니다.

## “Start Game” 버튼을 탭하면 `TicTacToe` RIB 로 전환

---

이 튜토리얼의 앞부분에서 말했듯이 `LoggedIn` RIB 는 사용자가 `OffGame` 과 TicTacToe RIB 사이를 전환할 수 있어야 합니다. `OffGame` 은 “Start Game” 스크린을 표시하고 `TicTacToe` 는 게임필드를 그리고, 플레이어의 움직임을 처리하는 역할을 합니다. 지금까지는 `OffGame` RIB 만 구현했고 사용자가 로그인한 후 `LoggedIn` RIB 에서 제어를 보장했습니다. 이제, `TicTacToe` RIB 를 구현하고 `OffGame` RIB 에 있는 “Start Game” 버튼을 탭해서 전환할 것입니다.

이 단계는 “Login” 버튼을 탭할 때 `LoggedIn` RIB 를 연결하고, `LoggedOut` RIB 를 분리하는 것과 매우 비슷합니다. 시간을 아끼기 위해서 `TicTacToe` RIB 이미 구현되어 프로젝트에 있을 것입니다.

TicTacToe 로 route 하기 위해서 `LoggedInRouter` 클래스에 있는 `routeToTicTacToe` 메서드를 구현해야합니다. 그리고 버튼 탭 이벤트를 `OffGameViewController` 에서 `OffGameInteractor` 로, 마침내 `LoggedInInterator` 로 연결해야 합니다.

앱을 실행하고 login 을 한 다음 “Start Game” 버튼을 눌러 `TicTacToe` RIB 가 로드되고 게임 필드가 표시되는지 확인하면 됩니다.

이 작업을 할 때 새 `OffGameListener` 의 메서드 이름은 `startTicTacToe` 로 지정하는 것이 좋습니다. 이 메서드는 이미 unit test 용으로 작성되어 있기 때문에 그렇지 않으면 나중에 unit test 를 빌드할 때 컴파일 오류를 볼 수 있습니다.

## winner 가 되었을 때 OffGame RIB 연결과 TicTacToe RIB 분리

---

게임이 끝나면 `TicTacToe` RIB 에서 `OffGame` RIB 로 다시 전환하려고 합니다. 제공된 `TicTacToe` RIB 에는 이미 리스너가 설정되어 있습니다. `LoggedIn` RIB 가 `TicTacToe` 이벤트에 응답할 수 있도록 `LoggedInInteractor` 에서 구현하기만 하면 됩니다.

`LoggedInRouting` 프로토콜에서 `routeToOffGame` 메서드를 선언해줍니다.(`LoggedInInteractor` 클래스에 선언되어 있습니다.)

```swift
protocol LoggedInRouting: Routing {
    func routeToTicTacToe()
    func routeToOffGame()
    func cleanupViews()
}
```

`LoggedInInteractor` 클래스에서 `gameDidEnd` 메서드를 구현합니다.(자식 RIB TicTacToeInteractor 에서 TicTacToeListener 리스너를 활용해서 메서드를 호출.)

```swift
// MARK: - TicTacToeListener

func gameDidEnd() {
    router?.routeToOffGame()
}
```

`LoggedInRouter` 클래스의 `routeToOffGame` 을 구현합니다.

```swift
func routeToOffGame() {
    detachCurrentChild()
    attachOffGame()
}
```

pivate section 에 private helper 를  추가합니다.

```swift
private func detachCurrentChild() {
    if let currentChild = currentChild {
        detachChild(currentChild)
        viewController.dismiss(viewController: currentChild.viewControllable)
    }
}
```

플레이어 중 한 명이 게임에서 이기면 앱이 game screen 에서 start screen 으로 전환됩니다.

## Unit testing

---

마지막으로 앱에 대한 unit test 를 작성해보겠습니다. RootRouter 클래스를 테스트해 보겠습니다. 동일한 원칙을 RIB 의 다른 부분에 대한 unit test 에 적용할 수 있으며 RIB 에 대한 모든 unit test 를 생성하는 템플릿도 있습니다.

`TicTacToeTests/Root` 그룹에 새로운 `RootRouterTests.swift` 파일을 만들고, `TicTacToeTest` target 에 추가합니다.

<img width="500" alt="8" src="https://user-images.githubusercontent.com/69136340/174248979-f5e862fd-d05d-4230-a304-124827cdef4d.png">

 `routeToLoggedIn` 메서드의 동작을 확인하는 테스트를 작성해 보겠습니다. 이 메서드가 호출되면 `RootRouter` 는 `LoggedInBuildable` 프로토콜의 `build` 메서드를 호출하고 반환된 router 를 attach 해야 합니다.

(이해를 돕기위해서 코드를 가져왔습니다.)

<img width="600" alt="9" src="https://user-images.githubusercontent.com/69136340/174248994-26881de1-b70b-43d8-907d-e29110cc2923.png">

test 의 구현을 위해서 [이 코드](https://raw.githubusercontent.com/uber/ribs/assets/tutorial_assets/ios/tutorial2-composing-ribs/source/source3.swift)를 RootRouterTests 에 복사하고 테스트가 컴파일되고 통과하는지 확인해봅시다.
*(제공된 링크와 동일한 코드입니다.)*

```swift
@testable import TicTacToe

import XCTest

class RootRouterTests: XCTestCase {

    private var loggedInBuilder: LoggedInBuildableMock!
    private var rootInteractor: RootInteractableMock!
    private var rootRouter: RootRouter!

    override func setUp() {
        super.setUp()

        loggedInBuilder = LoggedInBuildableMock()
        rootInteractor = RootInteractableMock()
        rootRouter = RootRouter(interactor: rootInteractor,
                   viewController: RootViewControllableMock(),
                   loggedOutBuilder: LoggedOutBuildableMock(),
                   loggedInBuilder: loggedInBuilder)
    }

    func test_routeToLoggedIn_verifyInvokeBuilderAttachReturnedRouter() {
        let loggedInRouter = LoggedInRoutingMock(interactable: LoggedInInteractableMock())
        var assignedListener: LoggedInListener? = nil
        loggedInBuilder.buildHandler = { (_ listener: LoggedInListener) -> (LoggedInRouting) in
            assignedListener = listener
            return loggedInRouter
        }

        XCTAssertNil(assignedListener)
        XCTAssertEqual(loggedInBuilder.buildCallCount, 0)
        XCTAssertEqual(loggedInRouter.loadCallCount, 0)

        rootRouter.routeToLoggedIn(withPlayer1Name: "1", player2Name: "2")

        XCTAssertTrue(assignedListener === rootInteractor)
        XCTAssertEqual(loggedInBuilder.buildCallCount, 1)
        XCTAssertEqual(loggedInRouter.loadCallCount, 1)
    }
}
```

위의 테스트 구조를 살펴보겠습니다.

`RootRouter` 를 테스트할 때 인스턴스화해야 합니다. router 는 mock 으로 인스턴스화되는 많은 프로토콜 기본 dependency 가 있습니다. mocks 는 이미 `TicTacToeMocks.swift` 에 준비되어 있습니다. 다른 RIB 에 대한 unit test 를 작성할 때 이를 위한 mocks 를 직접 만들어야 합니다.

`routeToLoggedIn` 을 호출할 때 root router 의 구현은 `LoggedIn` RIB 의 build 메서드를 호출하여 라우터를 인스턴스화해야 합니다. builder logic 을 mocks 로 복사하고 싶지 않기 때문에 대신 LoggedInRouting 인터페이스를 구현하는 router mock 을 반환하는 클로저를 전달합니다. 이 클로저는 테스트를 실행하기 전에 구성됩니다.

handler closures 로 작업하는 것은 unit test 중에 많이 사용하는 일반적인 개발 패턴입니다. 또 다른 패턴은 메서드의 호출 수를 계산하는 것입니다. 예를 들어, 우리가 테스트하는 `routeToLoggedIn` 메서드의 구현에서 `LoggedInBuildable` 의 `build` 메서드를 정확히 한 번 호출해야 한다는 것을 알고 있습니다. 그래서 우리는 테스트에서 메서드를 호출하기 전과 후에 각각의 mock 호출 횟수를 확인합니다.

## Tutorial completed

---

두 번째 튜토리얼은 마무리되었습니다. 이제 [tutorial 3](https://github.com/uber/RIBs/wiki/iOS-Tutorial-3) 로 넘어가봅시다.

**출처:**

[iOS Tutorial 2 · uber/RIBs Wiki](https://github.com/uber/RIBs/wiki/iOS-Tutorial-2)
