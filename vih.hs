import EditBuffer
import Rendering
import Input
import Data.Char
import System.Environment (getArgs)
import System.Console.Terminal.Size (size, height, width)

data EditMode = Command | Insert deriving (Eq,Show)

data Session = Session
  { filePath :: FilePath
  , extent   :: Int
  , cols     :: Int
  } deriving (Show)

data Editor = Editor
  { edMode    :: EditMode
  , edSession :: Session
  , edBuffer  :: EditBuffer
  } deriving (Show)

main :: IO ()
main =
  do dims <- size
     let (h, w) = maybe (33, 80) (\win -> (height win, width win)) dims
         y = h - 2

     initInput 
     args <- getArgs
     let base = Editor Command (Session "" y w) (EditBuffer 0 (0,0) "")

     case args of
       [f] -> do contents <- readFile f
                 mainLoop Editor { edMode    = Command
                                 , edSession = Session f y w
                                 , edBuffer  = EditBuffer 0 (0,0) contents }
       _   -> mainLoop base


promptAndRead :: String -> Int -> IO String
promptAndRead p y =
  do goto (commandHome y)
     putStr p
     getLine

mainLoop :: Editor -> IO ()
mainLoop ed = 
  do cls
     let y = extent (edSession ed)
         buf = edBuffer ed
         w    = cols    (edSession ed)
     render y w (frame y buf)

     ch <- getInputChar

     if edMode ed == Insert
       then 
         case ch of 
           '\ESC' -> mainLoop (ed {edMode = Command})
           _      -> if isInputChar ch 
                       then mainLoop (ed { edBuffer = insertChar ch buf})
                       else mainLoop ed
       else
         case lookup ch keyActions of
           Just act -> mainLoop (ed { edBuffer = act buf })
           _        -> case ch of        
             ':' -> do str <- promptAndRead ":" (extent (edSession ed))
                       handleCommand ed str
             '/' -> do str <- promptAndRead "/" (extent (edSession ed))
                       mainLoop (ed { edBuffer = searchForward str buf })
             'i' -> mainLoop (ed { edMode = Insert })
             'o' -> mainLoop (ed { edMode = Insert
                                 , edBuffer = insertLineAfter buf })
             'd' -> do nextCh <- getInputChar
                       if nextCh == 'd'
                         then mainLoop (ed { edBuffer = deleteLine buf })
                         else mainLoop ed
             'g' -> do nextCh <- getInputChar
                       if nextCh == 'g'
                         then mainLoop (ed { edBuffer = moveToHome buf })
                         else mainLoop ed
             'r' -> do nextCh <- getInputChar
                       if isInputChar nextCh
                         then mainLoop (ed { edBuffer = replaceChar nextCh buf })
                         else mainLoop ed
             'x' -> mainLoop (ed { edBuffer = deleteChar buf})
             _   -> mainLoop ed



handleCommand :: Editor -> String -> IO ()
handleCommand ed command =
  do goto (commandHome y)
     putStr ":"
     case command of
       ('q':_)                  -> return ()
       ("wq") | not (null f)   -> writeFile f (getBufferContents b)
       ('w':_) | not (null f)  -> do writeFile f (getBufferContents b)
                                     mainLoop ed
       (c:_)   | isDigit c      -> mainLoop (ed { edBuffer = moveToLine (read command :: Int) b } )
       _                        -> mainLoop ed
  where y  = extent (edSession ed)
        f  = filePath (edSession ed)
        b  = edBuffer ed

isInputChar :: Char -> Bool
isInputChar ch = (not (isControl ch)) || (ch == '\n')

