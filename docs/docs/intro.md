---
sidebar_position: 1
sidebar_label: Get started
title: Get started
---

Dartseid is a no-magic framework for building scalable and flexible backends in Dart. What do we mean by "no-magic"?
This means that there is no code generation required to run a Dartseid application. Though code generation is not
discouraged, it is not required. This allows you to use Dartseid in any way you want, without code genration being
forced upon you.

## Installation

Dartseid comes with its own CLI tool, which can be installed using the following command:

```sh
dart pub global activate dartseid_cli
```

## Creating a new project

To create a new project, run the following command:

```sh
dartseid create my_app
```

This will create a new project in the `my_app` directory. You can then `cd` into the directory and run the following
command to start the server:

```sh
dartseid serve
```

You can now head to `http://localhost:7331` to see your application running.
