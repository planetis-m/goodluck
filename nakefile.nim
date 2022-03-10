import nake, std/strformat

task "docs", "Generate documentation":
  # https://nim-lang.github.io/Nim/docgen.html
  let
    name = "intro.rst"
    dir = "docs/"
    src = "rstdocs" / name
    doc = dir / name.changeFileExt(".html")
  if doc.needsRefresh(src):
    direSilentShell("Generating the docs...", nimExe,
        &"rst2html --verbosity:0 --out:{dir} {src}")
  else:
    echo "Skipped generating the docs."
