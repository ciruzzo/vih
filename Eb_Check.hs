import Test.QuickCheck
import EditBuffer

main = do 
  quickCheck prop_insert_delete_inverse; 
  quickCheck prop_insert_char_advances

prop_insert_delete_inverse ch =
  ch /= '\n' ==> emptyBuffer == (deleteChar . moveLeft . insertChar ch) emptyBuffer

prop_insert_char_advances n =
  n >= 0 ==> n == x
               where (EditBuffer _ (x, _) _) = (iterate (insertChar 'a') emptyBuffer) !! n

