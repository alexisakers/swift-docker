/*
 * ==---------------------------------------------------------------------------------==
 *
 *  File            :   swift-docker.swift
 *  Project         :   swift-docker
 *  Author          :   ALEXIS AUBRY RADANOVIC
 *
 *  License         :   The MIT License (MIT)
 *
 * ==---------------------------------------------------------------------------------==
 *
 *	The MIT License (MIT)
 *	Copyright (c) 2016 ALEXIS AUBRY RADANOVIC
 *
 *	Permission is hereby granted, free of charge, to any person obtaining a copy of
 *	this software and associated documentation files (the "Software"), to deal in
 *	the Software without restriction, including without limitation the rights to
 *	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 *	the Software, and to permit persons to whom the Software is furnished to do so,
 *	subject to the following conditions:
 *
 *	The above copyright notice and this permission notice shall be included in all
 *	copies or substantial portions of the Software.
 *
 *	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 *	FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 *	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 *	IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 *	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * ==---------------------------------------------------------------------------------==
 *
 * This script generates Dockerfiles and builds images as specified in the
 * manifest.json file.
 *
 * This allows us to create multiple images for multiple OSes with only one command.
 *
 * Usage :
 * 1. Update the manifest if needed (see docs/Manifest.md)
 * 2. Compile this file (`swiftc swift-docker.swift`)
 * 3. Run `./swift-docker` 
 * 4. Done! 
 *
 * ==---------------------------------------------------------------------------------==
 */

import Foundation

// MARK: - Types

///
/// A platform where Swift will be built.
///

struct Platform {
    
    /// The codename of the platform.
    var name: String
    
    /// The version of the platform.
    var version: (major: String, minor: String)
    
    /// The tag of the Docker image to use for the `FROM` declaration.
    var baseImageTag: String
    
    /// The name of the OS (Ubuntu, macOS, ...)
    var os: String
}

///
/// An image creation job. 
///

struct Target {
    
    /// The version of Swift to bundle in the images.
    var swiftVersion: String
    
    /// The version number of Swift.
    var versionCode: String
    
    /// The names of the platforms Swift will be installed onto.
    var platforms: [String]
    
    /// The name of the .sh scripts to run when building the image. These files must exist in the ./build_scripts/ directory
    var buildScripts: [String]
    
}

///
/// The items to create a specialized Dockerfile.
///

enum DockerfileTemplateItem: String {
    
    /// The image to use to build the template.
    case sourceImage = "image"
    
    /// The long version of Swift to include in the image.
    case swiftVersion = "swift_version"
    
    /// The short numeric version of Swift to include in the image.
    case swiftVersionCode = "swift_version_code"
    
    /// The 
    case swiftTarballPath = "swift_tarball_path"
    case swiftPlatform = "swift_platform"
    case buildScripts = "build_scripts"
    
}

///
/// The paths to the files used by the script.
///

struct FilesPath {
    
    private init() {}
    
    /// The build manifest.
    static let manifest = "manifest.json"
    
    /// The reusable Dockerfile template.
    static let dockerfileTemplate = "Dockerfile.template"
    
    /// The directory that contains all the generated Dockerfiles.
    static let dockerfilesDirectory = "Dockerfiles/"
    
}

// MARK: - Helper Functions

/*----- Safe APIs -----*/

extension String {
    
    func replacingOccurrences(of templateItem: DockerfileTemplateItem, with newValue: String) -> String {
        let searchQuery = "{{" + templateItem.rawValue + "}}"
        return self.replacingOccurrences(of: searchQuery, with: newValue)
    }
    
}

/*----- PATH -----*/

///
/// Returns the path to the working directory.
///

func workingDirectory() -> String? {
    guard let pwd = getenv("PWD") else { return nil }
    return String(utf8String: pwd)?.appending("/") ?? nil
}

///
/// Returns the path to the build manifest (manifest.json).
///

func manifestPath() -> String? {
    guard let workingDirectory = main.workingDirectory() else { return nil }
    return workingDirectory  + FilesPath.manifest
}

///
/// Returns the path to the shared Dockerfile template (Dockerfile.template).
///

func dockerfileTemplatePath() -> String? {
    guard let workingDirectory = main.workingDirectory() else { return nil }
    return workingDirectory + FilesPath.dockerfileTemplate
}

///
/// Returns the path to the directory where the Dockerfiles will be written (./Dockerfiles)
///

func dockerfilesDirectoryPath() -> String? {
    guard let workingDirectory = main.workingDirectory() else { return nil }
    return workingDirectory + FilesPath.dockerfilesDirectory
}

/*----- TOOLS -----*/

///
/// Displays a welcome message.
///

func hello() {
    
    print("* ==---------------------------------------------------------------------------------== *")
    print("*                                                                                       *")
    print("*  SWIFT-DOCKER by ALEXIS AUBRY RADANOVIC                                               *")
    print("*  Easily create Docker images with Swift                                               *")
    print("*                                                                                       *")   
    print("* ==---------------------------------------------------------------------------------== *")
    print("\n")
    
}

///
/// Creates a result table to include in a README.
///

func tables(for platforms: [Platform], targets: [Target]) -> [String] {
    
    var tables = [String]()
    
    for target in targets {
        
        let sectionHeader = "### Swift \(target.versionCode)\n"
        let tableHeader = "\n| OS | Image Tag |\n"
        
        let targetPlatformsLines: [String] = target.platforms.flatMap {
            
            let name = $0
            
            guard let platform = platforms.first(where: { $0.name == name }) else {
                return nil
            }
            
            let osName = platform.os.capitalized
            let versionString = platform.version.major + "." + platform.version.minor
            let osRowText = osName + " " + versionString
            
            let tagRowText = "swift-docker:" + platform.name + "-" + target.versionCode
            
            return "| " + osRowText + " | " + tagRowText + " |"
            
        }
        
        let table = sectionHeader + tableHeader + targetPlatformsLines.joined(separator: "\n") + "\n"
        tables.append(table)
        
    }
    
    return tables
    
}

/*----- RUNTIME -----*/

///
/// Reads the contents of the manifest.json file.
///
/// - returns: A dictionary representation of the manifest.
///

func readManifest() -> [String:Any] {
    
    print("-----> Reading the manifest...")
    
    guard let manifestPath = manifestPath() else {
        print("-----> Could not determine the path to the manifest. Exiting.")
        exit(1)
    }

    guard let manifestData = try? NSData(contentsOfFile: manifestPath, options: []) else {
        print("-----> Could not read the manifest. Exiting.")
        exit(2)
    }

    guard let manifestJSON = try? JSONSerialization.jsonObject(with: manifestData as Data) else {
        print("-----> The specified manifest is not a valid JSON file. Exiting.")
        exit(2)
    }

    guard let manifest = manifestJSON as? [String:Any] else {
        print("-----> The specified manifest is not a valid JSON file. Exiting.")
        exit(2)
    }
    
    print("-----> Done! (using: \(manifestPath))")
    
    return manifest
    
}

///
/// Extracts the platforms where the Docker containers will be built.
///
/// - parameter manifest: The manifest that contains the platforms.
///
/// - returns: An array of platforms.
///

func readPlatforms(in manifest: [String:Any]) -> [Platform] {
    
    print("-----> Reading the platforms...")
    
    guard let platformsArray = manifest["platforms"] as? [[String:Any]] else {
        print("-----> The specified manifest does not contain a list of compatible platforms. Exiting.")
        exit(2)
    }
    
    let platforms: [Platform] = platformsArray.flatMap {
        
        guard let name = $0["name"] as? String else {
            print("-----> The platform \($0) does not have a name. Omiting.")
            return nil
        }
        
        guard let baseImageTag = $0["image_tag"] as? String else {
            print("-----> The platform \($0) does not have a tag. Omiting.")
            return nil
        }
        
        guard let versionInfo = $0["version"] as? [String:String] else {
            print("-----> The platform \($0) does not have version info. Omiting.")
            return nil
        }
        
        guard let majorVersion = versionInfo["major"] else {
            print("-----> The platform \($0) does not have a major version. Omiting.")
            return nil
        }
        
        guard let minorVersion = versionInfo["minor"] else {
            print("-----> The platform \($0) does not have a minor version. Omiting.")
            return nil
        }

        guard let os = $0["os"] as? String else {
            print("-----> The platform \($0) does not have an OS. Omiting.")
            return nil
        }

        return Platform(name: name, version: (majorVersion,minorVersion), baseImageTag: baseImageTag, os: os)
        
    }

    guard platforms.count > 0 else {
        print("----> No platforms to build the images on. Exiting.")
        exit(3)
    }

    print("-----> Done! (found \(platforms.count) platforms)")

    return platforms
    
}

///
/// Extracts the build jobs to execute.
///
/// - parameter manifest: The manifest that contains the targets.
///
/// - returns: An array of targets.
///

func readTargets(in manifest: [String:Any]) -> [Target] {
    
    print("-----> Reading the build targets...")
    
    guard let targetsArray = manifest["targets"] as? [[String:Any]] else {
        print("-----> The specified manifest does not contain a list of build targets. Exiting.")
        exit(3)
    }

    let targets: [Target] = targetsArray.flatMap {
        
        guard let swiftVersion = $0["swift_version"] as? String else {
            print("-----> The target \($0) does specify a Swift version. Omiting.")
            return nil
        }

        guard let versionCode = $0["version_code"] as? String else {
            print("-----> The target \($0) does specify a Swift version code. Omiting.")
            return nil
        }
        
        guard let platforms = $0["platforms"] as? [String] else {
            print("-----> The target \($0) does specify a list of target platforms. Omiting.")
            return nil
        }
            
        guard let buildScripts = $0["build_scripts"] as? [String] else {
            print("-----> The target \($0) does specify a list of build scripts. Omiting.")
            return nil
        }
        
        return Target(swiftVersion: swiftVersion, versionCode: versionCode, platforms: platforms, buildScripts: buildScripts)
        
    }
    
    guard targets.count > 0 else {
        print("----> No targets to build. Exiting.")
        exit(4)
    }
    
    print("----> Done! (found \(targets.count) Swift versions)")

    return targets
    
}

///
/// Associates each Swift version with every OS where it will be installed.
///
/// - returns: A list of platform/target couples.
///

func createBuildJobs(with platforms: [Platform], and targets: [Target]) -> [(platform: Platform, target: Target)] {
    
    print("----> Processing build context...")
    
    var buildJobs = [(platform: Platform, target: Target)]()
    
    for target in targets {
        
        let destinations: [Platform] = target.platforms.map {
                
            let name = $0
            guard let platform = platforms.first(where: { $0.name == name }) else {
                print("-----> Could'nt find a platform named '\(name)'. Exiting.")
                exit(5)
            }
                
            return platform
                
        }

        let jobs: [(platform: Platform, target: Target)] = destinations.map { ($0, target) }
        buildJobs += jobs
        
    }
    
    guard buildJobs.count > 0 else {
        print("Error : no build jobs found")
        exit(2)
    }
    
    print("----> Done! (found \(buildJobs.count) tasks)")
    
    return buildJobs
    
}

///
/// Executes a list of build jobs.
///
/// - parameter buildJobs: The build jobs to execute.
///

func execute(_ buildJobs: [(platform: Platform, target: Target)]) {
    
    print("----> Preparing to execute \(buildJobs.count) build jobs...")
    
    guard let templatePath = dockerfileTemplatePath() else {
        print("----> Could not determine the path to the Dockerfile template. Exiting.")
        exit(6)
    }

    guard let template = try? String(contentsOfFile: templatePath) else {
        print("----> Could not read the Dockerfile template. Exiting.")
        exit(7)
    }
    
    guard let dockerfilesDirectoryPath = dockerfilesDirectoryPath() else {
        print("----> Could not determine the path to the Dockerfiles directory. Exiting.")
        exit(8)
    }
    
    for buildJob in buildJobs {
        let creationResult = createDockerfile(for: buildJob, with: template, outputDirectory: dockerfilesDirectoryPath)
        buildImage(withDockerfilePath: creationResult.path, name: creationResult.name)
    }
    
}

///
/// Creates a Dockerfile for a build job.
///
/// - returns: The path to the Dockerfile and the name of the image.
///

func createDockerfile(for buildJob: (platform: Platform, target: Target), with template: String, outputDirectory: String) -> (path: String, name: String) {
        
    do {
        
        let platform = buildJob.platform
        let target = buildJob.target
        
        let name = "\(platform.name)-\(target.versionCode)"
        print("----> Writing \(name)...")
        
        let targetDirectoryPath = outputDirectory + name
        try FileManager.default.createDirectory(atPath: targetDirectoryPath, withIntermediateDirectories: true)
        
        let tarballPath = "swift-" + target.swiftVersion.lowercased() + "/" + platform.os + platform.version.major + platform.version.minor
        let swiftPlatform = platform.os + platform.version.major + "." + platform.version.minor
        let scripts = target.buildScripts.map { "RUN sh /build_scripts/" + $0 }.joined(separator: "\n") 
        
        let dockerfile = template
            .replacingOccurrences(of: .sourceImage, with: platform.baseImageTag)
            .replacingOccurrences(of: .swiftVersion, with: target.swiftVersion)
            .replacingOccurrences(of: .swiftVersionCode, with: target.versionCode)
            .replacingOccurrences(of: .swiftTarballPath, with: tarballPath)
            .replacingOccurrences(of: .swiftPlatform, with: swiftPlatform)
            .replacingOccurrences(of: .buildScripts, with: scripts)
        
        guard let dockerfileData = dockerfile.data(using: .utf8) else {
            print("----> Could not determine the path to the Dockerfiles directory. Exiting.")
            exit(8)
        }
        
        let path = targetDirectoryPath + "/Dockerfile"
        guard FileManager.default.createFile(atPath: path, contents: dockerfileData) else {
            print("----> Could not write the Dockerfile \(name). Exiting.")
            exit(9)
        }
        
        return (path,name)
        
    } catch {
        print("----> Error when writing a Dockerfile (error: \(error)).")
        exit(10)
    }

}

///
/// Builds a Docker image.
///
/// - parameter dockerfilePath: The path to the Dockerfile to use to build the image.
/// - parameter name: The name of the Docker image.
///
/// - warning: If you decide to kill this script, make sure to kill the `docker build` child process (`ps -ax | grep "docker build".

func buildImage(withDockerfilePath dockerfilePath: String, name: String) {
    
    let args = CommandLine.arguments
    let user: String
    
    if let index = args.index(of: "-u"), index + 1 < args.count {
        user = args[index + 1]
    } else {
        user = ""
    }
    
    let tag = "\(user)/swift-docker:\(name)"
    
    print("----> Starting to build \(tag)...")
    
    let process = Process()
    process.launchPath = "/bin/bash"
    process.arguments = [
        "-c",
        "docker build . -f \(dockerfilePath) --no-cache -q -t \(tag)"
    ]
    
    process.terminationHandler = {
        
        guard $0.terminationStatus == 0 else {
            print("----> Error \($0.terminationStatus) while compiling \(tag). Exiting")
            exit(11)
        }
        
        print("----> Successfully built \(tag)")
        
    }
    
    process.launch()
    process.waitUntilExit()
    
}

// MARK: - Main

hello()

let manifest = readManifest()
let platforms = readPlatforms(in: manifest)
let targets = readTargets(in: manifest)

let buildJobs = createBuildJobs(with: platforms, and: targets)
execute(buildJobs)

print("\n✅   Recap :")

let recap = tables(for: platforms, targets: targets).joined(separator: "\n")
print(recap)

print("Enjoy using your Docker Images! 🐳")
