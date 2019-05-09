import Foundation

public class ProcessInvoker
{
    public let output: String
    public let error: String
    public let exitCode: Int32
    public let exitReason: Process.TerminationReason


    static public func run(_ launchPath: String, arguments: [String]) -> ProcessInvoker {
        let result = ProcessInvoker.launch(launchPath, arguments: arguments)
        let process = ProcessInvoker(output: result.output, error: result.error, exitCode: result.exitCode, exitReason: result.exitReason)
        return process
    }

    fileprivate init(output: String, error: String, exitCode: Int32, exitReason: Process.TerminationReason) {
        self.output = output
        self.error = error
        self.exitCode = exitCode
        self.exitReason = exitReason
    }

    static fileprivate func launch(_ launchPath: String, arguments: [String]) -> 
                (output: String, error: String, exitCode: Int32, exitReason: Process.TerminationReason) {
        let launchCompleted = DispatchSemaphore(value: 0)

        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments

        task.terminationHandler = { t in 
            launchCompleted.signal()
        }

        var outputData = Data()
        let stdoutHandler: (FileHandle) -> Void = { handler in
            outputData.append(handler.availableData)
        }

        var errorData = Data()
        let stderrHandler: (FileHandle) -> Void = { handler in 
            errorData.append(handler.availableData)
        }

        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.readabilityHandler = stdoutHandler

        let errorPipe = Pipe()
        task.standardError = errorPipe
        errorPipe.fileHandleForReading.readabilityHandler = stderrHandler

        // This executable may depend on another executable in the same folder - make sure the path includes the executable folder
        task.environment = ["PATH": (launchPath as NSString).deletingLastPathComponent]

        task.launch()
// task.waitUntilExit()
        launchCompleted.wait()


        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil

        let output = String(data: outputData, encoding: String.Encoding.utf8) ?? ""
        let error = String(data: errorData, encoding: String.Encoding.utf8) ?? ""
        return (output, error, task.terminationStatus, task.terminationReason)
    }
}
