/*
 * ==---------------------------------------------------------------------------------==
 *
 *  File            :   Models.swift
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
import Unbox

// MARK: - Models

typealias BuildTask = (name: String, imageName: String, context: [TemplateToken:TemplateValueConvertible])

///
/// The informations to use to build the images.
///

public struct BuildManifest {
    let targets: [Target]
    let platforms: [Platform]
}

///
/// A generic, platform-agnostic definition of a Swift image build job.
///

public struct Target {

    ///
    /// The version of Swift to bundle in the images.
    ///

    public var swiftVersion: String

    ///
    /// The version number of Swift.
    ///

    public var versionCode: String

    ///
    /// The names of the platforms Swift will be installed onto.
    ///

    public var platforms: [Platform]

    ///
    /// The name of the .sh scripts to run when building the image. These files must exist in the ./build_scripts/ directory
    ///

    public var buildScripts: [String]

}

///
/// A platform where Swift can be built.
///

public struct Platform {

    ///
    /// The codename of the platform.
    ///
    /// Example: `xenial` for Ubuntu 16.04
    ///

    public let name: String

    ///
    /// The version of the platform.
    ///

    public let version: Version

    ///
    /// The tag of the Docker image to use for the `FROM` declaration.
    ///

    public let sourceImageTag: String

    ///
    /// The name of the OS (currently only Ubuntu is supported)
    ///

    public let os: String

}

///
/// A generic version.
///

public struct Version {

    ///
    /// The major version number.
    ///

    public let major: String

    ///
    /// The minor version number.
    ///

    public let minor: String

}

// MARK: - Models + Unboxable

extension BuildManifest: Unboxable {

    public init(unboxer: Unboxer) throws {

        let platforms: [Platform] = try unboxer.unbox(key: "platforms")
        self.platforms = platforms

        let targets: [Target] = try unboxer.unbox(key: "targets", context: platforms)
        self.targets = targets

        guard platforms.count > 0 && targets.count > 0 else {
            throw MakeError.invalidManifest
        }


    }

}

extension Target: UnboxableWithContext {

    public init(unboxer: Unboxer, context: [Platform]) throws {

        swiftVersion = try unboxer.unbox(key: "swift_version")
        versionCode = try unboxer.unbox(key: "version_code")

        let platformsList: [String] = try unboxer.unbox(key: "platforms")
        platforms = context.filter { platformsList.contains($0.name) }

        buildScripts = try unboxer.unbox(key: "build_scripts")

    }

}

extension Platform: Unboxable {

    public init(unboxer: Unboxer) throws {

        name = try unboxer.unbox(key: "name")
        version = try unboxer.unbox(key: "version")
        sourceImageTag = try unboxer.unbox(key: "image_tag")
        os = try unboxer.unbox(key: "os")

    }

}


extension Version: Unboxable {

    public init(unboxer: Unboxer) throws {
        major = try unboxer.unbox(key: "major")
        minor = try unboxer.unbox(key: "minor")
    }

}
