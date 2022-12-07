Last-Edited: 7 December 2022, 20:15 UTC

# Moving Files the Right Way

>  I think the OpenBSD crowd is a bunch of masturbating monkeys, in that they
>  make such a big deal about concentrating on security to the point where they
>  pretty much admit that nothing else matters to them.
>
> — _Linus Torvalds_

<br />


**NOTE**: This page isn’t done yet, and neither is `mmv`.

## Prologue

File moving and renaming is one of the most common tasks we undertake on the
command-line.  We basically always do this with the `mv` utility, and it gets
the job done most of the time.  Want to rename one file?  Use `mv`!  Want to
move a bunch of files into a directory?  Use `mv`!  How could `mv` ever go
wrong?  Well I’m glad you asked!


## Advanced Moving and Pitfalls

Let’s start off nice and simple.  You just inherited a C project that uses the
sacrilegious camelCase naming convension for its files:

```
$ ls
bytecodeVm.c  fastLexer.c  fastLexer.h  slowParser.c  slowParser.h
```

This deeply upsets you, as it upsets me.  So you decide you want to switch all
these files to use snake\_case, like a normal person.  Well how would you do
this?  You use `mv`!  This is what you might end up doing:

```
$ mv bytecodeVm.c bytecode_vm.c
$ mv fastLexer.c fast_lexer.c
$ mv fastLexer.h fast_lexer.h
$ mv slowParser.c slow_parser.c
$ mv slowParser.h slow_parser.h
```

Well...  It works _I guess_, but it’s a pretty shitty way of renaming these
files.  Luckily we only had 5, but what if this was a much larger project with
many more files to rename?  Things would get tedious.  So instead we can use a
little script for this:

```
#!/bin/sh

# I assume you have GNU sed here

for file in *.[ch]; do
	echo $file | sed 's/[A-Z]/\L_&/g' | xargs mv $file
done
```

That works and it gets the job done, but it’s not really ideal is it?  There are
a couple of issues with this.

  1. You’re writing a significantly increased amount of code.  This has the
     obvious drawbacks of being more stuff to write which is always a negative,
     being more error-prone, and if you want to use more than 1 line you need to
     hope that your shell offers user-friendly multiline input.

  2. If you try to rename the file “foo” to “bar” but “bar” already exists, you
     end up deleting a file you may not have wanted to.

  3. In a similar vein to the previous point, you need to be very careful about
     schemes like renaming the file ‘a’ to ‘b’ and ‘b’ to ‘c’.  You run the risk
     of turning ‘a’ into ‘c’ and losing the file ‘b’ entirely.

  4. Moving symbolic links is its own whole can of worms.  If a symlink points
     to a relative location then you need to make sure you keep pointing to the
     right place.  If the symlink is absolute however then you can leave it
     untouched.  But what if the symlink points to a file that you’re moving as
     part of your batch move operation?  Now you need to handle that too.


## Name Mapping with `mmv`

What is `mmv`?  It’s the solution to all your problems, that’s what it is!
`mmv` takes as its argument(s) a utility and that utilities arguments and uses
that to create a mapping between old and new filenames, similar to the `map()`
function found in many programming languages.  I think to best convey how the
tool functions, I should provide an example.  Let’s try to do the same thing we
did previously where we tried to turn camelCase files to snake\_case, but using
`mmv`:

```
$ ls *.[ch] | mmv sed 's/[A-Z]/\L_&/g'
```

Let me break down how this works.

`mmv` starts by reading a series of filenames seperated by newlines from the
standard input.  Yes, sometimes filenames have newlines in them and yes there is
a way to handle them but I shall get to that later.  The filenames that `mmv`
reads from the standard input will be referred to as the “input files”.  Once
all the input files have been read, the utility specified by the arguments is
spawned; in this case that would be `sed` with the argument `'s/[A-Z]/\L_&/g'`.
The input files are then piped into `sed` the exact same way that they would
have been if we ran the above commands without `mmv`, and the output of `sed`
then forms what will be referred to as the “output files”.  Once a complete list
of output files is accumulated, each input file gets renamed to its
corresponding output file.

Let’s look at a simpler example.  Say we want to rename 2 files in the current
directory to use lowercase letters, we could use the following command:

```
$ ls LICENSE README | mmv tr A-Z a-z
```

In the above example `mmv` reads 2 lines from standard input, those being
“LICENSE” and “README”.  Those are our 2 input files now.  The `tr` utilty is
then spawned and the input files are piped into it.  We can simluate this in the
shell:

```
$ ls LICENSE README | tr A-Z a-z
license
readme
```

As you can see above, `tr` has produced 2 lines of output; these are our 2
output files.  Since we now have our 2 input files and 2 output files, `mmv` can
go ahead and rename the files.  In this case it will rename “LICENSE” to
“license” and “README” to “readme”.  For some examples, check the [examples][1]
section of this page down below.


## Filenames with Special Characters

People are retarded, and as a result we have filenames with newlines in them.
All it would have taken to solve this issue for everyone was for literally
**anybody** during the early UNIX days to go “hey, this is a bad idea!”, but
alas, we must deal with this.  Newlines are of course not the only special
characters filenames can contain, but they are the single most infuriating to
deal with; the UNIX utilities all being line-oriented really doesn’t work well
with these files.

So how does `mmv` deal with special characters, and newlines in particular?
Well it does so by providing the user with the `-0`, `-1`, and `-e` flags:

*`-0`*
: Tell `mmv` to expect it’s input to not be seperated by newlines (‘`\n`’), but
  by NUL bytes (‘`\0`’).  NUL bytes are the only characters not allowed in
  filenames besides forward slashes, so they are an obvious choice for an
  alternative seperator.

*`-1`*
: Run the utility provided to `mmv` individually for each input file.  If we
  provide newline seperated input to a given utility, then we won’t be able to
  tell where in its output an output filename begins or ends.  By running the
  utility individually for each filename we can avoid this problem.

*`-e`*
: Encode input filenames before passing them to the provided utility.
  Characters such as tabs and newlines are backslash escaped, as is the backlash
  itself.  Other control characters are replaced with their hexadecimal
  equivalents in the format “`\xXX`” where “XX” is the hexadecimal value of the
  control character.

In order to better understand these flags and how they work let’s go though
another example.  In this case we have 2 files with newlines in their names, and
we want to simply uppercase the filenames.  In this example I am going to be
displaying newlines in filenames with the “`$'\n'`” syntax as this is what my
current shell (`zsh`) displays them as.  This will vary from shell to shell.

We can start by just trying to naïvely pass these 2 files to `mv` and use `tr`
to uppercase the names, but this doesn’t work!

```
$ ls my$'\n'file1 my$'\n'file2 | mmv tr a-z A-Z
mmv: No such file or directory (os error 2)
```

The reason this doesn’t work is because due to the line-oriented nature of
`ls` and `mmv`, we are actually trying to rename the files “my”, “file1”, “my”,
and “file2” to the new filenames “MY”, “FILE1”, “MY”, “FILE2”.  Not only do none
of those input files actually exist, but we are trying to rename “my” twice!
The first thing we need to do in order to proceed is to pass the `-0` flag to
`mmv`, because we want to use the NUL byte as our input seperator and not the
newline.  We also need `ls` to actually provide us with the filenames delimeted
by NUL bytes though.  Luckily `GNU ls` gives us the `--zero` flag to do just
that:

```
$ ls --zero my$'\n'file1 my$'\n'file2 | mmv -0 tr a-z A-Z
```

This is not done yet though!  `mmv` now realizes that we have 2 input files, one
called “my‹newline›file1” and one called “my‹newline›file2”, but it is still
providing these 2 filenames to a single `tr` process.  The result of this is
`tr` providing us with 4 lines of output as it recieved 4 lines of input.  This
in turn gets interpreted by `mmv` as 4 output files which triggers an error as
we can’t rename 2 files into 4.

This is where `-1` arrives to save the day!  By instructing `mmv` to spawn a new
instance of `tr` for each input file, then it knows that the complete output of
any given instance of `tr` regardless of how many lines the output contains must
be a single output filename.  So we can combine the `-0` and `-1` flags in order
to get a working solution:

```
$ ls --zero my$'\n'file1 my$'\n'file2 | mmv -01 tr a-z A-Z
$ ls
MY$'\n'FILE1  MY$'\n'FILE2
```

The `-e` flag isn’t quite as useful, but it is very nice to have when you want
to edit files that may contain special characters in your editor.  An example is
provided in the [examples][1] section of this page.


## Safety

When compared to the standard `for f in *; do mv $f ...; done` construct, `mmv`
is significantly more safe to use.  These are the following safety features that
are built into the tool:

1. If the number of input and output files differs, execution is aborted before
   making any changes.

2. If an input file is renamed to the name of another input file, the second
   input file is not lost (i.e. you can rename ‘a’ to ‘b’ and ‘b’ to ‘a’ with no
   problem).

3. If as a result of the renaming, a file would be overwritten which is not
   itself another input file, exeuction is aborted before making any changes.
   This can be overridden with the `-f` flag.

4. All input files must be unique, and all output files must be unique.
   Otherwise execution is aborted before making any changes.


## Examples

_All of these examples are ripped straight from the `mmv(1)` manual page
available online [here][2].  If you installed `mmv` through a package manager or
via `make install` then you should have the manual installed on your system._

Swap the files “foo” and “bar”:

```
$ ls foo bar | mmv tac
```

Rename all unhidden files in the current directory to use hyphens (‘-’) instead
of spaces:

```
$ ls | mmv tr ' ' -
```

Rename all \*.jpeg files to use the “.jpg” file extension:

```
$ ls *.jpeg | mmv sed 's/\.jpeg$/.jpg/'
```

Rename a given list of movies to use lowercase letters and hyphens instead of
uppercase letters and spaces, and number them so that they’re properly ordered
in globs (e.g. rename “The Return of the King.mp4” to
“02-the-return-of-the-king.mp4”):

```
$ ls 'The Fellowship of the Ring.mp4' ... 'The Two Towers.mp4' | \
	mmv awk '{ gsub(" ", "-"); printf "%02d-%s", NR, tolower($0) }'
```

Rename files interactively in your editor while encoding special characters to
more human friendly forms, making use of `vipe(1)` from [moreutils][3]:

```
$ ls * | mmv -e vipe
```

Rename all C source code and header files in a project repository to use
snake\_case instead of camelCase using the `GNU sed` `\L` extension:

```
$ find . -name '*.[ch]' | mmv sed 's/[A-Z]/\L_&/g'
```

[1]: #examples
[2]: /en/man/mmv/mmv.1
[3]: https://joeyh.name/code/moreutils/
