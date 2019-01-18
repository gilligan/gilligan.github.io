---
layout: post
title: "Post-Christmas Advent of Code In Haskell - Day 2"
description: "Haskelling our way through the puzzles of Day 2"
---

Today's post is about [Day 2: _"Inventory Management System"_](https://adventofcode.com/2018/day/2)
. We are given a file containing random looking strings
and are asked to calculate some checksums and also find a certain pair among them..

### Day 2 / Part 1

We have to calculate a checksum for the strings (_IDs_) in the input file. The checksum
algorithm works as follows: 

```
Checksum = Twos * Threes
Twos = number of IDs that contain a letter exactly 2 times
Threes = number of IDs that contain a letter exactly 3 times
```
It also provides an example:

```
"abcdef" -> no letters that appear exactly two or three times.
"bababc" -> two a and three b, so it counts for both.
"abbcde" -> two b, but no letter appears exactly three times.
"abcccd" -> three c, but no letter appears exactly two times.
"aabcdd" -> two a and two d, but it only counts once.
"abcdee" -> two e.
"ababab" -> three a and three b, but it only counts once.

Checksum = Twos * Threes = 4 * 3 = 12
```

#### getOccurrences

In order to determine the checksum we have to look at each string separately and test both
properties separately: _(1)_ Does it contain any letter exactly twice? _(2)_ Does it 
contain any letter exactly three times?

So `getOccurrences` should take a `String` and return something that conveys whether or
not the String fulfills either or both of those properties..

```haskell
getOccurrences :: String -> (Bool, Bool)
```
Admittedly `(Bool, Bool)` is a type you should usually be avoiding since it is entirely
meaningless when it appears without context. Luckily we aren't writing production code
today so I am just going to pretend this never happened and carry on.

We will assume the
first value refers to letters appearing twice (`True` --> appearing twice), and the second 
one to letters appearing three times (`True` --> appearing three times).

How do we go about finding out if a string has any re-occurring characters? We can use
some handy functions from `Data.List`, namely
[sort](http://hackage.haskell.org/package/base-4.12.0.0/docs/Data-List.html#v:sort) and
[group](http://hackage.haskell.org/package/base-4.12.0.0/docs/Data-List.html#v:group):

```
> import Data.List
> (group . sort) "bababc"
["aa", "bbb", "c"]
```

We turned our String into a sorted list grouped by characters. In order to get to our
desired result type we just have to check if this list contains strings of length 2 or 3
respectively:

```haskell
ofLength n = filter ((==n) . length)
```

We can use `ofLength` on our intermediate value from above:

```
> ofLength 2 ["aa", "bbb", "c"]
["aa"]
> ofLength 3 ["aa", "bbb", "c"]
["bbb"]
```


##### (&&&)

What we want to do now is apply two functions (`ofLength 2` and `ofLength 3`)
to one value (our intermediate result) and collect both results in a tuple. It just so
happens that the [Arrow](https://wiki.haskell.org/Arrow_tutorial) function
[(&&&)](http://hackage.haskell.org/package/base-4.12.0.0/docs/Control-Arrow.html#v:-38--38--38-)
does exactly what we want:

```
> import Control.Arrow
> (+1) &&& (*1) 0
(1,0)
```

**Note**: I don't know the first thing about the whole Arrow abstraction but I've seen 
`(&&&)` used here and there and it fits our purposes right now. Furthermore _Advent of
Code_ is the perfect opportunity to just play round with things like that. Anyhow, moving
on:

```
ofLength 2 &&& ofLength 3 $ ["aa", "bbb", "c"]
(["aa"], ["bbb"])
```

We are getting closer. We now have a tuple, but the type is still wrong. We are at
`([String], [String])` instead of `(Bool, Bool)`. The values of our tuple should be `True`
or `False` depending on whether or not the list is empty. Well that is easy enough:

```
> (not . null) ["foo"]
True
```

Now we just have to apply this to both values of the tuple:

```
> fmap (not . null) (["aa"], ["bbb"])
(["aa"], True)
-- Oops, right, this doesn't work..
```

##### Bifunctor

Functor won't do since we want to map over both values of the tuple. [`bimap`](http://hackage.haskell.org/package/base-4.12.0.0/docs/Data-Bifunctor.html#v:bimap) to the rescue:

```
> import Data.Bifunctor
> :t bimap
bimap :: (a -> b) -> (c -> d) -> p a c -> p b d
> bimap (not . null) (not . null) (["aa"], ["bbb"])
(True, True)
```

##### Putting The Pieces Together

```haskell
getOccurrences :: String -> (Bool, Bool)
getOccurrences = bimap (not . null) (not . null)
               . (ofLength 2 &&& ofLength 3)
               . group
               . sort
```

Now we just have to write a function that applies `getOccurrences` to all IDs, sums up,
and finally multiplies the values.


#### calcChecksum

Let's assume that `calcChecksum` will get the contents of the input file as input and we
want to return the final checksum:

```haskell
calcChecksum :: String -> Int
```

Our input is a file containing newline separated strings so we can start with something
like this:

```haskell
f :: String -> [(Bool, Bool)]
f = fmap getOccurrences . lines
```

We split the String and apply our `getOccurrences` function to all IDs. 

Where do we go from here? We have to count the `True` values from the first and the second
value of all tuples in the list. Sure sounds like a fold to me, don't you think? I tend to
mess things up with folds so let's sketch this out and have ghc help us out:

```haskell
g = foldr _f (0,0) (undefined :: [(Bool, Bool)])
```

ghc is going to report back:

```
    • Found hole: _f :: (Bool, Bool) -> (a, b) -> (a, b)
      Where: ‘a’, ‘b’ are rigid type variables bound by
               the inferred type of it :: (Num a, Num b) => (a, b)
```

Alright, we can write something fulfilling that signature:

```haskell
toNum x = if x then 1 else 0
sumUp (f, s) (x, y) = (x + toNum f, y + toNum s)
```

Let's try it:

```
> foldr sumUp (0,0) [(True, False), (True, False), (True, False)]
(3,0)
```

Let's add it to what we already have:

```haskell
f :: String -> (Int, Int)
f = foldr sumUp (0,0)
  . fmap getOccurrences
  . lines
```

Almost there! The only part missing is that we still need to multiply the first and second
value of the tuple. We cannot just put multiplication in front of our composition because
`(*)` expects 2 arguments where we just have a tuple. The answer to that is `uncurry`:

```
> :t (*)
(*) :: Num a => a -> a -> a
> :t uncurry
uncurry :: (a -> b -> c) -> (a, b) -> c
> :t uncurry (*)
uncurry (*) :: Num c => (c, c) -> c
```

With that last bit we can complete our `calcChecksum` function:

```haskell
calcChecksum :: String -> Int
calcChecksum = uncurry (*)
             . foldr sumUp (0,0)
             . fmap getOccurrences
             . lines
```

##### Putting The Pieces Together

Here is the complete code for solving part 1 of this challenge:

```haskell
ofLength n = filter ((==n) . length)

toNum x = if x then 1 else 0
sumUp (f, s) (x, y) = (x + toNum f, y + toNum s)

getOccurrences :: String -> (Bool, Bool)
getOccurrences = bimap (not . null) (not . null)
               . (ofLength 2 &&& ofLength 3)
               . group
               . sort


calcChecksum :: String -> Int
calcChecksum = uncurry (*)
             . foldr sumUp (0,0)
             . fmap getOccurrences
             . lines

solvePart1 :: FilePath -> IO Int
solvePart1 file = calcChecksum <$> readFile file
```


### Day 2 / Part 2

The second part continues with the same input data. We are tasked with finding a pair of
IDs differing in only 1 character. The result is said string with the differing character
removed.

Let's again start in the small and work our way up to the bigger picture. We are going to
need a function to determine the distance between two strings - the number of differing
characters between two strings:

```haskell
strDist :: String -> String -> Int
strDist [] _ = 0
strDist (x:xs) (y:ys) = if x == y then strDist xs ys else 1 + strDist xs ys
```

Let's also quickly implement the function that we'll need once we have
our pair which drops the differing character:

```haskell
dropEq :: String -> String -> String
dropEq [] _ = []
dropEq (x:xs) (y:ys) = if x == y then x : dropEq xs ys else dropEq xs ys
```

Another simple, manual recursion. Now we need to start thinking about how we actually want
to find our pair in the first place.
The pair we are looking for could be between any two strings of our input. Thus let's
build a list of tuples representing all combinations. Haskell
[list comprehension](https://wiki.haskell.org/List_comprehension) comes in handy here:

```haskell
getCombinations :: [a] -> [(a, a)]
getCombinations xs = [(x,y) | x <- xs, y <- xs]
```

When fed with all IDs from the input file, the pair we are looking for is going to be
one of the tuples in that list. We can find it by looking for the tuple where `strDist`
yields `1`. Let's put together what we have so far:

```haskell
findPair :: String -> Maybe (String, String)
findPair = find ((==1) . uncurry strDist)
         . getCombinations
         . lines
```

With that we can already find the tuple we are looking for! We only need to add one last
transformation - we want a single string with the differing character omitted. We have
already written `dropEq :: String -> String -> String` for that purpose. Note that we want
to apply `dropEq` to two strings in a tuple so yet again we reach for 
[uncurry](http://hackage.haskell.org/package/base-4.12.0.0/docs/Prelude.html#v:uncurry).

```haskell
findPair :: String -> Maybe (String, String)
findPair = fmap (uncurry dropEq)
         . find ((==1) . uncurry strDist)
         . getCombinations
         . lines
```

Note how we need to use `fmap` as the tuple is wrapped in a `Maybe`

##### Putting The Pieces Together

Below is the full code for solving the second part of this challenge:

```haskell
getCombinations :: [b] -> [(b, b)]
getCombinations xs = [(x,y) | x <- xs, y <- xs]

dropEq :: String -> String -> String
dropEq [] _ = []
dropEq (x:xs) (y:ys) = if x == y then x : dropEq xs ys else dropEq xs ys

strDist :: String -> String -> Int
strDist [] _ = 0
strDist (x:xs) (y:ys) = if x == y then strDist xs ys else 1 + strDist xs ys

findPair :: String -> Maybe String 
findPair = fmap (uncurry dropEq)
         . find ((==1) . uncurry strDist)
         . getCombinations
         . lines

solvePart2 :: FilePath -> IO (Maybe String)
solvePart2 file = findPair <$> readFile file
```


### That's All Folks

That's it for Day 2. You can find the full code on
[github](https://github.com/gilligan/aoc2018). If you have any feedback please don't
hesitate to reach out: [@tpflug](https://twitter.com/tpflug).
