# unix_utils

Like FileUtils, but provides zip, unzip, bzip2, bunzip2, tar, untar, sed, du, md5sum, shasum, cut, head, tail, wc, unix2dos, dos2unix, iconv, curl, perl, etc.

Works in MRI 1.8.7+, MRI 1.9.2+, and JRuby 1.6.7+

## What to expect

For commands like zip, untar, sed, head, cut, dos2unix, etc.:

1. Just returns a path to the output, randomly named, located in the system tmp dir (`UnixUtils.unzip('kittens.zip)` &rarr; `'/tmp/unix_utils-129392301-kittens'`)
2. Never touches the input
3. Sticks a useful file extension on the output, if applicable (`UnixUtils.tar('puppies/')` &rarr; `'/tmp/unix_utils-99293192-puppies.tar'`)

For commands like du, md5sum, shasum, etc.:

1. Just returns the good stuff (the checksum, for example, not the filename that is listed after it in the standard command output)
2. Never touches the input

## Philosophy

Use a subprocess to perform a big task and then get out of memory.

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

    str = UnixUtils.shasum('kittens.zip', 256)

## Compatibility

Uses `open3` because it's in the Ruby stdlib and is consistent across MRI and JRuby.

## Where it's used

* [Brighter Planet Reference Data web service](http://data.brighterplanet.com)
* [Brighter Planet Emission Estimate web service](http://impact.brighterplanet.com) aka CM1
* [`remote_table` library](https://github.com/seamusabshere/remote_table)

## Authors

* Seamus Abshere <seamus@abshere.net>

## Copyright

Copyright (c) 2012 Brighter Planet. See LICENSE for details.
