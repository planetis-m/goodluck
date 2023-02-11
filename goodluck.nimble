# Package
version     = "0.1.0"
author      = "Antonis Geralis"
description = "A hackable template for creating small and fast games."
license     = "MIT"

# Deps
requires "nim >= 1.6.0"
requires "bingo#83f0924"
requires "sdl2#head"

import os

const
  PkgDir = thisDir().quoteShell
  DocsDir = PkgDir / "docs"

task docs, "Generate documentation":
  # https://nim-lang.github.io/Nim/docgen.html
  withDir(PkgDir):
    let tmp = "intro"
    let doc = DocsDir / (tmp & ".html")
    let src = "rstdocs" / (tmp & ".rst")
    # Generate the docs for {src}
    exec("nim rst2html --project --verbosity:0 --out:" & doc & " " & src)
