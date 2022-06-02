[https://github.com/uber/RIBs](https://github.com/uber/RIBs)

### 내용

- RIBs 에 대해서 알아봤으니 튜토리얼을 따라가 보겠습니다.

[iOS Tutorial 1 · uber/RIBs Wiki](https://github.com/uber/RIBs/wiki/iOS-Tutorial-1)

# 준비

- 우선 RIBs 를 설치하고, template 을 설치해 주어야 합니다.

## **Installation for iOS**


**CocoaPods**

To integrate RIBs into your project add the following to your `Podfile`:

```swift
pod 'RIBs', '~> 0.9'
```

**Carthage**

To integrate RIBs into your project using Carthage add the following to your `Cartfile`:

```swift
github "uber/RIBs" ~> 0.9
```

## RIB Tooling

[Home · uber/RIBs Wiki](https://github.com/uber/RIBs/wiki#rib-tooling)

앱 전반에 걸쳐 RIB 아키텍쳐를 원활하게 채택할 수 있도록 tooling 에 투자해야합니다. RIBs 아키텍쳐를 채택하여 생성된 불변성을 활용하고, RIBs 를 더 쉽게 사용할 수 있도록 하기 위해서입니다.

지금까지 오픈소스로 공개한 RIB 관련 tooling 에는 다음이 포함됩니다.

- **Code generation:** IDE plugins for creating new RIBs and accompanying tests.
    - [iOS code generation templates for Xcode](https://github.com/uber/RIBs/tree/master/ios/tooling)
    - [Android code generation IDE plugin](https://github.com/uber/RIBs/tree/master/android/tooling/rib-intellij-plugin)
- **NPE Static analysis (Android):** [NullAway](https://github.com/uber/NullAway) is a static analysis tool that makes NullPointerExceptions a thing of the past.
- **Autodispose Static Analysis (Android):** Prevents the most common RIB memory leak.

🙌 **이 중에서 해당되는 [iOS code generation templates for Xcode](https://github.com/uber/RIBs/tree/master/ios/tooling) 을 통해서 template 생성을 해보겠습니다.**

## RIBs Xcode Templates

[iOS Tooling · uber/RIBs Wiki](https://github.com/uber/RIBs/wiki/iOS-Tooling)

RIBs scaffolding(발판 재료) 와 test scaffolding 을 생성하기 위해 Xcode 템플릿을 만들어서 RIBs 사용 및 채택을 더 쉽게 합니다. scaffolded 클래스는 비즈니스 로직을 추가할 준비가 된 RIBs 가 연결되어 있습니다.

### template 설치

[https://github.com/uber/RIBs](https://github.com/uber/RIBs)

여기에서 zip 으로 다운 혹은 clone 후, 터미널에서 `<RIBs 경로>/ios/tooling` 경로로 이동합니다.

그 후 아래와 같이 입력해서 template 을 설치합니다.

```swift
./install-xcode-template.sh
```

- 다음과 같이 RIBs 템플릿이 생성되었다.

<img src="https://user-images.githubusercontent.com/69136340/171554248-7e0e148c-7318-4abf-a1d6-d0ea7611615c.png" width ="500">

# 시작

- RIBs Wiki 의 Tutorial 1 을 번역 및 진행 내용입니다.

[iOS Tutorial 1 · uber/RIBs Wiki](https://github.com/uber/RIBs/wiki/iOS-Tutorial-1)

## Create your first RIB

튜토리얼의 일부로 RIBs 아키텍쳐 및 관련  tooling 을 사용하여 간단한 TicTacToe 게임을 빌드할 것입니다. 튜토리얼의 starting point 가 되는 source file 을 [**여기에서**](https://github.com/uber/RIBs/tree/main/ios/tutorials/tutorial1) 다운받아서 README 를 따라서 설치하시고, 계속 진행하면 됩니다.

README 내용을 요약하면 source file 다운 후, 아래의 과정을 진행해야 합니다.

- `pod install` 하여 TicTacToe.xcworkspace 을 만들어주어야 합니다.
- 앞서 안내한 과정처럼 templates 설치합니다.

추가적으로 다음과 같은 오류가 나온다면 다음과 같이 podfile 을 수정해주면 됩니다.(최신버전이 설치됩니다.)

<img width="500" alt="2" src="https://user-images.githubusercontent.com/69136340/171554281-4e9ef9e6-d545-4af1-a23d-7d253ff936e4.png">

```swift
platform :ios, '9.0'

use_frameworks!
inhibit_all_warnings!

target 'TicTacToe' do
  pod 'RIBs'
  pod 'SnapKit'
  pod 'RxCocoa'
end
```

### ❗️AppDelegate 에서 RootBuilder Launch 에러

- 프로젝트를 열고 아무것도 하지 않아도 AppDelegate 에서 에러가 발생할 거에요…! `launch(form:)` 대신 `launchFromWindow(_:)` 으로 메서드를 대체해주면 됩니다.

```swift
let launchRouter = RootBuilder(dependency: AppComponent()).build()
        self.launchRouter = launchRouter
        launchRouter.launch(from: window)

// 위와 같이 AppDelegate 에 선언되어 있을텐데 Louter Tree 를 실행하는 코드가 변경되었다.()
launchRouter.launchFromWindow(window)
// 로 변경해주어야 한다.
```

LaunchRouter 클래스를 확인해보니 lauchFromWindw(_:) 메서드만 있고, 구현부를 보니 rootViewController 를 지정하는 것을 보아서 튜토리얼이 업데이트가 되지 않은줄…알았는데요.

LaunchRouter 파일의 맨 첨 커밋을 보니까… 처음부터 launchFromWindow 인데요..? 아무튼.. 그렇습니다.

[Add all RIB, Worker and Workflow classes · uber/RIBs@e542fe0](https://github.com/uber/RIBs/commit/e542fe07af5cc1e35ee9a45bdf3e36917ececa22#diff-d7ce5f9505a8f94f5926ba615146f6d7f5c021ba79eb2d747705b9ece556b034)

## Goal

<img src="https://user-images.githubusercontent.com/69136340/171554328-694c2ece-a8f9-4e78-86d0-6e6e558a22d5.png" width ="220">

tutorial 1 의 목표는 RIB 의 다양한 부분을 이해하고, 더 중요하게는 서로 상호작용하고 통신하는 방법을 이해하는 것 입니다.

**이 튜토리얼에서 구현할 것은?**

- 사용자가 플레이어 이름을 입력하고 로그인 버튼을 탭할 수 있는 화면.
- 버튼을 탭하면 Xcode 콘솔에 플레이어의 이름 출력.

## Project structure

제공하는 Boilerplate code(=상용구 코드, 변형없이 여러 위치에서 반복되는 코드 섹션) 는 두 개의 RIBs(`LoggedOut`, `Root`) 로 구성된 iOS 프로젝트를 포함하고 있습니다. 앱이 시작되면 AppDelegate 는 Root RIB 를 빌드하고, 애플리케이션에 대한 제어를 Root RIB 로 전송합니다. Root RIB 의 목적은 RIBs tree 의 루트 역할을 하고 필요할 때 자식에게 제어를 전달하는 것입니다. Root RIB 의 코드는 대부분 Xcode 템플릿에 의해 자동으로 생성되므로 이 코드를 이해하는 것은 이번에 필요하지 않습니다.

TicTacToe 앱의 두번째 RIB  `LoggedOut` 는 로그인 인터페이스와 인증 관련 이벤트를 관리해야 합니다. `Root` RIB `AppDelegate` 로부터 제어를 얻었을 때, 즉시 제어를 `LoggedOut` RIB 로 전송하여 로그인 양식을 보여줍니다.  `LoggedOut` RIB 를 빌드하고 보여주는 것을 담당하는 코드는 이미 `RootRouter` 에서 찾을 수 있습니다.

지금은 `LoggedOut` RIB 가 구현되어 있지 않습니다. `LoggedOut` 그룹을 연다면 코드를 컴파일하는데 필요한 일부 stub(=구현되지 않고 틀만 있는 함수)들이 포함된  `DELETE_ME.swift` 파일을 찾을 수 있습니다. 이 튜토리얼에서는 `LoggedOut` RIB 의 적절한 구현에 대해서 진행할 것입니다.

## LoggedOut RIB 만들기

- LoggedOut group 에 Xcode RIB templates 를 통해 새로운 파일을 하나 만듭니다.

<img width="500" alt="4" src="https://user-images.githubusercontent.com/69136340/171554383-a70be77c-b0a4-4fb4-a5b4-17f3bb1c26a6.png">

- `LoggedOut` 라고 Name 을 설정하고, `Owns corresponding view` 체크박스를 체크합니다.

<img width="500" alt="5" src="https://user-images.githubusercontent.com/69136340/171554392-7a74f30b-f6e9-4dde-b3e9-beb043376b2b.png">

RIB 가 view(controller) 를 가질 필요는 없습니다. 하지만, 이 RIB 에는 로그인 인터페이스가 포함되어야 하기 떄문에 뷰컨트롤러를(플레이어 이름을 가진 text fields 와 “Login” 버튼을 가짐) 만들려고 합니다. `Owns corresponding view` 체크박스를 선택하면 해당 뷰컨트롤러 클래스로 새 RIB 가 생성됩니다.

<img width="400" alt="6" src="https://user-images.githubusercontent.com/69136340/171554427-5e2ae2fd-0590-47be-8adb-62a798bcd748.png">

> 호오… Interactor, ViewController, Router 가 생성되었습니다.

`DELETE_ME.swift` 파일을 삭제해줍니다.

## 생성된 코드 이해하기

<img src="https://user-images.githubusercontent.com/69136340/171554456-d376f0b4-f51e-43df-b8d8-5fc9cb375982.png" width ="700">

`LoggedOut` RIB 를 만들면서 여러 클래스가 만들어졌습니다.

- `LoggedOutBuilder` : `LoggedOutBuildable` 를 준수하므로 builder 를 사용하는 다른 RIB 는 buildable protocol 을 준수하는 mocked 인스턴스를 사용할 수 있습니다.
- `LoggeddOutInteractor` : `LoggedOutRouting` 프로토콜을 사용하여 라우터와 통신합니다. 이것은 interactor 가 필요한 것을 선언하고, `LoggedOutRouter` 와 같은 다른 유닛이 구현을 제공하는 `Dependency Inversion Principle`(의존성 역전 원칙)을 기반으로 합니다. buildable 프로토콜과 비슷하게 이를 통해서 interactor 가 unit-tested 될 수 있습니다. `LoggedOutPresentable` 은 interactor 가 뷰 컨트롤러와 통신할 수 있도록 하는 하는 동일한 개념입니다.
- `LoggedOutRouter` : interactor 와 통신하기 위해 `LoggedOutInteractable` 에서 필요한 것을 선언합니다. `LoggedOutViewControllable` 를 사용하여 뷰 컨트롤러와 통신합니다.
- `LoggedOutViewController` : `LoggedOutPresentableListener` 를 사용해서 DIP 에 따라 interactor 와 통신합니다.

## LoggedOut UI

아래의 사진은 우리가 원하는 UI 이기 때문에 `LoggedOutViewController` 를 수정해야 합니다. 시간을 아끼기 위해서 [다음의 코드](https://raw.githubusercontent.com/uber/ribs/assets/tutorial_assets/ios/tutorial1-create-a-rib/source/source1.swift)를 LoggedOutViewController 구현부에 더하면됩니다.

프로젝트가 컴파일되도록 예제 코드를 사용하는 경우 LoggedOutViewController 에서 `import SnapKit` 해야합니다.
     
<img src="https://user-images.githubusercontent.com/69136340/171554510-40fabad7-d70a-475f-9834-4ccee24025eb.png" width ="220">


## Login logic

사용자가 `Login` 버튼을 탭한 후, `LoggedOutViewController` 는 사용자가 로그인하기를 원한다는 것을 알리기 위해서 listener(`LoggedOutPresentableListener`) 를 호출해야 합니다. listener 는 로그인 요청을 진행하기 위해서 게임에 참여하는 플레이어들의 이름들을 수신해야 합니다.

logic 을 구현하기 위해서 우리는 listner 를 업데이트해서 뷰 컨트롤러에서 login 요청을 수신할 수 있도록 해야 합니다.

`LoggedOutViewController` 파일의 `LoggedOutPresentableListener` 프로토콜을 다음과 같이 수정합니다:

```swift
protocol LoggedOutPresentableListener: class {
    func login(withPlayer1Name player1Name: String?, player2Name: String?)
}
```

사용자가 플레이어 이름에 아무 것도 입력하지 않을 수 있으므로, 두명의 플레이어 이름은 optional 로 선언해야 합니다. 두 이름이 입력될 때까지 로그인 버튼을 비활성화 할 수 있지만, 이 연습에서는 LoggedOutInteractor 가 빈 이름을 처리하도록 하겠습니다. 플레이어 이름이 비어있다면, 기본적으로 “Player1” 과 “Player2” 로 설정됩니다.

이제, 다음 메서드를 추가해서 `LoggedOutPresentableListener` 프로토콜을 준수하도록 `LoggedOutInteractor` 를 수정합니다.

```swift
// MARK: - LoggedOutPresentableListener

func login(withPlayer1Name player1Name: String?, player2Name: String?) {
    let player1NameWithDefault = playerName(player1Name, withDefaultName: "Player 1")
    let player2NameWithDefault = playerName(player2Name, withDefaultName: "Player 2")

    print("\(player1NameWithDefault) vs \(player2NameWithDefault)")
}

private func playerName(_ name: String?, withDefaultName defaultName: String) -> String {
    if let name = name {
        return name.isEmpty ? defaultName : name
    } else {
        return defaultName
    }
}
```

지금은 사용자가 로그인 할 때 이름만 출력할 것 입니다.

마지막으로, 우리는 로그인 버튼을 눌렀을 때 listener 메서드를 호출하도록 뷰컨트롤러를 연결해야 합니다.(현재 로그인 logic 은 `LoggedOutInteractor` 에 선언되어 있습니다!) `LoggedOutViewController` 에서 `didTapLoginButton` 메서드(튜토리얼 코드를 사용한 경우)를 다음 코드로 변경합니다.

```swift
@objc private func didTapLoginButton() {
    listener?.login(withPlayer1Name: player1Field?.text, player2Name: player2Field?.text)
}
```

## Tutorial complete

축하합니다! 첫 번째 RIB 를 만들었습니다. 지금 프로젝트를 빌드하고 실행하면 interactive button 을 가진 login interface 를 볼 수 있을겁니다. 그리고 버튼을 탭하면, Xcode 콘솔에서 플레이어의 이름이 출력되는 것을 볼 수 있습니다.

요약하자면, 이 튜토리얼에서는 Xcode 템플릿에서 새 RIB 를 생성하고, 인터페이스를 업데이트했으며 사용자가 입력한 데이터를 뷰 컨트롤러에서 interactor 로 전달하는 button tap event 에 대한 handler 를 추가했습니다. 이를 통해 이 두 unit 간의 책임을 분리하고 코드의 testability 를 개선할 수 있습니다.

이제 tutorial 2 로 넘어갑니다.

출처: 

[iOS Tutorial 1 · uber/RIBs Wiki](https://github.com/uber/RIBs/wiki/iOS-Tutorial-1)

[Study-RIBs/tutorials/tutorial1 at master · snowedev/Study-RIBs](https://github.com/snowedev/Study-RIBs/tree/master/tutorials/tutorial1)

[[iOS] RIBs - Tutorial 1](https://duwjdtn11.tistory.com/636)
