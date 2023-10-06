
# Glibc Dynamic Linking issue

This repository contains a proposed fix for https://github.com/jetpack-io/devbox/issues/1276

## Problem

The original `devbox.json` was:
```
{
  "packages": [
    "python310@latest",
    "python310Packages.pip@latest",
    "drawio@21.6.1",
    "inkscape@1.1.2",
    "librsvg@2.52.5",
    "xorg.xorgserver@latest",
    "plantuml@1.2023.9",
    "imagemagick@6.9.11-60",
    "stdenv.cc.cc.lib",
    "texlive.combined.scheme-full@2022.20221227"
  ],
  "shell": {
    "init_hook": [
      ". $VENV_DIR/bin/activate",
      "pip install -q -r requirements.txt"
    ]
  },
  "nixpkgs": {
    "commit": "a16f7eb56e88c8985fcc6eb81dabd6cade4e425a"
  }
}
```

It also has this `requirements.txt`:
```
Sphinx==5.3.0
sphinx_rtd_theme==1.1.1
sphinxcontrib-plantuml==0.25
sphinxcontrib-svg2pdfconverter==1.2.1
sphinxcontrib-drawio==0.0.16
sphinxcontrib-bibtex==2.5.0
Pillow==9.3.0
matplotlib==3.7.2
```

and `main.py`:
```
import matplotlib

def main():
    print("hello world")

main()
```

However, running `python main.py` gives this error:
```
Traceback (most recent call last):
  File "/code/main.py", line 1, in <module>
    import matplotlib
  File "/code/.devbox/virtenv/python310Packages.pip/.venv/lib/python3.10/site-packages/matplotlib/__init__.py", line 129, in <module>
    from . import _api, _version, cbook, _docstring, rcsetup
  File "/code/.devbox/virtenv/python310Packages.pip/.venv/lib/python3.10/site-packages/matplotlib/rcsetup.py", line 27, in <module>
    from matplotlib.colors import Colormap, is_color_like
  File "/code/.devbox/virtenv/python310Packages.pip/.venv/lib/python3.10/site-packages/matplotlib/colors.py", line 56, in <module>
    from matplotlib import _api, _cm, cbook, scale
  File "/code/.devbox/virtenv/python310Packages.pip/.venv/lib/python3.10/site-packages/matplotlib/scale.py", line 22, in <module>
    from matplotlib.ticker import (
  File "/code/.devbox/virtenv/python310Packages.pip/.venv/lib/python3.10/site-packages/matplotlib/ticker.py", line 138, in <module>
    from matplotlib import transforms as mtransforms
  File "/code/.devbox/virtenv/python310Packages.pip/.venv/lib/python3.10/site-packages/matplotlib/transforms.py", line 49, in <module>
    from matplotlib._path import (
ImportError: libstdc++.so.6: cannot open shared object file: No such file or directory
```

Here, `matplotlib` requires a `libstdc++.so.6` library.

## The usual fix: stdenv.cc.cc.lib

In the nix and Devbox communities, the usual suggestion to fix this is `devbox add stdenv.cc.cc.lib`.

However, doing this leads to two errors now:
```
$ python main.py
Traceback (most recent call last):
  File "/code/main.py", line 1, in <module>
    import matplotlib
  File "/code/.devbox/virtenv/python310Packages.pip/.venv/lib/python3.10/site-packages/matplotlib/__init__.py", line 129, in <module>
    from . import _api, _version, cbook, _docstring, rcsetup
  File "/code/.devbox/virtenv/python310Packages.pip/.venv/lib/python3.10/site-packages/matplotlib/rcsetup.py", line 27, in <module>
    from matplotlib.colors import Colormap, is_color_like
  File "/code/.devbox/virtenv/python310Packages.pip/.venv/lib/python3.10/site-packages/matplotlib/colors.py", line 56, in <module>
    from matplotlib import _api, _cm, cbook, scale
  File "/code/.devbox/virtenv/python310Packages.pip/.venv/lib/python3.10/site-packages/matplotlib/scale.py", line 22, in <module>
    from matplotlib.ticker import (
  File "/code/.devbox/virtenv/python310Packages.pip/.venv/lib/python3.10/site-packages/matplotlib/ticker.py", line 138, in <module>
    from matplotlib import transforms as mtransforms
  File "/code/.devbox/virtenv/python310Packages.pip/.venv/lib/python3.10/site-packages/matplotlib/transforms.py", line 49, in <module>
    from matplotlib._path import (
ImportError: /nix/store/lqz6hmd86viw83f9qll2ip87jhb7p1ah-glibc-2.35-224/lib/libc.so.6: version `GLIBC_2.36' not found (required by /code/.devbox/nix/profile/default/lib/libstdc++.so.6)
```

and

```
$ rsvg-convert --help
/nix/store/0ccn204v5kds9i08x7plf4x644l6wm87-librsvg-2.52.5/bin/rsvg-convert: /nix/store/4s21k8k7p1mfik0b33r2spq5hq7774k1-glibc-2.33-108/lib/libc.so.6: version `GLIBC_2.35' not found (required by /code/.devbox/nix/profile/default/lib/libgcc_s.so.1)
/nix/store/0ccn204v5kds9i08x7plf4x644l6wm87-librsvg-2.52.5/bin/rsvg-convert: /nix/store/4s21k8k7p1mfik0b33r2spq5hq7774k1-glibc-2.33-108/lib/libc.so.6: version `GLIBC_2.34' not found (required by /code/.devbox/nix/profile/default/lib/libgcc_s.so.1)
```

This is happening because the `libstdc++.so.6` and `libgcc_s.so.1` libraries are expecting newer versions of glibc than `python3` and `rsvg-convert` were packaged with.

## New fix: patch python310 and librsvg to use latest glibc

In this fix, the `devbox.json` is now:
```
{
  "packages": [
    "path:./local-flakes/python",
    "python310Packages.pip@latest",
    "inkscape@1.1.2",
    "path:./local-flakes/librsvg",
    "xorg.xorgserver@latest",
    "plantuml@1.2023.9",
    "imagemagick@6.9.11-60",
    "texlive.combined.scheme-full@2022.20221227",
    "github:nixos/nixpkgs/7131f3c223a2d799568e4b278380cd9dac2b8579#stdenv.cc.cc.lib"
  ],
  "shell": {
    "init_hook": [
      ". $VENV_DIR/bin/activate",
      "pip install -q -r requirements.txt"
    ]
  },
  "nixpkgs": {
    "commit": "a16f7eb56e88c8985fcc6eb81dabd6cade4e425a"
  }
}
```

You'll notice three changes:
1. `path:./local-flakes/python`
2. `path:./local-flakes/librsvg`
3. `github:nixos/nixpkgs/7131f3c223a2d799568e4b278380cd9dac2b8579#stdenv.cc.cc.lib`

First, within `local-flakes/python`, we patch `python3` to use the latest glibc
```nix
 python3 = wrapper.libcPatcher pkgs-latest "python-patched" pkgs-python.python3;
```
This uses a small nix function [libcPatcher](https://github.com/savil/libc-patcher/blob/main/flake.nix) that is essentially a bash-script.
This bash-script uses a utility called `patchelf` to ensure that `python3` will execute with the latest libc.
I'll add details to the readme of https://github.com/savil/libc-patcher to explain what it does internally.

Second, `path:./local-flakes/librsvg` does the very same operation as the python flake.

Lastly, regarding `github:nixos/nixpkgs/7131f3c223a2d799568e4b278380cd9dac2b8579#stdenv.cc.cc.lib`:
The nixpkgs commit hash here must match that of the `nixpkgs-latest` in the python and librsvg flakes from which the libc is used.

Starting a `devbox shell` with this `devbox.json` and these local flakes, gives:
```
# may need to clear local state
> rm -rf .devbox

> devbox shell
Starting a devbox shell...

(devbox) $ python main.py
hello world

(devbox)$ rsvg-convert --help
rsvg-convert version 2.52.5
... // omitted

```

## Reasoning and Limitations

This fix relies on the following assumptions and observations:
1. Glibc has a high level of backwards-compatibility. This lets us patch binaries to use newer glibc versions than they were initially built with. However, it is [not perfectly backwards compatible](https://abi-laboratory.pro/?view=timeline&l=glibc), so this may yet fail in some scenarios. Glibc also has some [private symbols `GLIBC_PRIVATE`, which are not backwards compatible](https://groups.google.com/g/uk.comp.os.linux/c/PX3rstGtZRQ).
2. This only patches Glibc, and not other libraries. That said, Glibc seems to be the most (only?) frequently reported library incompatibility reported by Devbox users.
