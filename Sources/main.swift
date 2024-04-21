// Apple Swift version 5.4.2 (swiftlang-1205.0.28.2 clang-1205.0.19.57)
// Target: x86_64-apple-darwin20.6.0

import Foundation
/* [in Function 1: runCommand]:
 * String
 * [String]
 * Int32
 * 
 * Process()
 * Pipe()
 * 
 * Data
 * 
 * [in/around Function 2: Timer closure]:
 * Timer
 * ClosedRange<PointerOrNumeric>
 * String.Index
 * 
 * [in RunLoop]:
 * CFRunLoopGetCurrent
 * CFRunLoopRun
 * 
 * [in Handle SIGINT]:
 * signal: Actually part of Objective-C's <signal.h> header
 * SIGINT
 * SIG_IGN: same as line 1 of this section
 * DispatchSource
 * CFRunLoopStop
 * SIG_DFL: same as line 3
 */

import AVFoundation
/* AVSpeechSynthesizer
 * 
 * 
 * 
 * 
 */

import Combine // withExtendedLifetime




// [Function 1]:
// Call this function to run any Unix *cmd* with arguments (input data) as an
// ASCII-space-separated list of word-like tokens called *args*
func runCommand(
    cmd : String, // the name of a Unix command, such as pmset or ifconfig
    args : String // such as "-rf" or "push origin main" or "--force"
) -> ( /* tuple body */
    output : [String], // these names are ussed within *runCommand* only
    error : [String], // you will see that we pull out the first member 
    exitCode : Int32 // *output* in [Function 2]. We can name it as we like.
) {
    var output : [String] = [], error : [String] = [], status : Int32

    // [Paragraph 1]:
    // Create a new Process and set 1. launchPath, 2. arguments,
    // and tie new Pipes to 3. standardOutput, and 4. standardError.
    // Then launch the process. In the next paragraph we will collect data.
    let task = Process()
    task.launchPath = cmd // 1.
    var argarr: [String] = [];
    for str in args.split(separator: " ") // str is not a String
    {    argarr.append(String(str))     }
    task.arguments = argarr // 2.
    let outpipe = Pipe()
    let errpipe = Pipe()
    task.standardOutput = outpipe // 3.
    task.standardError = errpipe // 4.
    task.launch()

    // [Paragraph 2]:
    // First declare a local *func*, then call it twice with different args.
    // 1. Functions in Swift can be declared inside functions, meaning that
    //    they are visible only inside that function (function scope).
    // 2. One side each of *outpipe* and *errpipe* are connected to the task
    //    "standardOutput" and "standardError" outputs. The function
    //    *readPipe* reads from a pipe into a bucket, which in this case is
    //    an output variable of *runCommand*, either *output* or *error*.
    // 3. inout means the variable/parameter/argument is passed in with
    //    reference to a "ticket number" instead of copied in by value.
    func readPipe(
        pipe : Pipe,
        bucket : inout [String]
    ) {
        let data: Data? = try? pipe.fileHandleForReading.readToEnd()
        if let string = String(
            data: (data != nil ? data! : Data()),
            encoding: .utf8
        ) {
            for str in string.trimmingCharacters(
                in: CharacterSet.newlines
            ).split(
                separator: "\n"
            ) {
                bucket.append(String(str))
            }
        }
    }
    readPipe(pipe: outpipe, bucket: &output)
    readPipe(pipe: errpipe, bucket: &error)
    
    // [Paragraph 3]:
    // Keep collecting data until subprogram exits and write down the way
    // that the program finished (badly or well) into the output variable 
    // of *runCommand*.
    task.waitUntilExit()
    status = task.terminationStatus

    // [Paragraph 4]:
    // The function is finished but for the return of results back to the 
    // caller, that is, its productivity
    return (output, error, status)
}



// [Function 2: closure]:
// This function is accepted by the block parameter.
// It takes one argument into its unnamed parameter, and we supply *timer*.
// The block parameter is from a call to scheduleTimer, which here schedules
// a recurring timer that keeps on counting down to 0 from 600 (six hundred)
// seconds, and upon reaching 0, calling the closure with itself as *timer*.
let timer = Timer.scheduledTimer(
    withTimeInterval: 600,
    repeats: true, 
block: { timer in
    var speech = AVSpeechUtterance(string: "")
    let synth = AVSpeechSynthesizer()
    let voice = AVSpeechSynthesisVoice(language: "en-US")
    let (output, _, _) = runCommand(
        cmd: "/usr/bin/pmset",
        args: "-g batt"
    )
    let tabIndex = output[1].firstIndex(of: "\t")!
    let lowBatteryPercent = 30
    var percent = -1
    var span: ClosedRange<String.Index>
    let batteryFull = "Battery full. Unplug the charger."
    var chargeBattery = ""

    // \t57% Find the %, assuming first a 2 digit percentage
    //  ^123
    span = output[1].index(
        tabIndex,
        offsetBy: 3
    )...output[1].index(
        tabIndex,
        offsetBy: 3
    )
    if output[1][span] == "%" {
        // \t49% two digit percentage
        //  ^12
        span = output[1].index(
            tabIndex, 
            offsetBy: 1
        )...output[1].index(
            tabIndex, 
            offsetBy: 2
        )
        if let int = Int(output[1][span])
        {   percent = int   }
    }
    else {
        // \t100% 3 digit percentage
        //  ^123
        span = output[1].index(
            tabIndex, 
            offsetBy: 1
        )...output[1].index(
            tabIndex, 
            offsetBy: 3
        )
        if let int = Int(output[1][span]) 
        {   percent = int   }
    }

    if output[0].contains("AC Power") && percent > 95
    {   speech = AVSpeechUtterance(string: batteryFull)     }
    else if (
        output[0].contains("Battery Power") &&
        percent <= lowBatteryPercent
    )
    {   
        chargeBattery = "Battery at \(percent) percent. Charge the battery."
        speech = AVSpeechUtterance(string: chargeBattery)
    }
    speech.voice = voice;
    synth.speak(speech)
    print(percent)
})



// [RunLoop]:
// A RunLoop is told to run, which is normal, but *withExtendedLifetime*
// only calls its *body* to run the RunLoop after it guarantees that *timer*
// (not the same as the closure argument *timer* from [Function 2]) will be
// held in computer memory until we call *CFRunLoopStop* in the
// [Handle SIGINT] section directly below.
//
// CF stands for CoreFoundation, a package that is written not in Swift but
// the lower-level language Objective-C. Notice that importing *Foundation*
// also imports CoreFoundation.
let runLoop = CFRunLoopGetCurrent()
withExtendedLifetime(timer) { // body: {}
    CFRunLoopRun()
}



// [Handle SIGINT (Ctrl-C)]:
// We override the default SIGINT behavior, insert our "stop-run-loop"
// function call, and then allow this program to finish running and exit
// without any more intervention.
signal(SIGINT, SIG_IGN) // // IGNore
let sigintSrc = DispatchSource.makeSignalSource(
    signal: SIGINT, 
    queue: .main
)
sigintSrc.setEventHandler { // handler: {}
    CFRunLoopStop(runLoop)
    signal(SIGINT, SIG_DFL) // // DeFauLt
}
sigintSrc.resume()

// [Handle SIGTERM]
// By analog to the SIGINT case
signal(SIGTERM, SIG_IGN)
let sigtermSrc = DispatchSource.makeSignalSource(
    signal: SIGTERM, 
    queue: .main
)
sigtermSrc.setEventHandler {
    CFRunLoopStop(runLoop)
    signal(SIGTERM, SIG_DFL)
}
sigtermSrc.resume()