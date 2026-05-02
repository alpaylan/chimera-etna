module Main where

import           Control.Exception (SomeException, evaluate, try)
import           Etna.Result       (PropertyResult(..))
import           Etna.Witnesses
  ( witness_to_wheel210_monotonic_case_i11
  , witness_to_wheel210_monotonic_case_i13
  , witness_to_wheel210_monotonic_case_i17
  , witness_from_infinite_index_equals_head_case_n0_k0
  , witness_from_infinite_index_equals_head_case_n42_k7
  , witness_from_infinite_index_equals_head_case_n1000_k1023
  )
import           System.Exit       (exitFailure, exitSuccess)

cases :: [(String, PropertyResult)]
cases =
  [ ("witness_to_wheel210_monotonic_case_i11",                    witness_to_wheel210_monotonic_case_i11)
  , ("witness_to_wheel210_monotonic_case_i13",                    witness_to_wheel210_monotonic_case_i13)
  , ("witness_to_wheel210_monotonic_case_i17",                    witness_to_wheel210_monotonic_case_i17)
  , ("witness_from_infinite_index_equals_head_case_n0_k0",        witness_from_infinite_index_equals_head_case_n0_k0)
  , ("witness_from_infinite_index_equals_head_case_n42_k7",       witness_from_infinite_index_equals_head_case_n42_k7)
  , ("witness_from_infinite_index_equals_head_case_n1000_k1023",  witness_from_infinite_index_equals_head_case_n1000_k1023)
  ]

main :: IO ()
main = do
  results <- mapM evalCase cases
  let failures =
        [ (n, m) | (n, Left m)         <- results ] ++
        [ (n, m) | (n, Right (Fail m)) <- results ] ++
        [ (n, "discard") | (n, Right Discard) <- results ]
  if null failures
    then do
      putStrLn $ "OK: all " ++ show (length cases) ++ " witnesses passed"
      exitSuccess
    else do
      mapM_ (\(n, m) -> putStrLn (n ++ ": FAIL: " ++ m)) failures
      exitFailure
  where
    evalCase (name, r) = do
      mr <- try (evaluate r) :: IO (Either SomeException PropertyResult)
      pure (name, either (Left . show) Right mr)
