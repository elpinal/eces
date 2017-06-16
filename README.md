# Eces

Every Circumstance of Emacs is Separated.

## Install

The simplest way of installing the command, using OMake:

```bash
$ omake install
```

It installs the executable into /usr/local/bin.

If you want to specify the install directory:

<pre><code>$ omake install PREFIX=<i>path_you_want_to_install</i></code></pre>

The build requires basically MLton, but you can choose the build command as the following:

<pre><code>$ omake install SML=<i>standard_ml_compiler_you_like</i></code></pre>

## Contribution

1. Fork ([https://github.com/elpinal/eces/fork](https://github.com/elpinal/eces/fork))
1. Create a feature branch
1. Commit your changes
1. Rebase your local changes against the master branch
1. Run test suite and confirm that it passes
1. Create a new Pull Request

## Author

[elpinal](https://github.com/elpinal)
