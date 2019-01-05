---
layout: post
title: "Post-Christmas Advent of Code In Haskell"
description: "Solving Advent of Code with Haskell - slowly."
---

This year, for the first time, I tried to follow the annual [Advent of Code](http://adventofcode.com/2018/)
coding challenge series. In case you haven't heard about it, here is an excerpt from its about page:

> Advent of Code is an Advent calendar of small programming puzzles for a variety of skill sets and skill levels that can be solved in any programming language you like. People use them as a speed contest, interview prep, company training, university coursework, practice problems, or to challenge each other.

It began with nice little tasks that I could solve with little effort. After some days however the challenges got
more and more involved and i was unable to find the time to work on them. Each day there is a new challenge so the
unsolved ones started to pile up which I found somewhat demotivating.

Now that _Advent of Code 2018_ is over I decided to pick up the challenges again and blog about solving them in Haskell.
Maybe some people will get something out of it - Actually, if you do then let [me know](https://twitter.com/tpflug) :)

### A Short Note On Nix

I ♥ Nix - so I also use its wonderful Haskell integration. This isn't really relevant in the context of 
this series but I wanted to briefly mention it anyway. You can have a look at the relevant [default.nix](https://github.com/gilligan/aoc2018/blob/master/default.nix). Some notes:

- It picks `ghc863` as compiler.
- It declares a little [ghcid](https://github.com/ndmitchell/ghcid) script.
- It uses [callCabal2nix](https://github.com/NixOS/nixpkgs/blob/62882d8cd2498d4591ece59a455b700a9600ad0c/pkgs/development/haskell-modules/make-package-set.nix#L195) for creating a nix derivation from a cabal file.
- It uses [shellFor](https://github.com/NixOS/nixpkgs/pull/36393) to provide a shell environment with everything we need (including the ghcid script).

There is also a [shell.nix](https://github.com/gilligan/aoc2018/blob/master/default.nix) which just refers to the
shell from the `default.nix` file and is automatically picked up from `nix-shell` calls.

**TL;DR**: If you have nix installed you can just run `nix-shell` to get a working development environment.


### Day 1 / Part 1

Go [here](https://adventofcode.com/2018/day/1) for the full description of the challenge. Looking
at the following examples should suffice to understand what we need to do though:

```
+1, +1, +1 results in  3
+1, +1, -2 results in  0
-1, -2, -3 results in -6
```

Our input is a sequence of numbers that we have to "combine" to a single number (is it me
or does it suddenly smell very monoidal in here?). First things first though: Let us start
with reading in the input.

#### Reading the input

Reading the input data is of course just a matter of calling [readFile](http://hackage.haskell.org/package/base-4.12.0.0/docs/Prelude.html#v:readFile).
Unfortunately all the numbers are prefixed with either `-` or `+`. If we want to use [read](http://hackage.haskell.org/package/base-4.12.0.0/docs/Prelude.html#v:read) to parse the strings as numbers then this won't work:

```
Prelude> read "3" :: Integer
3
Prelude> read "-3" :: Integer
-3
Prelude> read "+3" :: Integer
*** Exception: Prelude.read: no parse
```

We need to skip the `+` signs. We can just peek at the start of the string check if it is
a `+` or not and then act accordingly:

```Haskell
toNum :: String -> Integer
toNum str@(s:ss) = if s == '+' then read ss else read str
```

#### Combining the input

Now that we know how to read the file and parse the numbers we can think about how to 
perform the actual calculation. All we really need to do is to sum up all the numbers.
For this we can use a combination of [foldMap](http://hackage.haskell.org/package/base-4.12.0.0/docs/Data-Foldable.html#v:foldMap)
and [Sum](http://hackage.haskell.org/package/base-4.12.0.0/docs/Data-Monoid.html#v:Sum):

```Haskell
calibrate :: String -> Integer
calibrate = getSum
          . foldMap (Sum . toNum)
          . lines
```

This is a neat little composition. Let's go over it step by step (starting at the end because composition
goes right to left):

- `lines :: String -> [String]`: the numbers in the input data file are `\n` separated to lets split it up
- `foldMap :: (Foldable t, Monoid m) => (a -> m) -> t a -> m`: We fold over our list of strings (`t a`) using
`(Sum . toNum)` (`a -> m` function), and get back `Sum Integer` (`m`).
- `getSum`: unwraps our Integer from the Sum


#### Solution To Part 1

Putting it all together we can write a module like the following:


```Haskell
module Day1 where

import Data.Monoid

toNum :: String -> Integer
toNum str@(s:ss) = if s == '+' then read ss else read str

calibrate :: String -> Integer
calibrate = getSum
          . foldMap (Sum . toNum)
          . lines

solvePart1 :: FilePath -> IO Integer
solvePart1 file = calibrate <$> readFile file
```

We can use the `solvePart1` function to get our answer:

```
Day1> solvePart1 "./day1.input"
477
```

### Day 1 / Part 2
