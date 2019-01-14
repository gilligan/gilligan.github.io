---
layout: post
title: "Haskell, Nix and Vim: Getting started"
description: "Suggestions on how to set up a nice Haskell environment"
---

In this post I am going to make some suggestions on how to get a nice
environment for writing Haskell code in Vim using Nix and various other tools.
Of course there are many other routes that you can take and tools that you can
pick to get the same or, depending on your goals, better results ;)

### A Disclaimer On Code Completion

There are two (or maybe 1.5 since `hie` does actually use `ghc-mod` somehow) 
ways to get code completion for Haskell code:

- [ghc-mod](https://github.com/DanielG/ghc-mod)
- [haskell-ide-engine (hie)](https://github.com/haskell/haskell-ide-engine)

I am going to suggest to use **neither**. The latest official `ghc-mod` release
only supports `ghc < 8.2`, the most recent (hie) version is 
[broken](https://github.com/haskell/haskell-ide-engine/issues/1015) for
`cabal-2.4.1.0`.

Before you get the impression that I am being grumpy, I am not.  I applaud all
the
[contributors](https://github.com/haskell/haskell-ide-engine/graphs/contributors)
that are working on `hie` and I believe the whole LSP (language server protocol)
approach is fantastic. Yet I wish I could get back all the time that I have
wasted on getting `ghc-mod` and similar tools to work. I think code completion
is nice, but I am convinced you don't need it in order to call your setup
efficient.

### The Nix Side Of Things

I know there is a huge number of people that use Stack and are really happy
with it. I just happened to get into Nix before Stack was even around and then
basically never felt a real incentive to switch. Anyhow ...

#### Tell Cabal About Nix

The first thing you want to do is make sure you enable the Nix integration of
Cabal by adding (or uncommenting) the following in your `~/.cabal/config` file:

```yaml
nix: True
```

As described 
[here](https://www.haskell.org/cabal/users-guide/nix-integration.html) Cabal
is now going to run all cabal commands in the nix environment provided via
`shell.nix` or `default.nix`. It is also going to obtain the dependencies via
Nix.

#### Nixifying Your Project

The standard way to crate a nix derivation for your project is to use
[cabal2nix](https://github.com/NixOS/cabal2nix):

```
$ cd random-haskell-project
$ cabal2nix --shell . > shell.nix
$ cabal configure && cabal build
```

This will do for some ad-hoc hacking but if you are actively developing some
project you don't want to manually keep your `shell.nix` file up-to-date with
your cabal file each time you add a dependency or change something else.

Thus what you want to use instead is a `default.nix` file that does this for
you. The `callCabal2nix` nix library function does just that. Below are rough
templates for writing your own `default.nix` and `shell.nix` files for your 
project:

**default.nix**
```nix
{ compiler ? "ghc863", pkgs ? import <nixpkgs> {} }:

let

  haskellPackages = pkgs.haskell.packages.${compiler};
  drv = haskellPackages.callCabal2nix "foo" ./. {};

in
  {
    foo = drv;
    foo-shell = haskellPackages.shellFor {
      packages = p: [drv];
      buildInputs = with pkgs; [ cabal-install hlint ghcid];
    };
  }
```

- Both the compiler and the nixpkgs set are passed arguments with default values
but you can override both using `--argstr` (for `compiler`) and `--arg` (for
`pkgs`).
- If you want your build to be deterministic you should really consider to pin
nixpkgs to a certain revision 
([here](https://vaibhavsagar.com/blog/2018/05/27/quick-easy-nixpkgs-pinning/) is
 a nice article by [Vaibhav](https://twitter.com/vbhvsgr) on pinning nixpkgs).
Otherwise you might be surprised to find that suddenly your code doesn't build
anymore after some nix-channel update.
- Add any tools that you want to have available for working on your project to
the `buildInputs` of `foo-shell`. Note though that whatever you are adding there
is only going to be available inside the nix-shell. If you expect Vim to execute
`hlint` you will have to also run Vim inside the nix-shell. Either that or you
install those tools to your nix profile or add them to your environment in
`configuration.nix` if you are a NixOS user.

**shell.nix**
```nix
(import ./. {}).foo-shell
```

- With the cabal Nix support enabled you can now just run `cabal configure` and
under the hood cabal is going to execute `nix-shell --run "cabal configure"`.

Once your project grows bigger and you need more fine grained control this
simple approach won't be sufficient anymore. Once you've reached that point you
might want to consult 
[Nix And Haskell In Production](https://github.com/Gabriel439/haskell-nix) by
[Gabriel Gonazles](https://twitter.com/GabrielG439)

### The Vim Side Of Things

I switched to neovim a while ago but I guess that everything I use is probably
going to also work just fine with Vim - You **should** switch to neovim though :)

- [neovimhaskell/haskell-vim](https://github.com/neovimhaskell/haskell-vim)

My first suggestion is that you install 
[haskell-vim](https://github.com/neovimhaskell/haskell-vim)  which provides you
with sane and improved highlighting and code indentation. It should just work
out of the box after installing (I hope you are using some plugin manager) but
there are also a couple of configuration options for fine tuning indentation
behavior.

- [ujihisa/unite-haskellimport](https://github.com/ujihisa/unite-haskellimport)

I quite like this one. This plugin depends on
[Unite.vim](https://github.com/Shougo/unite.vim) which has actually been
discontinued but the plugin continues to work just fine. You can use it to
search for function names and have the appropriate import statement added to the
top of your file automatically. This is by no means mind boggling magic but I do
find it very convenient. I use the following mapping:

```vim
nnoremap <leader>hI :execute "Unite -start-insert haskellimport"<CR>
```

- [eagletmt/unite-haddock](https://github.com/eagletmt/unite-haddock)

Another Unite based plugin which I find very convenient. It's basically just a
vim integrated hoogle search with as-you-type results in the Unite buffer. I
mapped it to `<leader>hs` as follows:

```vim
nnoremap <leader>hs :execute "Unite hoogle"<CR>
```

Hitting enter on a selection will open the respective documentation link on
hackage for you.

- [parsonsmatt/intero-neovim](https://github.com/parsonsmatt/intero-neovim)

This is definitely the most sophisticated plugin in this list. While the name
suggests it might be for [intero](https://github.com/chrisdone/intero) only, it
does actually work with just `ghci` or `cabal repl` instead just fine. From the
README on GitHub: 

> Intero makes working with Haskell painless by harnessing the power of the GHCi
> REPL. Intero was originally built alongside an Emacs package. This plugin
> ports much of the Emacs plugin functionality into a package for Neovim.

One thing that I definitely missed after giving up on ghc-mod was easy,
editor-integrated type information. Fortunately you can get that with
`intero-neovim`. There is extensive documentation through the
[README.md](https://github.com/parsonsmatt/intero-neovim/blob/master/README.md)
and also the [vim
documentation](https://github.com/parsonsmatt/intero-neovim/blob/master/doc/intero.txt)
Check out the available functions and add some keyboard mappings.

**Make it play nicely with ghci**

- Tell intero-neovim that you want to use `ghci`:

```vim
let g:intero_backend = {
        \ 'command': 'ghci',
        \ 'cwd': expand('%:p:h'),
        \}
```
- Enable the collection of type information in your `.ghci` file:
```
:set +c
```
The 
[ghci user guide](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/ghci.html#ghci-cmd-:set%20+c) 
has details. Adding this is **essential** to get intero-neovim to work.

**A Note On Error Reporting**

intero-neovim also has support for integration with 
[neomake](https://github.com/neomake/neomake) which will report any errors in 
the current buffer on safe. As it happens I use [ale](https://github.com/w0rp/ale)
instead and thus don't make use of this. Feel free to explore this feature if
you are interested. Of course you can also just stick to 
[ghcid](https://github.com/ndmitchell/ghcid) as described below.

#### [w0rp/ale](https://github.com/w0rp/ale)

There are various code linter plugins available and `ale` is one of the more
popular ones these days. It supports checking the current buffer with various
tools and also supports applying fixes in some scenarios (I am not using that
though). As a matter of fact it might well be that I will drop using ale sooner
or later but for now here is my configuration:

```vim
let g:ale_linters = {'haskell': ['hlint', 'ghc']}
let g:ale_haskell_ghc_options = '-fno-code -v0 -isrc'
```

What you get from that is live, asynchronous as-you-type validation of your
buffer contents with both `ghc` and `hlint`. Do you really need it? Maybe --
More about this at the end of this blog post.

### The One Tool You Definitely Want: [ghcid](https://github.com/ndmitchell/ghcid)

The one tool you most definitely want to install from everything I have
mentioned so far is [ghcid](https://github.com/ndmitchell/ghcid). Here are
_detailed instructions_ on how to get it to work:

```
$ cd your-awesome-project
$ ghcid 
# the end <3
```

To be fair, you might have to tell ghcid the command to invoke with the right
target to load and `:set -isrc` to your `.ghci` file if your code actually
resides inside `src/` but apart from that it really is that simple. Now ghcid
will monitor your code and display any occurring errors. If your project has
tests you can also configure ghcid to run those when there have been changes.
Consult the
[README.md](https://github.com/ndmitchell/ghcid/blob/master/README.md) on
details and links to useful additional resources.

### Closing Thoughts Or _"Forget most of what I've just told you"_

What I described above is mostly just a selection of random tools that happen to
work for me at the moment. There sure are alternatives to probably each of
those. 

My recommendations for a solid Haskell development environment are:

1. **Use hlint**: If you are, like me, not a super experienced Haskell Developer
   I would suggest to integrate
   [hlint](https://github.com/ndmitchell/hlint#readme) into your editor/workflow
   of choice. hlint is the closest thing to a pair programming buddy making
   suggestions on how to improve your code. (**Note**: That being said, do
   not hesitate to ignore suggestions if you either don't understand
   them or simply prefer the way your code looks right now)

1. **Use hoogle**: If you end up using some sort of plugin/integration for your
   editor, fine. Otherwise just use `hoogle` on the command line or add a
   command to `~/.ghc/ghci.conf` so you can call it from within ghci

   ```
   :def hoogle \s -> return $ ":! hoogle --count=15 \"" ++ s ++ "\""
   ```

1. **Use ghcid**: It is fast and _it just works_. The error messages that you get
   from ghc can at times look intimidating but more often than not they do
   actually point you in the right direction. Not only that, with typed holes
   you can even ask the compiler to help you out:

   - [Moving Towards Dialogue](https://vaibhavsagar.com/blog/2018/11/03/moving-towards-dialogue/index.html) talks about using type holes in Haskell in general.
   - [Typed Holes](https://octopi.chalmers.se/2018/11/08/typed-holes/): talks
   about the valid hole fit suggestions available in `ghc >= 8.6.x`

   The error messages have been continuously improving and will even get better.
   Try to make good use of them.

1. **Use the REPL Luke!**: The integration offered by `intero-neovim` is nice
   but you can also just invoke `cabal repl` and explore and test and hack. You
   can find the most important facts and features about ghci
   [here](http://dev.stephendiehl.com/hask/#ghci) and in the 
   [ghci user guide](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/ghci.html). In case you haven't heard about it already, with `ghc 8.6.x` you get
   the `:doc` command in `ghci` which makes haddock documentation available
   inside the repl. Pretty nice, don't you think?

These are the things that qualify as **good tooling** when we talk about
Haskell. Do not confuse that with _good editor integration_. Being able to
search for `FilePath -> IO Text` and get back `Data.Text.IO readFile` or asking
for the type signature of `readFile` and getting back `FilePath -> IO Text` is
great tooling. Doing all of that from your editor is good editor integration.

### The Actual Epilogue

Compared to the other programming languages that I have been using, Haskell
definitely has some fantastic tooling available. With Haskell IDE Engine getting
more and more mature the editor integration is also getting smoother. Happy
Hacking (Or should I say
[Happy Haskell Programming!](https://github.com/kazu-yamamoto/hhp)).
