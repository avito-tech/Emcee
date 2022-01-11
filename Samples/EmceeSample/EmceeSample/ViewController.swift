import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func raiseException() {
        NSException(
            name: .genericException,
            reason: "EmceeSample.ViewController test exception",
            userInfo: nil
        ).raise()
    }

}

