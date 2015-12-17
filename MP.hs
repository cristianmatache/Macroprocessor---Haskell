module MP where

import System.Environment

type FileContents = String

type Keyword      = String
type KeywordValue = String
type KeywordDefs  = [(Keyword, KeywordValue)]

separators :: String
separators
  = " \n\t.,:;!\"\'()<>/\\"

lookUp :: String -> [(String, a)] -> [a]
-- searches first string in a given list
lookUp xs pairs = [y | (x,y) <- pairs, xs == x]

split :: [Char] -> [Char] -> ([Char], [[Char]])
-- splits a string as described
split seps [] = ([],[""])
split seps (x:xs)
 | elem x seps = ((x:f), ("":(s1:s)))
 | otherwise   = ( f, (x:s1):s)
  where
   (f,(s1:s)) = split seps xs

split2 :: [Char] -> [Char] -> ([Char], [[Char]])
-- another way of solving split
split2 seps xs
 = ([x| x <-xs, elem x seps], foldr split' [""] xs)
  where
   split' chr (y:ys)
    | elem chr seps = "" : (y :ys)
    | otherwise     = (chr : y) : ys

combine :: String -> [String] -> [String]
-- combines separators and words, generated by split, of a string
combine "" a = a
combine (x:xs) (y:ys)
 = y:[x]:(combine xs ys)

getKeywordDefs :: [String] -> KeywordDefs
-- returns pairs of Keywords and their definitions
getKeywordDefs xs = map gKHelp xs
 where
  gKHelp :: String -> (String, String)
  gKHelp "" = ("","")
  gKHelp ys
   = (w, concat(combine ts ws))
   where ((t:ts), (w:ws)) = split separators ys

expand :: FileContents -> FileContents -> FileContents
-- takes: text, info files; returns: modified text file
expand text info
 = concat (combine fss (map (replaceWord w ) sns))
  where
   (fss, sns) = split separators text
   w = filter (/=("","")) (def info)

replaceWord :: KeywordDefs -> String -> String
-- replaces a word with its definition if needed
replaceWord ts "" = ""
replaceWord ((h : m, n) : ts) (x : xs)
 | (x == '$') && (xs == m) = n
 | (x == '$') && (xs /= m) = replaceWord ts (x : xs)
 | otherwise = (x : xs)

def :: String -> [(String, String)]
-- takes: info file; returns: list of keywords and their definitions
def xs
 = getKeywordDefs (snd (split "\n" xs))

generaldef :: String -> [[(String,String)]]
-- returns a lists of definitions for each phrase
generaldef info
 = map (filter (/= ("","")))  (map def (snd(split "#" info)))

expandex :: FileContents -> FileContents -> FileContents
expandex text info
 = concat (page (map (expand text) (snd(split "#" info))))

page :: [String] -> [String]
    -- page layout
page [] = []
page (x:xs)
 = (x++"-----\n") : page xs

-- another version of advanced expand:

generalexpand :: String -> String -> [String]
generalexpand text info
-- generalization of expand : for each phrase
 = expandex' (generaldef info)
   where
    (fss, sns) = split separators text
    expandex' [] = []
    expandex' (h:hs)
         = (concat (combine fss(map (replaceWord h) sns))) : expandex' hs

expandex2 :: FileContents -> FileContents -> FileContents
--final advanced expand
expandex2 text info
 = concat( page (generalexpand text info))

main :: IO ()
-- The provided main program which uses your functions to merge a
-- template and source file.
main = do
  args <- getArgs
  main' args

  where
    main' :: [String] -> IO ()
    main' [template, source, output] = do
      t <- readFile template
      i <- readFile source
      writeFile output (expandex t i)
    main' _ = putStrLn ("Usage: runghc MP <template> <info> <output>")
