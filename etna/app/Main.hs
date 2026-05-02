{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import           Control.Exception     (SomeException, evaluate, try)
import           Data.IORef            (newIORef, readIORef, modifyIORef')
import           Data.Time.Clock       (diffUTCTime, getCurrentTime)
import           System.Environment    (getArgs)
import           System.Exit           (exitWith, ExitCode(..))
import           System.IO             (hFlush, stdout)
import           Text.Printf           (printf)

import           Etna.Result           (PropertyResult(..))
import qualified Etna.Properties       as P
import qualified Etna.Witnesses        as W
import qualified Etna.Gens.QuickCheck  as GQ
import qualified Etna.Gens.Hedgehog    as GH
import qualified Etna.Gens.Falsify     as GF
import qualified Etna.Gens.SmallCheck  as GS

import qualified Test.QuickCheck                    as QC
import qualified Hedgehog                           as HH
import qualified Test.Falsify.Generator             as FG
import qualified Test.Falsify.Interactive           as FI
import qualified Test.Falsify.Property              as FP
import qualified Test.SmallCheck                    as SC
import qualified Test.SmallCheck.Drivers            as SCD
import qualified Test.SmallCheck.Series             as SCS

allProperties :: [String]
allProperties = ["ToWheel210Monotonic", "FromInfiniteIndexEqualsHead"]

data Outcome = Outcome
  { oStatus :: String
  , oTests  :: Int
  , oCex    :: Maybe String
  , oErr    :: Maybe String
  }

main :: IO ()
main = do
  argv <- getArgs
  case argv of
    [tool, prop] -> dispatch tool prop
    _            -> do
      putStrLn "{\"status\":\"aborted\",\"error\":\"usage: etna-runner <tool> <property>\"}"
      hFlush stdout
      exitWith (ExitFailure 2)

dispatch :: String -> String -> IO ()
dispatch tool prop
  | prop /= "All" && prop `notElem` allProperties =
      emit tool prop "aborted" 0 0 Nothing (Just $ "unknown property: " ++ prop)
  | otherwise = do
      let targets = if prop == "All" then allProperties else [prop]
      mapM_ (runOne tool) targets

runOne :: String -> String -> IO ()
runOne tool prop = do
  t0 <- getCurrentTime
  result <- try (driver tool prop) :: IO (Either SomeException Outcome)
  t1 <- getCurrentTime
  let us = round ((realToFrac (diffUTCTime t1 t0) :: Double) * 1e6) :: Int
  case result of
    Left e  -> emit tool prop "aborted" 0 us Nothing (Just (show e))
    Right (Outcome status tests cex err) ->
      emit tool prop status tests us cex err

driver :: String -> String -> IO Outcome
driver "etna"       p = runWitnesses p
driver "quickcheck" p = runQuickCheck p
driver "hedgehog"   p = runHedgehog   p
driver "falsify"    p = runFalsify    p
driver "smallcheck" p = runSmallCheck p
driver tool         _ = pure (Outcome "aborted" 0 Nothing (Just ("unknown tool: " ++ tool)))

------------------------------------------------------------------------------
-- Tool: etna (witness replay)
------------------------------------------------------------------------------

-- Force each witness inside `try`; a witness whose property raises a
-- pure error (e.g. fromInfinite under the buggy patch) is reported as
-- a *failure* against the witness name, not an aborted run.
runWitnesses :: String -> IO Outcome
runWitnesses prop = case witnessesFor prop of
  []    -> pure (Outcome "aborted" 0 Nothing (Just ("no witnesses for " ++ prop)))
  cs    -> go cs 0
  where
    go [] n = pure (Outcome "passed" n Nothing Nothing)
    go ((name, r):rest) n = do
      mr <- try (evaluate r) :: IO (Either SomeException PropertyResult)
      case mr of
        Left e ->
          pure (Outcome "failed" (n + 1) (Just name) (Just (show e)))
        Right Pass     -> go rest (n + 1)
        Right Discard  -> go rest (n + 1)
        Right (Fail msg) ->
          pure (Outcome "failed" (n + 1) (Just name) (Just msg))

witnessesFor :: String -> [(String, PropertyResult)]
witnessesFor "ToWheel210Monotonic" =
  [ ("witness_to_wheel210_monotonic_case_i11", W.witness_to_wheel210_monotonic_case_i11)
  , ("witness_to_wheel210_monotonic_case_i13", W.witness_to_wheel210_monotonic_case_i13)
  , ("witness_to_wheel210_monotonic_case_i17", W.witness_to_wheel210_monotonic_case_i17)
  ]
witnessesFor "FromInfiniteIndexEqualsHead" =
  [ ("witness_from_infinite_index_equals_head_case_n0_k0",        W.witness_from_infinite_index_equals_head_case_n0_k0)
  , ("witness_from_infinite_index_equals_head_case_n42_k7",       W.witness_from_infinite_index_equals_head_case_n42_k7)
  , ("witness_from_infinite_index_equals_head_case_n1000_k1023",  W.witness_from_infinite_index_equals_head_case_n1000_k1023)
  ]
witnessesFor _ = []

------------------------------------------------------------------------------
-- Tool: quickcheck
------------------------------------------------------------------------------

runQuickCheck :: String -> IO Outcome
runQuickCheck "ToWheel210Monotonic" =
  qcDrive (QC.forAll GQ.gen_to_wheel210_monotonic (qcProp P.property_to_wheel210_monotonic))
runQuickCheck "FromInfiniteIndexEqualsHead" =
  qcDrive (QC.forAll GQ.gen_from_infinite_index_equals_head (qcProp P.property_from_infinite_index_equals_head))
runQuickCheck p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

qcProp :: (a -> PropertyResult) -> a -> QC.Property
qcProp f args = case f args of
  Pass     -> QC.property True
  Discard  -> QC.discard
  Fail msg -> QC.counterexample msg (QC.property False)

qcDrive :: QC.Property -> IO Outcome
qcDrive p = do
  result <- QC.quickCheckWithResult
              QC.stdArgs { QC.maxSuccess = 200, QC.chatty = False }
              p
  case result of
    QC.Success { QC.numTests = n } -> pure (Outcome "passed" n Nothing Nothing)
    QC.Failure { QC.numTests = n, QC.failingTestCase = tc } ->
      pure (Outcome "failed" n (Just (concat tc)) Nothing)
    QC.GaveUp  { QC.numTests = n } -> pure (Outcome "aborted" n Nothing (Just "QuickCheck gave up"))
    QC.NoExpectedFailure { QC.numTests = n } ->
      pure (Outcome "aborted" n Nothing (Just "no expected failure"))

------------------------------------------------------------------------------
-- Tool: hedgehog
------------------------------------------------------------------------------

runHedgehog :: String -> IO Outcome
runHedgehog "ToWheel210Monotonic" =
  hhDrive GH.gen_to_wheel210_monotonic P.property_to_wheel210_monotonic
runHedgehog "FromInfiniteIndexEqualsHead" =
  hhDrive GH.gen_from_infinite_index_equals_head P.property_from_infinite_index_equals_head
runHedgehog p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

hhDrive
  :: (Show a) => HH.Gen a -> (a -> PropertyResult) -> IO Outcome
hhDrive gen f = do
  let test = HH.property $ do
        args <- HH.forAll gen
        case f args of
          Pass     -> pure ()
          Discard  -> HH.discard
          Fail msg -> do
            HH.annotate msg
            HH.failure
  ok <- HH.check test
  if ok
    then pure (Outcome "passed" 200 Nothing Nothing)
    else pure (Outcome "failed" 1 Nothing Nothing)

------------------------------------------------------------------------------
-- Tool: falsify
------------------------------------------------------------------------------

runFalsify :: String -> IO Outcome
runFalsify "ToWheel210Monotonic" =
  fsDrive GF.gen_to_wheel210_monotonic P.property_to_wheel210_monotonic
runFalsify "FromInfiniteIndexEqualsHead" =
  fsDrive GF.gen_from_infinite_index_equals_head P.property_from_infinite_index_equals_head
runFalsify p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

fsDrive
  :: (Show a)
  => FG.Gen a
  -> (a -> PropertyResult)
  -> IO Outcome
fsDrive gen f = do
  let prop = do
        args <- FP.gen gen
        case f args of
          Pass     -> pure ()
          Discard  -> FP.discard
          Fail msg -> FP.testFailed (show args ++ ": " ++ msg)
  -- A pure `error` thrown from the property body propagates straight
  -- through Falsify; without this `try` it becomes an `aborted` run
  -- (caught by the outer driver wrapper) instead of a counterexample
  -- attribution. We treat any exception as a backend-level failure.
  mResult <- try (FI.falsify prop) :: IO (Either SomeException (Maybe String))
  case mResult of
    Left  e          -> pure (Outcome "failed" 1 Nothing (Just (show e)))
    Right Nothing    -> pure (Outcome "passed" 100 Nothing Nothing)
    Right (Just msg) -> pure (Outcome "failed" 1 (Just msg) Nothing)

------------------------------------------------------------------------------
-- Tool: smallcheck
------------------------------------------------------------------------------

runSmallCheck :: String -> IO Outcome
runSmallCheck "ToWheel210Monotonic" =
  scDrive GS.series_to_wheel210_monotonic P.property_to_wheel210_monotonic
runSmallCheck "FromInfiniteIndexEqualsHead" =
  scDrive GS.series_from_infinite_index_equals_head P.property_from_infinite_index_equals_head
runSmallCheck p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

scDrive
  :: (Show a)
  => SCS.Series IO a
  -> (a -> PropertyResult)
  -> IO Outcome
scDrive series f = do
  countRef <- newIORef (0 :: Int)
  -- depth 12 reaches the wheel-210 bug indices (smallest at i = 11).
  -- The fromInfinite series caps internally so this doesn't blow up
  -- enumeration on the orthogonal property.
  let depth = 12
      check args = SC.monadic $ do
        modifyIORef' countRef (+1)
        pure $ case f args of
          Pass    -> True
          Discard -> True
          Fail _  -> False
      smTest = SC.over series check
  res <- try (SCD.smallCheckM depth smTest)
           :: IO (Either SomeException (Maybe SCD.PropertyFailure))
  n <- readIORef countRef
  case res of
    Left e          -> pure (Outcome "failed" n Nothing (Just (show e)))
    Right Nothing   -> pure (Outcome "passed" n Nothing Nothing)
    Right (Just pf) -> pure (Outcome "failed" n (Just (show pf)) Nothing)

------------------------------------------------------------------------------
-- Output (single JSON line, exit 0 except on argv error)
------------------------------------------------------------------------------

emit :: String -> String -> String -> Int -> Int -> Maybe String -> Maybe String -> IO ()
emit tool prop status tests us cex err = do
  let q = quoteJSON
      esc Nothing  = "null"
      esc (Just s) = q s
  printf "{\"status\":%s,\"tests\":%d,\"discards\":0,\"time\":\"%dus\",\"counterexample\":%s,\"error\":%s,\"tool\":%s,\"property\":%s}\n"
    (q status) tests us (esc cex) (esc err) (q tool) (q prop)
  hFlush stdout

quoteJSON :: String -> String
quoteJSON s = '"' : concatMap esc s ++ "\""
  where
    esc '"'  = "\\\""
    esc '\\' = "\\\\"
    esc '\n' = "\\n"
    esc '\r' = "\\r"
    esc '\t' = "\\t"
    esc c | fromEnum c < 0x20 = printf "\\u%04x" (fromEnum c)
          | otherwise = [c]

