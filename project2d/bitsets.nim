import std/bitops

type
  ElemType = uint

const
  ElemSize* = sizeof(uint) * 8
  One = ElemType(1)
  Zero = ElemType(0)

proc wordsFor(n: Positive): int =
  (n + ElemSize - 1) div ElemSize

const
  componentsLen = high(HasComponent).ord - low(HasComponent).ord + 1
  bitSetLen = wordsFor(componentsLen)

type
  BitSet* = distinct array[bitSetLen, ElemType]

template modElemSize(arg: untyped): untyped = arg.ord and (ElemSize - 1)
template divElemSize(arg: untyped): untyped = arg.ord shr countTrailingZeroBits(ElemSize)

template `[]`(x: BitSet, i: int): ElemType = array[bitSetLen, ElemType](x)[i]
template `[]=`(x: BitSet, i: int, v: ElemType) =
  array[bitSetLen, ElemType](x)[i] = v

proc contains*(x: BitSet, e: HasComponent): bool =
  result = (x[int(e.divElemSize)] and (One shl e.modElemSize)) != Zero

proc incl*(x: var BitSet, elem: HasComponent) =
  x[int(elem.divElemSize)] = x[int(elem.divElemSize)] or
      (One shl elem.modElemSize)

proc excl*(x: var BitSet, elem: HasComponent) =
  x[int(elem.divElemSize)] = x[int(elem.divElemSize)] and
      not(One shl elem.modElemSize)

proc union*(x: var BitSet, y: BitSet) =
  for i in 0..<bitSetLen: x[i] = x[i] or y[i]

proc diff*(x: var BitSet, y: BitSet) =
  for i in 0..<bitSetLen: x[i] = x[i] and not y[i]

proc symDiff*(x: var BitSet, y: BitSet) =
  for i in 0..<bitSetLen: x[i] = x[i] xor y[i]

proc intersect*(x: var BitSet, y: BitSet) =
  for i in 0..<bitSetLen: x[i] = x[i] and y[i]

proc equals*(x, y: BitSet): bool =
  for i in 0..<bitSetLen:
    if x[i] != y[i]:
      return false
  result = true

proc contains*(x, y: BitSet): bool =
  for i in 0..<bitSetLen:
    if (y[i] and not x[i]) != Zero:
      return false
  result = true

proc `<`*(x, y: BitSet): bool {.inline.} = contains(y, x) and not equals(x, y)
proc `<=`*(x, y: BitSet): bool {.inline.} = contains(y, x)
proc `==`*(x, y: BitSet): bool {.inline.} = equals(x, y)

proc bitset*(e: varargs[HasComponent]): BitSet =
  for val in items(e): result.incl(val)
