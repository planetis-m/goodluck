import std/bitops

type
  ElemType = uint

const
  ElemSize = sizeof(ElemType) * 8
  One = ElemType(1)
  Zero = ElemType(0)

proc enumRange[T: enum](t: typedesc[T]): int =
  high(T).ord - low(T).ord + 1

proc wordsFor*[T: enum](t: typedesc[T]): int =
  (enumRange(t) + ElemSize - 1) div ElemSize

type
  BitSet*[T: enum; N: static int] = distinct array[N, ElemType]

template modElemSize(arg: untyped): untyped = arg.ord and (ElemSize - 1)
template divElemSize(arg: untyped): untyped = arg.ord shr countTrailingZeroBits(ElemSize)

template `[]`(x: BitSet, i: int): ElemType = array[N, ElemType](x)[i]
template `[]=`(x: BitSet, i: int, v: ElemType) =
  array[N, ElemType](x)[i] = v

proc contains*[T, N](x: BitSet[T, N], e: T): bool =
  result = (x[int(e.divElemSize)] and (One shl e.modElemSize)) != Zero

proc incl*[T, N](x: var BitSet[T, N], elem: T) =
  x[int(elem.divElemSize)] = x[int(elem.divElemSize)] or
      (One shl elem.modElemSize)

proc excl*[T, N](x: var BitSet[T, N], elem: T) =
  x[int(elem.divElemSize)] = x[int(elem.divElemSize)] and
      not(One shl elem.modElemSize)

proc union*[T, N](x: var BitSet[T, N], y: BitSet[T, N]) =
  for i in 0..<N: x[i] = x[i] or y[i]

proc diff*[T, N](x: var BitSet[T, N], y: BitSet[T, N]) =
  for i in 0..<N: x[i] = x[i] and not y[i]

proc symDiff*[T, N](x: var BitSet[T, N], y: BitSet[T, N]) =
  for i in 0..<N: x[i] = x[i] xor y[i]

proc intersect*[T, N](x: var BitSet[T, N], y: BitSet[T, N]) =
  for i in 0..<N: x[i] = x[i] and y[i]

proc equals*[T, N](x, y: BitSet[T, N]): bool =
  for i in 0..<N:
    if x[i] != y[i]:
      return false
  result = true

proc contains*[T, N](x, y: BitSet[T, N]): bool =
  for i in 0..<N:
    if (y[i] and not x[i]) != Zero:
      return false
  result = true

proc `*`*[T, N](x, y: BitSet[T, N]): bool {.inline.} = (var x = x; intersect(x, y))
proc `+`*[T, N](x, y: BitSet[T, N]): bool {.inline.} = (var x = x; union(x, y))
proc `-`*[T, N](x, y: BitSet[T, N]): bool {.inline.} = (var x = x; diff(x, y))
proc `<`*[T, N](x, y: BitSet[T, N]): bool {.inline.} = contains(y, x) and not equals(x, y)
proc `<=`*[T, N](x, y: BitSet[T, N]): bool {.inline.} = contains(y, x)
proc `==`*[T, N](x, y: BitSet[T, N]): bool {.inline.} = equals(x, y)

proc bitset*[T, N](e: varargs[T, N]): BitSet[T, N] =
  for val in items(e): result.incl(val)
