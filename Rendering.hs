module Rendering
     ( render
     , cls
     , goto
     , home
     , commandHome
     , writeAt
     ) 
where

import EditBuffer
import System.IO

home :: Location
home = (0,0)

commandHome :: Int -> Location
commandHome yExtent = (0, yExtent + 1)

cls :: IO ()
cls = putStr "\ESC[2J\ESC[H"

render :: Int -> Int -> EditBuffer -> IO ()
render yExtent cols (EditBuffer topLine (x,y) contents) = do 
    writeAt home $ window screenLines 
    goto (x, y - topLine)
    where window       = unlines . take yExtent . drop topLine  
          screenLines  = map (take cols) (lines contents) ++ (repeat "~")

goto :: Location -> IO ()
goto (x,y) =
  putStr ("\ESC[" ++ show (y + 1) ++ ";" ++ show (x + 1) ++ "H")

writeAt :: Location -> String -> IO ()
writeAt location xs = do
  goto location
  putStr xs

