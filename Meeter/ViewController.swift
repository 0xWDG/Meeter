//
//  ViewController.swift
//  Meeter
//
//  Created by Wesley de Groot on 01/12/2022.
//

import Cocoa
import WebKit

// This is not the nicest piece of code, and does not handle errors.
// how to use:
// 1) change the configuration part.
// 2) login to meetup and press "start".
// 3) wait until done.
class ViewController: NSViewController {
    var meetupEventURL = "https://www.meetup.com/appsterdam/events/"
    var eventNameToAttend = "Weekly Meeten en Drinken"
    var timeout: Double = 15

    // DO NOT CHANGE ANYTHING BELOW
    @IBOutlet weak var wv: WKWebView!
    @IBOutlet weak var status: NSTextField!

    // Wait before loading the "next" page.
    var meetupURLs: [String] = [];
    var loginURL = URL(string: "https://www.meetup.com/login/")!
    var eventProgressCounter = 1;

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        wv.load(URLRequest.init(url: loginURL))
    }

    @IBAction func didLoginToMeetup(_ sender: Any) {
        // Load event page.
        setStatus("Loading page")
        wv.load(
            .init(
                url: .init(string: meetupEventURL)!
            )
        )

        var cnt = 1;
        perform(after: 5, times: 10) {
            self.setStatus("Scrolling to bottom (\(cnt)/10)... ETA \(55-(cnt*5))s.")
            self.wv.evaluateJavaScript("window.scrollTo(1000000,1000000);")
            cnt += 1
        }

        perform(after: 55, times: 1) {
            self.setStatus("Fetching URL's...")
            self.wv.evaluateJavaScript("""
            var urls = [];
            document.querySelectorAll("a[class=eventCard--link]").forEach(
                function (event) {
                    if(event.firstChild.innerText == "\(self.eventNameToAttend)") {
                        urls.push(event.href);
                    }
                }
            )
            urls;
            """) { data, error in
                if error == nil {
                    self.setStatus("Got data")

                    if let strData = data as? [String] {
                        self.setStatus("Attending to \(strData.count) events...")
                        self.meetupURLs = strData
                        print("URLs=", strData)

                        self.attendToMeetups()
                    }
                } else {
                    self.setStatus("Error, please see console")
                }
            }
        }
    }

    func attendToMeetups() {
        var timer = 0
        for meetupURL in self.meetupURLs {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + (Double(timer + 1) * timeout)
            ) {
                self.attendTo(url: meetupURL)
            }
            timer += 1
        }
    }

    func attendTo(url: String) {
        setStatus("Loading meetup \(self.eventProgressCounter)/\(self.meetupURLs.count), url: \(url)")
        wv.load(.init(url: .init(string: url)!))

        perform(after: timeout / 2, times: 1) {
            self.setStatus("Attending meetup \(self.eventProgressCounter)/\(self.meetupURLs.count), url: \(url)")
            self.wv.evaluateJavaScript("""
                    document.querySelectorAll("button").forEach(
                        function (attendButton){
                            if (attendButton.innerText == "Attend") {
                                attendButton.click();
                                document.querySelectorAll("button").forEach(
                                    function (confirmButton){
                                        if (confirmButton.innerText == "Submit") {
                                            confirmButton.click();
                                        }
                                    }
                                );
                            }
                        }
                    );
            """)

            self.eventProgressCounter += 1
        }
    }

    func setStatus(_ status: String) {
        print(status)
        self.status.stringValue = status
    }

    func perform(after: Double, times: Int = 1, action: @escaping () -> Void) {
        for time in stride(from: 0, to: times, by: 1) {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + (Double(time + 1) * after),
                execute: action
            )
        }
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}

