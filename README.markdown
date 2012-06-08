# unix_utils

Like FileUtils, but provides access to system binaries like zip, unzip, bzip2, bunzip2, tar, untar, sed, du, md5sum, shasum, cut, head, tail, wc, unix2dos, dos2unix, iconv, curl, perl, etc.

Works in MRI 1.8.7+, MRI 1.9.2+, and JRuby 1.6.7+

## Real-world usage

<p><a href="http://brighterplanet.com"><img src="https://s3.amazonaws.com/static.brighterplanet.com/assets/logos/flush-left/inline/green/rasterized/brighter_planet-160-transparent.png" alt="Brighter Planet logo"/></a></p>

We use `unix_utils` for [data science at Brighter Planet](http://brighterplanet.com/research) and in production at

* [Brighter Planet's impact estimate web service](http://impact.brighterplanet.com)
* [Brighter Planet's reference data web service](http://data.brighterplanet.com)

Originally extracted from [`remote_table`](https://github.com/seamusabshere/remote_table)

## Philosophy

Use a subprocess to perform a big task and then get out of memory.

<table>
  <tr>
    <td rowspan="2"><img src="https://github.com/seamusabshere/unix_utils/raw/master/unix-philosophy-cover.png" alt="cover of the Unix Philosophy book" /></td>
    <td><img src="https://github.com/seamusabshere/unix_utils/raw/master/unix-philosophy-quote-pg1.png" alt="Tenet 2: Make Each Program Do One Thing Well. The best programs, like Cousteau's lake fly, does but one task in its life and does it well. The program is loaded into memory, accomplishes its function, and then gets out ot the way to allow" /></td>
  </tr>
  <tr>
    <td><img src="https://github.com/seamusabshere/unix_utils/raw/master/unix-philosophy-quote-pg2.png" alt="the next single-minded program to begin. This sounds simple, yet it may surprise you how many software developers have difficulty sticking to this singular goal." /></td>
  </tr>
</table>

## Three variations

### Plain (`UnixUtils.xyz`)

1. Returns path to output file or dir, randomly named, located in the system tmp dir (`UnixUtils.unzip('kittens.zip)` &rarr; `'/tmp/unix_utils-129392301-kittens'`)
2. Doesn't modify input files
3. Sticks a useful file extension on the output, if applicable (`UnixUtils.tar('puppies/')` &rarr; `'/tmp/unix_utils-99293192-puppies.tar'`)

### String (`UnixUtils.xyz_s`)

Same as plain, except returns a string with the (useful part of the) output (`UnixUtils.shasum('kittens.zip)` &rarr; `"8b051eb364edf451e8e9344cc103a666f437753a"`)

### Bang (`UnixUtils.xyz!`)

Same as plain, except deletes the input file.

## Another way to do three variations

1. `UnixUtils.xyz`
2. `UnixUtils::String.xyz`
3. `UnixUtils::Bang.xyz`

## But I can just spawn these myself

This lib was created to ease the pain of remembering command options for Ubuntu vs. Gentoo vs. OSX&mdash;deciding which spawning method to use&mdash;possibly handling pipes...

    # you could do this yourself
    require 'tmpdir'
    destdir = File.join(Dir.tmpdir, "kittens_#{Kernel.rand(1e11)}")
    require 'open3'
    Open3.popen3('unzip', '-qq', '-n', 'kittens.zip, '-d', destdir) do |stdin, stdout, stderr|
      stdin.close
      @error_message = stderr.read
    end
    $stderr.puts @error_message

is replaced safely with

    destdir = UnixUtils.unzip 'kittens.zip'

## Compatibility

This is not a magic pure-Ruby replacement for all these utilities. They need to be available in your path and you probably have to be running Unix.

Now using [`posix-spawn`](https://github.com/rtomayko/posix-spawn) for speed. Thanks for the suggestion [jjb](https://github.com/jjb)!

Previously used `open3` because it's in the Ruby stdlib and is consistent across MRI and JRuby.

## Authors

* Seamus Abshere <seamus@abshere.net>

## Copyright

Copyright (c) 2012 Brighter Planet. See LICENSE for details.
