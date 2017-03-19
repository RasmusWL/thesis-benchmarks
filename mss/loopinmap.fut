fun max(x: i32) (y: i32): i32 =
  if x > y then x else y

-- (best, left, right, total)
fun redOp((bx, lx, rx, tx): (i32,i32,i32,i32))
         ((by, ly, ry, ty): (i32,i32,i32,i32)): (i32,i32,i32,i32) =
  ( max bx (max by (rx + ly))
  , max lx (tx+ly)
  , max ry (rx+ty)
  , tx + ty)

fun mapOp (x: i32): (i32,i32,i32,i32) =
  ( max x 0, max x 0, max x 0, x)

entry main(xss: [m][n]i32): [m]i32 =
  if m < 64
  then replicate (m) 0
  else
  map (\(xs : [n]i32) ->
       loop ((bx, lx, rx, tx) = (0,0,0,0)) = for i < n do
         redOp (bx, lx, rx, tx) (mapOp xs[i])
        in bx
    ) xss
