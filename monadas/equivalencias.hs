import Control.Monad
import Control.Concurrent
import Data.IORef
--import Control.Either
foreign import ccall "exp" c_exp :: Double -> Double
--foreign import swap "swap" c_swap:: Double -> Double

{-
newIORef :: a -> IO (IORef a)
readIORef :: IORef a -> IO a
writeIORef :: IORef a -> a -> IO ()
modifyIORef :: IORef a -> (a -> a) -> IO ()

data STRef s a
newSTRef    :: a -> ST s (STRef s a)
readSTRef   :: STRef s a -> ST s a
writeSTRef  :: STRef s a -> a -> ST s ()
modifySTRef :: STRef s a -> (a -> a) -> ST s ()
para escapar de la monada usar:
runST :: ST s a -> a

MVar, de Control.Concurrent
newMVar :: a -> IO (MVar a)
newEmptyMVar :: IO (MVar a)
takeMVar :: MVar a -> IO a

data TVar a
newTVar    :: a -> STM (TVar a)
readTVar   :: TVar a -> STM a
writeTVar  :: TVar a -> a -> STM ()
modifyTVar :: TVar a -> (a -> a) -> STM ()
There are also alternatives that work in the IO monad.
newTVarIO   :: a -> IO (TVar a)
readTVarIO  :: TVar a -> IO a
-}

magic :: IORef (Maybe Int) -> IO ()
magic ref = do
    value <- readIORef ref

    case value of
        Just _ -> return ()
        Nothing -> writeIORef ref (Just 42)

modIORef :: IO ()
modIORef = do
    ref <- newIORef Nothing
    magic ref

    readIORef ref >>= print
--entre ambas funciones son capaces de modificar ref!

bubbleSort :: [Int] -> IO [Int]
bubbleSort input = do
    let ln = length input

    xs <- mapM newIORef input

    forM_ [0..ln - 1] $ \_ -> do
        forM_ [0..ln - 2] $ \j -> do
            let ix = xs !! j
            let iy = xs !! (j + 1)

            x <- readIORef ix
            y <- readIORef iy

            when (x > y) $ do
                writeIORef ix y
                writeIORef iy x

    mapM readIORef xs

pruebaBurbuja = bubbleSort [1,4,3,0] >>= (putStr . show) 

--Mvar de concurrencia
simpleMVar = do
  a <- newEmptyMVar

  forkIO $ forever $ takeMVar a >>= putStrLn

  forM_ [0..3] $ $ do
      text <- getLine
      putMVar a text

--STM : Software Transactional Memory
--atomically :: STM a -> IO a
bigTransaction :: IO ()
bigTransaction = do
    value <- atomically $ do
        var <- newTVar (0 :: Int)
        modifyTVar var (+1)
        readTVar var

    print value

atomicReadWrite :: IO ()
atomicReadWrite = do
    var <- newTVarIO (0 :: Int)

    atomically $ do
        value <- readTVar var
        writeTVar var (value + 1)

    readTVarIO var >>= print

f :: TVar Int -> STM ()
f var = modifyTVar var (+1)

twoCombined :: IO ()
twoCombined = do
    var <- newTVarIO (0 :: Int)

    atomically $ do
        f var
        f var

    readTVarIO var >>= print
--transaccion entre trheads 

maybePrint :: IORef Bool -> IORef Bool -> IO ()
maybePrint myRef yourRef = do
  writeIORef myRef True
  yourVal <- readIORef yourRef
  unless yourVal $ putStrLn "critical section"

threadIO :: IO ()
threadIO = do
  print (c_exp 0)
  r1 <- newIORef False
  r2 <- newIORef False
  forkIO $ maybePrint r1 r2
  forkIO $ maybePrint r2 r1
  threadDelay 1000000

main :: IO ()
main = simpleMVar