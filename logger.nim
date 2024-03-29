import std / [strutils, os]

type
  LogLevel* = enum
    lvlDebug = "Debug"
    lvlHint = "Hint"
    lvlWarn = "Warning"
    lvlError = "Error"
    lvlFatal = "Fatal"

const
  stDebug = "\e[34;2m"
  stHint = "\e[32;2m"
  stWarn = "\e[33;2m"
  stError = "\e[31;2m"
  stFatal = "\e[35;2m"
  stInst = "\e[1m"
  stTraced = "\e[36;21m"
  resetCode = "\e[0m"

const
  sourceDir = currentSourcePath().parentDir()
  levelToStyle: array[LogLevel, string] = [
    lvlDebug: stDebug,
    lvlHint: stHint,
    lvlWarn: stWarn,
    lvlError: stError,
    lvlFatal: stFatal
  ]

var logLevel* = lvlDebug

template log*(lvl: LogLevel, filter: typed, args: varargs[string, `$`]) =
  const
    info = instantiationInfo(fullPaths = true)
    module = relativePath(info.filename, sourceDir)
    header = format("$1$2($3)$6 $4$5:$6 ", stInst, module, info.line,
        levelToStyle[lvl], lvl, resetCode)
    footer = format(" $1[$2]$3\n", stTraced, astToStr(filter), resetCode)
  if logLevel <= lvl and filter:
    stdout.write(header)
    stdout.write(args)
    stdout.write(footer)

template genLogger(name: untyped, lvl: untyped): untyped =
  template name*(filter: typed, args: varargs[string, `$`]): untyped =
    log(lvl, args, filter)

genLogger(debug, lvlDebug)
genLogger(hint, lvlHint)
genLogger(warn, lvlWarn)
genLogger(error, lvlError)
genLogger(fatal, lvlFatal)

template fatalError*(filter: typed, args: varargs[string, `$`]) =
  when defined(debug): writeStackTrace()
  fatal(args, filter)
  quit(QuitFailure)
