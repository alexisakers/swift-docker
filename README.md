![swift-docker](assets/logo.jpg)

![License](https://img.shields.io/badge/Licence-MIT-000000.svg)
[![Twitter : @leksantoine](https://img.shields.io/badge/Twitter-%40leksantoine-6C7A89.svg)](https://twitter.com/leksantoine)

`swift-docker` is a collection of [Docker](https://docker.com/) images that include Swift, plus other libraries & developer tools.

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

These images come with several commonly used libraries and binaries. Among other features, they have `libcurl` with HTTP/2 support, which means you can use them to send push notifications with server-side Swift OOTB (see [vapor-apns](https://github.com/matthijs2704/vapor-apns)).

For more infos, see :

• [Contents of the 3.0 / 3.0.1 images](docs/1.0-RN.md)

## Using the images

There are several ways these images can be used. Here are two most common :

### Testing Swift on Linux locally

These images offer you a complete build environment to test your Swift programs on Linux.

**1-** Pull an image of your choice using:

```
docker pull aleksaubry/swift-docker:[tag]
```

(replace `[tag]` with the tag of the image you chose)

**2-** Start it with:

```
docker run -ti -v [local directory]:/data aleksaubry/swift-docker:[tag] /bin/bash
```

Use the `-v [local directory]:/data` flag to bind a directory on your local machine (host) to the `/data` volume on the container. This enables you to save data between runs.

_Done!_

**Important** : If you want to use the Swift REPL, you have to start the container with special privileges using the `--privileged=true` flag.

### Using them as a source image for your custom containers

You can use these images as the source image in your own Dockerfiles. Simply choose a version and add this line:

```
FROM aleksaubry/swift-docker:[tag]
```

This allows you to quickly create containers for Swift, which can be useful with Heroku deployment or CI for instance.

## The Dockerfiles

The Dockerfiles have been generated dynamically using a [Swift script](swift-docker.swift) and a [manifest file](manifest.json). 
If you want to try it, simply compile the script's source file and run :

```
./swift-docker
```

This writes the Dockerfiles in the `./Dockerfiles` directory and builds each image specified in the manifest.

**Note:** The `-u` flag is used internally to tag the image with my DockerHub repo name. You don't have to use it.

To learn how the manifest works, see the [build manifest reference](docs/Manifest.md).

## Contributing

Feel free to contribute to the project! You can for instance suggest new packages to include, new platforms or even improve the build script :)

_Enjoy!_ 🐳