![swift-docker](assets/logo.jpg)

[![View on DockerHub](https://img.shields.io/badge/Project%20Page-Docker%20Hub-1A273B.svg)](https://hub.docker.com/r/aleksaubry/swift-docker)
[![The MIT License](https://img.shields.io/badge/Licence-MIT-000000.svg)](LICENSE)
[![Twitter : @leksantoine](https://img.shields.io/badge/Twitter-%40leksantoine-6C7A89.svg)](https://twitter.com/leksantoine)

`SwiftDocker` is an automation tool that builds [Docker](https://docker.com/) images with Swift, plus other libraries & developer tools.

## Images

### Swift 3.0.1

| OS           | Image Tag                            |
|--------------|--------------------------------------|
| Ubuntu 16.04 | aleksaubry/swift-docker:xenial-3.0.1 |
| Ubuntu 15.10 | aleksaubry/swift-docker:wily-3.0.1   |
| Ubuntu 14.04 | aleksaubry/swift-docker:trusty-3.0.1 |

### Swift 3.0

| OS           | Image Tag                          |
|--------------|------------------------------------|
| Ubuntu 15.10 | aleksaubry/swift-docker:wily-3.0   |
| Ubuntu 14.04 | aleksaubry/swift-docker:trusty-3.0 |

## Features

These images come with several commonly used libraries and binaries. Among other features, they include `libcurl` with HTTP/2 support, which means you can use them to send push notifications with server-side Swift OOTB (see [vapor-apns](https://github.com/matthijs2704/vapor-apns)).

For more infos, see :

• [Contents of the images](docs/Contents.md)

## Usage

There are several ways these images can be used. Here are two most common :

### Testing Swift on Linux locally

The images offer you a complete build environment to test open-source Swift on Linux.

**1-** Pull the image of your choice using:

```
docker pull aleksaubry/swift-docker:[tag]
```

(replace `[tag]` with the tag of the image you chose)

**2-** Start it with:

```
docker run -ti -v [local directory]:/data aleksaubry/swift-docker:[tag] /bin/bash
```

Use the `-v [local directory]:/data` flag to bind a directory on your local machine to the `/data` volume on the container. This enables you to save data between runs.

_Done!_

**Important** : If you want to use the Swift REPL, you have to start the container with special privileges using the `--privileged=true` flag.

### Using them as a base image for your custom containers

You can use one of the images as the base image for your own Docker container. Simply choose a version and add this line to your `Dockerfile`:

```
FROM aleksaubry/swift-docker:[tag]
```

This allows you to quickly create containers for executing Swift programs, which can be useful for Heroku deployment or CI/CD for instance.

## Automation tool?

At the heart of this project is the `SwiftDocker` program. It's a Swift package that automates the creation of every Dockerfile. It also launches the build and deploy tasks.

It uses a `manifest.json` file to create these tasks. You can check its [format reference](docs/Manifest.md).

### Usage

If you want to build the images locally, or build your own, follow theses steps:

**1-** Compile the program

```
swift build -c [config] -Xswiftc -D[mode]
```

Replace [config;mode] with `debug;DEBUG` to use debug mode (preferred in low memory conditions) or with `release;RELEASE` to use release mode (fails with <8GB RAM).

**2-** Build the image

```
./.build/[config]/DockerToolbox make
```

You can use the `--manifest=path/to/custom/manifest.json` flag to use a manifest that is not in the working directory.

*Note:* The `--user` and the `--deploy` flags are for internal use only.

## Contributing

Contributions are more than welcome! You can for instance suggest new packages to include, new platforms or even improve the build script :)

## Acknowledgements

These open-source projects made `SwiftDocker` possible:

- [Console](https://github.com/vapor/console) by @vapor
- [Unbox](https://github.com/johnsundell/unbox) by @JohnSundell
- [PathKit](https://github.com/kylef/PathKit) by @kylef

A big thanks to you all!

🐳
