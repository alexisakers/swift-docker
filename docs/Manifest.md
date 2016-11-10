# The Build Manifest Reference

The build script uses a JSON manifest to generate and build the images. The `manifest.json` must be placed at the root of the working directory.

## Platforms

The manifest must contain a list of platform objects. A platform is a single version of an OS for which a Docker image will be created.

This list must be defined with the `"platforms"` key.

### The `Platform` object

| Key           | Type             | Description                                                                                    |
|---------------|------------------|------------------------------------------------------------------------------------------------|
| `name`        | String           | The friendly name of the platform                                                              |
| `version`     | `Version` object | The numeric version of the platform                                                            |
| `image_tag`   | String           | The tag of the Docker image to use to build the Swift image                                    |
| `os`          | String           | The lowercased name of the OS, as spelled on the [swift.org](https://swift.org) downloads page |

### The `Version` object

| Key     | Type   | Description                              |
|---------|--------|------------------------------------------|
| `major` | String | The major release number of the platform |
| `minor` | String | The minor release number of the platform |

#### Example

This JSON object represents the Ubuntu 16.04 platform :

```json
{
    "name": "xenial",
    "version": {
        "major": "16",
        "minor": "04"
    },
    "image_tag": "ubuntu:16.04",
    "os": "ubuntu"
}
```

## Targets

The manifest must contain a list of target objects. A target represents the content of a Docker image to build.

This list must be defined with the `"targets"` key.

### The `Target` object

| Key             | Type             | Description                                                                                                                           |
|-----------------|------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| `swift_version` | String           | The full name of the Swift toolchain to install.                                                                                      |
| `version_code`  | String           | The Swift version number.                                                                                                             |
| `platforms`     | Array of Strings | A list of platform names for which an image will be created. Each value must be a reference to a platform in the `"platforms"` array. |
| `build_scripts` | Array of Strings | A list of shell scripts to run when building the image. Each script must be contained in the `build_scripts` directory.               |

#### Example

This JSON object represents a build target for Swift 3.0 that will be installed on Ubuntu 15.0 : 

```json
{
    "swift_version": "3.0-RELEASE",
    "version_code": "3.0",
    "platforms": [
        "wily"
    ],
    "build_scripts": [
        "apt.sh",
        "curl.sh",
        "swift.sh"
    ]
}
```

## Example Build

This is an example build manifest :

```json
{    
    "platforms": [
        {
            "name": "xenial",
            "version": {
                "major": "16",
                "minor": "04"
            },
            "image_tag": "ubuntu:16.04",
            "os": "ubuntu"
        },
        {
            "name": "wily",
            "version": {
                "major": "15",
                "minor": "10"
            },
            "image_tag": "ubuntu:15.10",
            "os": "ubuntu"
        },
        {
            "name": "trusty",
            "version": {
                "major": "14",
                "minor": "04"
            },
            "image_tag": "ubuntu:14.04",
            "os": "ubuntu"
        }
    ],
    "targets": [
        {
            "swift_version": "3.0-RELEASE",
            "version_code": "3.0",
            "platforms": [
                "wily",
                "trusty"
            ],
            "build_scripts": [
                "apt.sh",
                "curl.sh",
                "swift.sh"
            ]
        },
        {
            "swift_version": "3.0.1-RELEASE",
            "version_code": "3.0.1",
            "platforms": [
                "xenial",
                "wily",
                "trusty"
            ],
            "build_scripts": [
                "apt.sh",
                "curl.sh",
                "swift.sh"
            ]
        }
    ]
}
```