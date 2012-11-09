# unix_utils

Like FileUtils, but provides zip, unzip, bzip2, bunzip2, tar, untar, sed, du, md5sum, shasum, cut, head, tail, wc, unix2dos, dos2unix, iconv, curl, perl, etc.

You must have these binaries in your `PATH`. _Not_ a pure-ruby implementation of all these UNIX greats!

Works in MRI 1.8.7+, MRI 1.9.2+, and JRuby 1.6.7+. No gem dependencies; uses stdlib

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

## Rules (what you can expect)

For commands like zip, untar, sed, head, cut, dos2unix, etc.:

1. Just returns a path to the output, randomly named, located in the system tmp dir (`UnixUtils.unzip('kittens.zip)` &rarr; `'/tmp/unix_utils-129392301-kittens'`)
2. Never touches the input
3. Sticks a useful file extension on the output, if applicable (`UnixUtils.tar('puppies/')` &rarr; `'/tmp/unix_utils-99293192-puppies.tar'`)

For commands like du, md5sum, shasum, etc.:

1. Just returns the good stuff (the checksum, for example, not the filename that is listed after it in the standard command output)
2. Never touches the input

## But I can just spawn these myself

This lib was created to ease the pain of remembering command options for Gentoo, deciding which spawning method to use, possibly handling pipes...

    require 'tmpdir'
    destdir = File.join(Dir.tmpdir, "kittens_#{Kernel.rand(1e11)}")
    require 'open3'
    Open3.popen3('unzip', '-q', '-n', 'kittens.zip, '-d', destdir) do |stdin, stdout, stderr|
      stdin.close
      @error_message = stderr.read
    end

is replaced safely with

    destdir = UnixUtils.unzip 'kittens.zip'

## But I can just use `Digest::SHA256`

(Note: [Balazs Kutil](https://github.com/bkutil) pointed out [this is a bad example](https://gist.github.com/1950707)... I will replace it soon)

This will load an entire file into memory before it can be processed...

    require 'digest'
    str = Digest::SHA256.hexdigest File.read('kittens.zip')

... so you're really replacing this ...

    sha256 = Digest::SHA256.new
    File.open('kittens.zip', 'r') do |f|
      while chunk = f.read(4_194_304)
        sha256 << chunk
      end
    end
    str = sha256.hexdigest

You get the same low memory footprint with

    str = UnixUtils.shasum 'kittens.zip', 256

## Compatibility

Uses `open3` because it's in the Ruby stdlib and is consistent across MRI and JRuby.

## Wishlist

* cheat sheet based on [GNU Coreutils cheat sheet](www.catonmat.net/download/gnu-coreutils-cheat-sheet.pdf)
* yarddocs
* properly use Dir.tmpdir(name), etc.
* smarter tmp file name generation - don't include url params for curl, etc.

## Authors

* Seamus Abshere <seamus@abshere.net>

## Copyright

Copyright (c) 2012 Seamus Abshere
