{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Etna.Gens.SmallCheck where

import qualified Test.SmallCheck.Series as SC

import Etna.Properties
  ( Wheel210Index(..)
  , FromInfArgs(..)
  )

-- Enumerate small Wheel210 indices densely; bug shows at i=11,13,17,...
-- so depth budget of ~8 is plenty.
series_to_wheel210_monotonic :: Monad m => SC.Series m Wheel210Index
series_to_wheel210_monotonic = do
  i <- SC.generate (\d -> map fromIntegral [0 .. (min d 209 :: Int)])
  pure (Wheel210Index i)

-- The fromInfinite construction bug fires for any (n, k); enumerate
-- a tiny prefix and let SmallCheck explore.
series_from_infinite_index_equals_head :: Monad m => SC.Series m FromInfArgs
series_from_infinite_index_equals_head = do
  n <- SC.generate (\d -> map fromIntegral [0 .. (min d 5 :: Int)])
  k <- SC.generate (\d -> map fromIntegral [0 .. (min d 5 :: Int)])
  pure (FromInfArgs n k)
