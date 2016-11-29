/*
 * ==---------------------------------------------------------------------------------==
 *
 *  File            :   MakeCommand.swift
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
 */

import Foundation
import Console
import PathKit
import Unbox

///
/// A command to build Docker images.
///

public class Make: Command {

    public var id: String = "make"

    public var signature: [Argument] = [
        Option(name: "manifest", help: ["The path to the build manifest.", "Default: ./manifest.json"]),
        Option(name: "user", help: ["An optional DockerHub username to tag the images with."]),
        Option(name: "deploy", help: ["Deploy the images once they're built."])
    ]

    public var help: [String] = [
        "Builds Docker images."
    ]

    public var console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console =  console
    }

    public func run(arguments: [String]) throws {

        let processBar = start("🔎  Processing Context")

        // 1- Read arguments

        let userName = arguments.options["user"]?.string
        var manifestPath = Make.defaultManifestPath

        if let customManifestPath = arguments.options["manifest"]?.string {
            manifestPath = Path(customManifestPath).absolute()
        }

        let templatePath = Path.current + Path("DockerfileTemplate")
        let scriptsPath = Path.current + Path("build_scripts")

        let shouldDeploy = arguments.flag("deploy")

        // 2- Check context

        guard manifestPath.exists else {
            fail(processBar)
            throw MakeError.noManifest(manifestPath.description)
        }

        guard templatePath.exists else {
            fail(processBar)
            throw MakeError.noTemplate(templatePath.description)
        }

        guard scriptsPath.exists else {
            fail(processBar)
            throw MakeError.noBuildScripts
        }

        // 3- Read manifest

        guard let manifestData = try? manifestPath.read() else {
            fail(processBar)
            throw MakeError.invalidManifest
        }

        let manifest: BuildManifest

        do {
            manifest = try unbox(data: manifestData)
        } catch {
            fail(processBar)
            throw MakeError.invalidManifest
        }

        // 4- Load template

        guard let dockerfileTemplateFile: String = try? templatePath.read() else {
            fail(processBar)
            throw MakeError.cannotReadTemplate
        }

        var dockerfileTemplate = [String]()

        dockerfileTemplateFile.enumerateLines { (line, _) in
            dockerfileTemplate.append(line)
        }

        // 5- Prepare the build environment

        let dockerfilesDirectory = Path.current + Path(".docker-build")

        if dockerfilesDirectory.exists {
            try? dockerfilesDirectory.delete()
        }

        do {
            try dockerfilesDirectory.mkdir()
        } catch {
            fail(processBar)
            throw MakeError.cannotCreateBuildDirectory
        }

        finish(processBar)

        let buildTasks = manifest.targets.map { self.buildTasks(for: $0, owner: userName) }.reduce([BuildTask]()) { $0 + $1 }

        let description = shouldDeploy ? "Building and deploying" : "Building"
        let s = buildTasks.count > 0 ? "s" : ""
        console.info("📦  \(description) \(buildTasks.count) Docker image\(s)...")

        // 6- Build the images"

        for buildTask in buildTasks {

            let buildBar = start("🛠  Building \(buildTask.imageName)")

            let dockerfile = TemplateRenderer.render(dockerfileTemplate, context: buildTask.context)
            let dockerfilePath = dockerfilesDirectory + Path("Dockerfile-\(buildTask.name)")

            do {
                try dockerfilePath.write(dockerfile)
            } catch {
                fail(buildBar)
                throw MakeError.cannotWriteDockerile(dockerfilePath.description)
            }

            do {

                let buildArguments = self.buildArguments(for: buildTask, dockerfilePath: dockerfilePath)
                _ = try execute(program: "docker", arguments: buildArguments)

                finish(buildBar)

            } catch {
                fail(buildBar)
                throw MakeError.imageBuildError(error)
            }

            if shouldDeploy {

                let deployBar = start("📤  Deploying \(buildTask.imageName)")

                do {

                    let deployArguments = ["push", buildTask.imageName]
                    _ = try execute(program: "docker", arguments: deployArguments)

                    finish(deployBar)

                } catch {
                    fail(deployBar)
                    throw MakeError.imageDeployError(error)
                }

            }

        }

        // 7- Cleanup

        try? dockerfilesDirectory.delete()

        print("✅  Done!")
        print("🐳  Enjoy using your Docker images!")

    }

}

// MARK: - Factory

extension Make {

    static var defaultManifestPath: Path {
        return Path.current + Path("manifest.json")
    }

    ///
    /// Determines the build tasks for a target.
    ///

    func buildTasks(for target: Target, owner: String?) -> [BuildTask] {

        return target.platforms.map {

            let taskName = "swift-docker:\($0.name)-\(target.versionCode)"
            let imageName = owner != nil ? "\(owner!)/\(taskName)" : taskName

            let tarballPathLhs = "swift-" + target.swiftVersion.lowercased()
            let tarballPathRhs = $0.os + $0.version.major + $0.version.minor
            let tarballPath = [tarballPathLhs,tarballPathRhs].joined(separator: "/")

            let swiftPlatform = $0.os + $0.version.major + "." + $0.version.minor

            let scripts = target.buildScripts.map {
                TemplateRenderer.render(buildScriptTemplate, context: [.scriptFile:$0])
            }

            let context: [TemplateToken:TemplateValueConvertible] = [
                .image: $0.sourceImageTag,
                .swiftVersion: target.swiftVersion,
                .swiftVersionCode: target.versionCode,
                .swiftTarballPath: tarballPath,
                .swiftPlatform: swiftPlatform,
                .buildScripts: scripts
            ]

            return (taskName,imageName,context)

        }

    }

    func buildArguments(for buildTask: BuildTask, dockerfilePath: Path) -> [String] {

        let base = [
            "build",
            ".",
            "--no-cache",
            "--rm",
            "--pull",
            "-t",
            buildTask.imageName,
            "-f",
            "\(dockerfilePath)"
        ]

        #if RELEASE
            return base + ["--quiet"]
        #else
            return base
        #endif

    }

}

// MARK: - Console I/O

extension Make {

    func start(_ task: String) -> LoadingBar {

        let bar = console.loadingBar(title: task)

        #if DEBUG
            console.print(task)
        #else
            bar.start()
        #endif

        return bar

    }

    func finish(_ bar: LoadingBar) {

        #if DEBUG
            console.info("[Done]")
        #else
            bar.finish()
        #endif

    }

    func fail(_ bar: LoadingBar) {

        #if DEBUG
            console.error("[Failed]")
        #else
            bar.fail()
        #endif

    }

    func execute(program: String, arguments: [String]) throws -> String? {

        #if DEBUG
            try console.foregroundExecute(program: program, arguments: arguments)
            return nil
        #else
            return try console.backgroundExecute(program: program, arguments: arguments)
        #endif

    }

}
