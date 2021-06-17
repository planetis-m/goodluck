import nake, std/strformat

task "docs", "Generate documentation":
  # https://nim-lang.github.io/Nim/docgen.html
  let
    dir = "docs/"
    src = dir / "intro.rst"
    doc = dir / src.changeFileExt(".html")
  if doc.needsRefresh(src):
    echo "Generating the docs..."
    direShell(nimExe,
        &"rst2html --verbosity:0 --out:{dir} {src}")
  else:
    echo "Skipped generating the docs."
