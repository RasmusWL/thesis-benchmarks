{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Main where

import Random.Array

import Data.Array.Accelerate as A
import Data.Array.Accelerate.LLVM.PTX as A
import Data.Bits

import Prelude as P

--import Data.Array.Accelerate.Interpreter

import Criterion.Main

doTest :: Int -> Int -> IO ()
doTest powy powx = do
--  let total_elems = shift 1 (powy+powx)

  let num_segments = shift 1 powy
  let segment_size = shift 1 powx

  let arr :: Array DIM2 Float = randomArray uniform (Z :. num_segments :. segment_size)

  -- Run the benchmarks
  defaultMain
    [ bgroup (show powy P.++ " " P.++ show powx)
--        [ bench "vector"        $ nf   (V.dotp xs_vec) ys_vec
--        [ bench "cublas"        $ B.dotp hdl n xs_dev ys_dev
        [ bench "accelerate"    $ whnf (A.run1 segsum) arr
        ]
    ]

  putStrLn "\n"

runTests:: Int -> IO ()
runTests n = do
  let tests = [ (y,x) | x <- [0..n], y <- [n..0] ]
  mapM_ (P.uncurry doTest) tests

main :: IO ()
main = do
  print wat
  runTests 10

wat =
  let arr = fromList (Z:.3:.5) [0..] :: Array DIM2 Int
      d_arr = use arr
  in run $ segsum d_arr

--------------------------------------------------------------------------------

dotp :: Acc (Vector Float) -> Acc (Vector Float) -> Acc (Scalar Float)
dotp xs ys =
  A.fold (+) 0 (A.zipWith (*) xs ys)


sum :: A.Num a => Acc (Array DIM1 a) -> Acc (Scalar a)
sum = A.fold (+) 0

-- Could make types more pretty by using this trick

     -- -> Acc (Array (sh:.Int) a)
     -- -> Acc (Array sh a)

segsum :: A.Num a => Acc (Array DIM2 a) -> Acc (Array DIM1 a)
segsum = A.fold (+) 0

segsum' :: (Shape sh, A.Num a) => Acc (Array (sh A.:. Int) a) -> Acc (Array sh a)
segsum' = A.fold (+) 0
