# unix_utils

Dead simple access to bzip2, bunzip2, tar, untar, du, sha256, etc.

TODO: md5, wc, etc.

## Philosophy

* Give a path, get a path (bzip2, bunzip2, etc.)
* Only return the good part (sha256, du, etc.)

## Spawning

Uses `open3` because it's the most consistent interface across MRI 1.8, 1.9 and JRuby.

## Authors

* Seamus Abshere <seamus@abshere.net>

## Copyright

Copyright (c) 2012 Brighter Planet. See LICENSE for details.
