import ArgumentParser
import Foundation
 
@main
struct CodeCoverageParser: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Parses a code coverage json file generated by xcov, formats it in the mardown format and writes to a file at a specified path",
        version: "0.0.1"
    )
    
    @Option(help: "input file path of the json to be parsed")
    var input: String
    
    @Option(help: "output file path for the markdown")
    var output: String
    
    mutating func run() throws {
        let jsonFileURL = URL(fileURLWithPath: input)
        let jsonData = try Data(contentsOf: jsonFileURL)
        let codeCoverage = try JSONDecoder().decode(CodeCoverage.self, from: jsonData)
        var outputString = """
        
        ## Unit test coverage result
        Target | Percentage
        --- | --- \n
        """
        for targetCoverage in codeCoverage.targetCodeCoverages {
            if let coveragePercent = (targetCoverage.coverage).percent {
                let targetCoverageString = targetCoverage.name + " | " + "\(coveragePercent) \n"
                outputString.append(targetCoverageString)
            }
        }
        
        let outputURL = URL(fileURLWithPath: output)
        try outputString.write(to: outputURL, atomically: true, encoding: .utf8)
    }
}





