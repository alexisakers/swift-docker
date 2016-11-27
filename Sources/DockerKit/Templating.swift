/*
 * ==---------------------------------------------------------------------------------==
 *
 *  File            :   Templating.swift
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

// MARK: - Internal Templates

let buildScriptTemplate = ["RUN sh /build_scripts/{{script_file}}"]

// MARK: - Core

///
/// Placeholders in templates that are escaped using '{{' and '}}'.
///

enum TemplateToken: String {

    ///
    /// The source image.
    ///

    case image = "image"

    ///
    /// The version of Swift to install.
    ///

    case swiftVersion = "swift_version"

    ///
    /// The short code of the Swift version to install.
    ///

    case swiftVersionCode = "swift_version_code"

    ///
    /// The intermediate path to the toolchain tarball.
    ///

    case swiftTarballPath = "swift_tarball_path"

    ///
    /// The name of the platform on which to install Swift.
    ///

    case swiftPlatform = "swift_platform"

    ///
    /// A newline-separated list of the scripts to run.
    ///

    case buildScripts = "build_scripts"

    ///
    /// A script file to use in the `buildScripts`.
    ///

    case scriptFile = "script_file"

}

///
/// A protocol for values that can be used into template rendering contexts.
///

protocol TemplateValueConvertible {

    ///
    /// Creates the value for the template.
    ///

    func makeTemplateValue() -> String

}

// MARK: - Extension

extension Array: TemplateValueConvertible {

    func makeTemplateValue() -> String {
        return self.map { String(describing: $0) }.joined(separator: "\n")
    }

}

extension String: TemplateValueConvertible {

    func makeTemplateValue() -> String {
        return self
    }

}

// MARK: - TemplateRenderer

///
/// Renders templates.
///

struct TemplateRenderer {


    ///
    /// Renders a template.
    ///
    /// A template is an array of strings whose elements repesent a single line.
    /// If this template contains tokens (strings escaped with '{{' and '}}'), they will be replaced using the values from the context.
    ///
    /// - parameter template: The lines composing the template.
    /// - parameter context: The set of replacement values to use to render the template.
    ///
    /// - returns: The rendered template. The original lines will be joined with a newline.
    ///

    static func render(_ template: [String], context: [TemplateToken:TemplateValueConvertible]) -> String {
        return template.map { render(templateLine: $0, context: context) }.joined(separator: "\n")
    }

    ///
    /// Renders a single line of a template.
    ///
    /// This function looks for tokens in the line and replace them with the appropriate values from the context.
    ///
    /// - parameter templateLine: The line to render.
    /// - parameter context: The values to use to render the context.
    ///
    /// - returns: The rendered line.
    ///

    private static func render(templateLine: String, context: [TemplateToken:TemplateValueConvertible]) -> String {

        var renderedLine = templateLine

        while let tokenStartDelimiterRange = renderedLine.range(of: "{{"), let tokenEndDelimiterRange = renderedLine.range(of: "}}") {

            let escapeSequenceRange = tokenStartDelimiterRange.lowerBound ..< tokenEndDelimiterRange.upperBound
            let tokenRange = tokenStartDelimiterRange.upperBound ..< tokenEndDelimiterRange.lowerBound

            let rawToken = renderedLine.substring(with: tokenRange)

            guard let token = TemplateToken(rawValue: rawToken) else {
                continue
            }

            guard let contextValue = context[token] else {
                continue
            }

            let replacementValue = contextValue.makeTemplateValue()
            renderedLine.replaceSubrange(escapeSequenceRange, with: replacementValue)

        }

        return renderedLine

    }

}
