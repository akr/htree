= htree - HTML/XML tree library

htree provides a tree data structre which represent HTML and XML data.

== Home Page

((<URL:http://cvs.m17n.org/~akr/htree/>))

== Download

* ((<URL:http://cvs.m17n.org/cgi-bin/viewcvs/htree/htree.tar.gz?tarball=1&cvsroot=ruby>))
* ((<URL:http://cvs.m17n.org/cgi-bin/viewcvs/htree/?tarball=1&cvsroot=ruby>))

== Feature

* Permissive unified HTML/XML parser
* byte-to-byte roundtripping unparser
* XML namespace support
* Dedicated class for escaped string.  This ease sanitization.
* XHTML/XML generator
* template engine
#* converter to REXML document

== Reference Manual

((<URL:doc/index.html>))

== Usage

#Following two-line script convert HTML to XHTML.
#
#  require 'htree'
#  puts HTree.parse(STDIN).to_xhtml

== License

Ruby's

== Author
Tanaka Akira <akr@m17n.org>
