-- Parallel Segmented maximum segment sum
-- ==
-- input { [ [1, -2, 3, 4, -1, 5, -6, 1]
--         , [3, -2, 3, 4, -1, 5, -6, 1]
--         ]
-- }
-- output { [11 , 12] }

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

-- old version, is currently not compiled to a segmented reduction
--fun main(xss: [m][n]i32): [m]i32 =
-- map (\xs -> let (x, _, _, _) = reduce redOp (0,0,0,0) (map mapOp xs) in x) xss

-- this version returns all arrays, and is currently compiled to a segmented reduction
fun main(xss: [m][n]i32): ([m]i32, [m]i32, [m]i32, [m]i32) =
  unzip (map (\xs -> reduce redOp (0,0,0,0) (map mapOp xs)) xss)
