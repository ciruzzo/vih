
import EditBuffer
import Rendering
import Input
import Data.Char
import System.Environment (getArgs)
import System.Console.Terminal.Size (size, height, width)

data EditMode = Command | Insert deriving (Eq,Show)

main :: IO ()
main =
  do 
     dims <- size
     let ext = maybe 33 height dims
         yExt = min 40 (ext - 2) 

     initInput 
     args <- getArgs
     case args of
              [f] -> do contents <- readFile f
                        mainLoop Command f yExt (EditBuffer 0 (0,0) contents)
              _   -> mainLoop Command "" yExt (EditBuffer 0 (0,0) "")

promptAndRead :: String -> Int ->  IO String
promptAndRead p yExt =
  do goto (commandHome yExt)
     putStr p
     getLine

mainLoop :: EditMode -> FilePath -> Int -> EditBuffer -> IO ()
mainLoop mode f yExt previousBuffer = 
  do cls
     buffer <- return (frame yExt previousBuffer) 
     render yExt buffer
     -- writeAt commandHome (showRepresentation buffer)
     ch <- getInputChar
     if mode == Insert
       then 
         case ch of 
           '\ESC' -> mainLoop Command f yExt (enterCommandMode buffer)
           _      -> if isInputChar ch 
                       then mainLoop mode f yExt (insertChar ch buffer)
                       else mainLoop mode f yExt buffer
       else
         case ch of
           ':' -> do str <- promptAndRead ":" yExt
                     handleCommand buffer f yExt str
           '/' -> do str <- promptAndRead "/" yExt
                     mainLoop mode f yExt (searchForward str buffer)
           'i' -> mainLoop Insert f yExt buffer
           'h' -> mainLoop mode f yExt (moveLeft buffer)
           'j' -> mainLoop mode f yExt (moveDown buffer)
           'k' -> mainLoop mode f yExt (moveUp buffer) 
           'l' -> mainLoop mode f yExt (moveRight buffer)
           'd' -> do nextCh <- getInputChar
                     if nextCh == 'd' 
                        then mainLoop mode f yExt (deleteLine buffer) 
                        else mainLoop mode f yExt buffer
           'g' -> do nextCh <- getInputChar
                     if nextCh == 'g' 
                        then mainLoop mode f yExt (moveToHome buffer) 
                        else mainLoop mode f yExt buffer 
           'G' -> mainLoop mode f yExt (moveToEnd buffer)
           '0' -> mainLoop mode f yExt (moveToLineStart buffer)
           '$' -> mainLoop mode f yExt (moveToLineEnd buffer)
           'o' -> mainLoop Insert f yExt (insertLineAfter buffer)
           'r' -> do nextCh <- getInputChar 
                     if isInputChar nextCh
                       then mainLoop mode f yExt (replaceChar nextCh buffer)
                       else mainLoop mode f yExt buffer
           'w' -> mainLoop mode f yExt (wordForward buffer)
           'b' -> mainLoop mode f yExt (wordBackward buffer)
           'x' -> mainLoop mode f yExt (deleteChar buffer)
           _   -> mainLoop mode f yExt buffer


-- aborts when line command is not parseable.  Fix with exception catch
handleCommand :: EditBuffer -> FilePath -> Int -> String -> IO ()
handleCommand buffer f yExt command =
  do goto (commandHome yExt)
     putStr ":"
     case command of
       ('q':_)                           -> return ()
       ("wq") | not (null f)             -> writeFile f (getBufferContents buffer)
       ('w':_) | not (null f)            -> do writeFile f (getBufferContents buffer)
                                               mainLoop Command f yExt buffer
       (c:_)   | isDigit c               -> mainLoop Command f yExt (moveToLine (read command :: Int) buffer)
       _                                 -> mainLoop Command f yExt buffer

isInputChar :: Char -> Bool
isInputChar ch = (not (isControl ch)) || (ch == '\n')

