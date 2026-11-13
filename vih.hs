
import EditBuffer
import Rendering
import Input
import Data.Char
import Control.Exception
import System.Environment (getArgs)

import Debug.Trace

data EditMode = Command | Insert deriving (Eq,Show)

main :: IO ()
main =
  do initInput 
     args <- getArgs
     case args of
              [f] -> do contents <- readFile f
                        mainLoop Command f (EditBuffer 0 (0,0) contents)
              _   -> mainLoop Command "" (EditBuffer 0 (0,0) "")

mainLoop :: EditMode -> FilePath -> EditBuffer -> IO ()
mainLoop mode f previousBuffer = 
  do cls
     buffer <- return (frame previousBuffer) 
     render buffer
     -- writeAt commandHome (showRepresentation buffer)
     ch <- getInputChar
     if mode == Insert
       then 
         case ch of 
           '\ESC' -> mainLoop Command f (enterCommandMode buffer)
           _      -> if isInputChar ch 
                       then mainLoop mode f (insertChar ch buffer)
                       else mainLoop mode f buffer
       else
         case ch of
           ':' -> handleCommandLine buffer f
           'i' -> mainLoop Insert f buffer
           'h' -> mainLoop mode f (moveLeft buffer)
           'j' -> mainLoop mode f (moveDown buffer)
           'k' -> mainLoop mode f (moveUp buffer) 
           'l' -> mainLoop mode f (moveRight buffer)
           'd' -> do nextCh <- getInputChar
                     if nextCh == 'd' 
                        then mainLoop mode f (deleteLine buffer) 
                        else mainLoop mode f buffer
           'g' -> do nextCh <- getInputChar
                     if nextCh == 'g' 
                        then mainLoop mode f (moveToHome buffer) 
                        else mainLoop mode f buffer 
           'G' -> mainLoop mode f (moveToEnd buffer)
           '0' -> mainLoop mode f (moveToLineStart buffer)
           '$' -> mainLoop mode f (moveToLineEnd buffer)
           'o' -> mainLoop Insert f (insertLineAfter buffer)
           'r' -> do nextCh <- getInputChar 
                     if isInputChar nextCh
                       then mainLoop mode f (replaceChar nextCh buffer)
                       else mainLoop mode f buffer
           'w' -> mainLoop mode f (wordForward buffer)
           'b' -> mainLoop mode f (wordBackward buffer)
           'x' -> mainLoop mode f (deleteChar buffer)
           _   -> mainLoop mode f buffer


-- aborts when line command is not parseable.  Fix with exception catch
handleCommandLine :: EditBuffer -> FilePath -> IO ()
handleCommandLine buffer f =
  do goto commandHome
     putStr ":"
     command <- getLine
     case command of
       ('q':_)                           -> return ()
       ('w':_) | not (null f)            -> do writeFile f (getBufferContents buffer)
                                               mainLoop Command f buffer
       (c:_)   | isDigit c               -> mainLoop Command f (moveToLine (read command :: Int) buffer)
       _                                 -> mainLoop Command f buffer

isInputChar :: Char -> Bool
isInputChar ch = (not (isControl ch)) || (ch == '\n')

