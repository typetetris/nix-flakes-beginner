nix-flakes-beginner
===================

This little flake should make it easier to play around with nix flakes
for beginners. We will try to keep that pratical, so we don't get
bogged down in technical nix obscura.

A little warning at the start:

> :warning: **Don't directly use `nix profile` it might render your profile unusable with `nix-env` later.** You can start using it later, when you feel comfortable with the new UI.

It assumes you have [nix](https://nixos.org) installed somehow.

To get started, clone the repository and call `nix-shell`
while having its toplevel directory as your working directory
of your shell.

For example a session start could look like that:

```
cd ~/repos
git clone https://github.com/typetetris/nix-flakes-beginner
cd nix-flakes-beginner
nix-shell
```

That drops you in a shell with a recent nix in your PATH,
which is suitable wrapped to allow you to explore nix new
UI directly without having to setup anything else.

For example you could start with `nix flake --help` to read
some starting manual page about nix flakes.

Gettings started with flakes
----------------------------

To get started with flakes, we will simply create some trivial ones now. After that,
we will analyse the `flake.nix` of this repository.

First enter the nix shell as described above and create a new directory somewhere, where
you like. And initialise a git repository there. Flakes usually reside in a git repository.

For me, the commands looked like that:

```
cd ~/repos/nix-flakes-beginner
nix-shell
cd ~/playground
mkdir first-flake
git init
```

Now lets create our first flake. In your shiny new repository create
a file named `flake.nix` with the following content.

```
{}
```

Yep. It is that short.

Now we try to look at, what we have done. It should not work!

Enter the following command:

```
nix flake show
```

You should get an error message like the following one:

```
error: getting status of '/nix/store/0ccnxa25whszw7mgbgyzdm4nqc0zwnm8-source/flake.nix': No such file or directory
```

This means, that nix thinks your flake doesn't contain a file named `flake.nix`. The reason for that is, that nix flake only consider files, which are known to the git repository, which the flake inhabitants. So let's add the `flake.nix` file:

```
git add flake.nix
```

We don't need to commit it, staging it should be sufficient.

Now we can repeat the `nix flake show` command and see it fail again. Your error message
should have changed to something like:

```
error: flake 'git+file:///home/typetetris/playground/first-flake' lacks attribute 'outputs'
```

and a warning about our git repository being dirty. You can ignore these for now.

So `{}` wasn't quite enough for trivial flake.

So change the contents of your `flake.nix` file to

```
{
  outputs = {self, ...}: {
  };
}
```

If you now repeat `nix flake show` you get an output like:

```
git+file:///home/typetetris/playground/first-flake
```

and that is it. There is not much to show, as our flake doesn't declare anything
yet. But let's take a look at it.

1. It looks like a normal attribute set.
2. It defines an attribute with the name `output`, which has a function for its value.

The function, which is the value for the attribute named `output`, maps inputs of the flake
to its outputs. At the moment, the only input we know is `self`, which represents the flake
we are writing itself.

To write a more meaningful flake, we need some inputs. There are ways to access certain inputs
without declaring them, but we will not delve on that now. We will explicitly declare the
inputs we need.

Lets use `nixpkgs` in our flake.

Change the content of our `flake.nix` to the following:

```
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = {
    self,
    nixpkgs,
    ...
  }: {
  };
}
```

Let's analyse that a bit.

We got this new line:

```
inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
```

So there is an attribute named `inputs` with another attribute set
as its value. The attribute set, which is the value of the attribute
`inputs` contains an attribute for each input we want to use.
The name of the attribute is a symbolic name, we use, to refer to the
specified input. The value of the attribute, here named `nixpkgs`,
is an attribute set describing the input.

For now it just contains an attribute `url` with a string value.
The value of the `url` attribute is a flake reference, which happens
to have the syntax of an url.

There are a some different types of flake references, but we will
only use the `github` one for now. The basic syntax of a `github` type
flake reference is

```
github:<owner>/<repository>[/<rev>]

```

The specified git repository must contain a `flake.nix` file,
which will be used to learn about the contents of the specified
input.

Also we added the identifier `nixpkgs` to the arguments of our
`outputs` function.

The name `nixpkgs` in this case doesn't bear special meaning. It
is just a way to refer to the specified input. We could have written

```
{
  inputs.rock.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = {
    self,
    rock,
    ...
  }: {
  };
}
```

just as well and used the identifier `rock` to refer to the
`nixpkgs` input. But that would have been pretty confusing.

If you run `nix flake show` again, you should get, besides the
output we already know, the following warning:

```
warning: creating lock file '/home/typetetris/playground/first-flake/flake.lock'
```

Here nix told us, it created a `flake.lock` file for us. Curious as we are,
we take a look inside. The contents of `flake.lock` while I tried all
this have been:

```
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1650161686,
        "narHash": "sha256-70ZWAlOQ9nAZ08OU6WY7n4Ij2kOO199dLfNlvO/+pf8=",
        "owner": "nixos",
        "repo": "nixpkgs",
        "rev": "1ffba9f2f683063c2b14c9f4d12c55ad5f4ed887",
        "type": "github"
      },
      "original": {
        "owner": "nixos",
        "ref": "nixos-unstable",
        "repo": "nixpkgs",
        "type": "github"
      }
    },
    "root": {
      "inputs": {
        "nixpkgs": "nixpkgs"
      }
    }
  },
  "root": "root",
  "version": 7
}
```

I don't know every bit of that, but what we can see is, that nix "locked" our
`nixpkgs` input for us to the commit `1ffba9f2f683063c2b14c9f4d12c55ad5f4ed887`.

And as long, as you don't do anything special, this flake will this commit
of our `nixpkgs` input for this flake. There is a whole lot of cli commands
and options to manage this lock file. So there should be no need for `niv`
and the like any more.

Now we declared an input, but we didn't do anything with it. Let's change that.

There are different types of outputs a flake can have. Development shells, packages,
hydra jobs, ....

We pick a package for now, as that is simple.

We want to take a package from nixpkgs and simply offer it as one of our own packages.

So we have two jobs here, access the `nixpkgs` input and "get" the package we want
and then "declare the package as one of our own".

Because of all the cross compiling stuff nix provides, we will have to specify for
which machine architecture we want to offer a package. Using a flake as input, we
also have to specify for which machine architecture we want to use stuff from that
input. This will complicate things a tiny bit.

So how do we access stuff from our inputs? Yeah, as usual, nixpkgs a special snowflake
here, as it declares a `legacyPackages` output, flakes usual don't have. To access
the derivation for GNU hello from nixpkgs we have to write:

```
nixpkgs.legacyPackages.x86_64-linux.hello
^ -- input symbolic name used in 'inputs' and the function arguments to 'outputs'
        ^ -- output specified by the nixpkgs flake
	               ^ -- machine architecture we want to deal with
```

To specify a package, our `outputs` function has to return an attribute set
containing an attribute named `packages` which contains attributes for
each machine architecture, whose values are a collection of derivations.

So provide the GNU hello derivation from nixpkgs as on of our own packages,
our flake.nix has to look like that:

```
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = {
    self,
    nixpkgs,
    ...
  }: {
      packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
  };
}
```

If you repeat `nix flake show` now, the output should be like:

```
git+file:///home/typetetris/playground/first-flake
└───packages
    └───x86_64-linux
        └───hello: package 'hello-2.12'
```

with potentially different version numbers of course.

We can now build this package like:

```
nix build .#hello
```

If your shell treats everything after a '#' as a comment, inspite of it being mid word, you need
to use apostrophes like the

```
nix build '.#hello'
```

You should get the usual result like to the build output of `hello`.

There is also the concept of a "default package" you can specify in two different
ways at the moment.

The new way is having a package declared under the default key, like that:

```
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = {
    self,
    nixpkgs,
    ...
  }: {
      packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
      packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.hello;
  };
}
```

or with the `defaultPackage` output attribute (which is deprecated and
support will be removed somewhen in the future):

```
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = {
    self,
    nixpkgs,
    ...
  }: {
      packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
      defaultPackage.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.hello;
  };
}
```

Now if you just run

```
nix build .
```

with the git repository of your flake as working directory, the default package
should be build.

Templates
---------

There is a template system in place, so you don't have to write your `flake.nix`
files from scratch every time.

Let's exercise this with a little rust program we want to build.

I did the following to get a little rust program going:

```
cd ~/playground
cargo init hello-world
cd hello-world
git add .
git commit -m "Initial"
```

and that is that. Now we want to build that with nix. There are different ways to
build rust programs with nix and I mention two of them. We could use the machinery
already in place in `nixpkgs` to build a rust program, or we could use [naersk](https://github.com/nix-community/naersk).

We are going to use `naersk`.

First we take a look at the `naersk` flake, for that we issue the command

```
nix flake show --no-write-lock-file github:nix-community/naersk
```

which yielded this output for me:

```
github:nix-community/naersk/e8f9f8d037774becd82fce2781e1abdb7836d7df
├───defaultTemplate: template: Build a rust project with naersk.
├───lib: unknown
├───overlay: Nixpkgs overlay
└───templates
    ├───cross-windows: template: Cross compile a rust project for use on Windows.
    ├───hello-world: template: Build a rust project with naersk.
    ├───multi-target: template: Compile a rust project to multiple targets.
    └───static-musl: template: Compile a rust project statically using musl.
```

(--no-write-lock-file was necessary, otherwise nix would have tried to write a lock
file for this flake, but how is that possible for something we directly used from
github without cloning it first to some writable directory on our machine?)

We can see `naersk` defines a bunch of templates for us to use. Let's go with
the `hello-world` one. To instantiate it, we call the following with
the directory of our rust program as our working directory:

```
nix flake init -t github:nix-community/naersk#hello-world
```

which writes a `flake.nix` file to our working directory with
the following contents (at the time of writing):

```
{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";
  };

  outputs = { self, nixpkgs, flake-utils, naersk }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages."${system}";
        naersk-lib = naersk.lib."${system}";
      in
        rec {
          # `nix build`
          packages.hello-world = naersk-lib.buildPackage {
            pname = "hello-world";
            root = ./.;
          };
          defaultPackage = packages.hello-world;

          # `nix run`
          apps.hello-world = flake-utils.lib.mkApp {
            drv = packages.hello-world;
          };
          defaultApp = apps.hello-world;

          # `nix develop`
          devShell = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [ rustc cargo ];
          };
        }
    );
}
```

It declares `flake-utils`, `naersk` as inputs and
declares a package, an app and and a development shell
as outputs. (Ignore that it uses nixpkgs input, without
declaring it. That is using some stuff we haven't touched
upon yet.)

Again we need to flake.nix to git, so it will be recognised by nix:

```
git add flake.nix
```

then we can take a look at our flake by running

```
nix flake show
```

we can also take a look at what inputs our flake uses with the cli
by calling

```
nix flake metadata
```

If our rust program wasn't convienently named 'hello-world' one
would change the 'hello-world' identifiers in the flake.nix to something
more meaningful for the own project, for consistencies sake.

The package can be build by

```
nix build
```

as it is also the default package of the flake.

The app can be run, which simply executes our rust program, by
calling

```
nix run
```

and we can "enter" the development shell by calling

```
nix develop
```

which will give us a shell with `rustc` and `cargo` on the path.

That's it for now.


Choice of nix version
---------------------

You might have noticed, that I choose to use nix from
its master branch. I did this, because at the time of
writing version 2.7.0 still had this [bug](https://github.com/NixOS/nix/issues/6373) which
makes `nix profile` unusable for beginners.
