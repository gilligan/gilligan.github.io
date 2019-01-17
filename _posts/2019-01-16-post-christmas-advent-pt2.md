---
layout: post
title: "Post-Christmas Advent of Code In Haskell - Day 2"
description: "Haskelling our way through the puzzles of Day 2"
---

Today's post is about [Day 2: _"Inventory Management System"_](https://adventofcode.com/2018/day/2)
. We are given an file containing random looking Strings
and are asked to calculate some checksums and also find a pair fulfilling a certain
property.

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
meaningless when it appears outside of context. Luckily we aren't writing production code
today so I am just going to pretend this never happened and carry on. We will assume the
first value refers to letters appearing twice, and the second one to letters appearing
three times.

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

Now that we can work on single strings we just have to write a function that applies
`getOccurrences` to all IDs, sums up and finally multiplies the values.


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

Alright, we can do that:

```haskell
toNum x = if x then 1 else 0
sumUp (f, s) (x, y) = (x + toNum f, y + toNum s)
```

Let's try it:

```
> foldr sumUp (0,0) [(True, False), (True, False), (True, False)]
(3,0)
```

So we can add that to what we worked out before:

```haskell
f :: String -> (Int, Int)
f = foldr sumUp (0,0)
  . fmap getOccurrences
  . lines
```

Almost there! The only part missing is that we need to multiply the first and second value
of the tuple still. We cannot just put multiplication in front of our composition because
`(*)` expects 2 arguments whereas we have a tuple. The answer to that is `uncurry`:

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

The only thing we haven't looked at is the boring part of actually reading the file. Here
is the complete code for solving part 1 of this challenge:

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
