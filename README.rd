= htree - HTML/XML tree library

htree provides a tree data structre which represent HTML and XML data.

== Home Page

((<URL:http://cvs.m17n.org/~akr/htree/>))

== Download

* ((<URL:http://cvs.m17n.org/cgi-bin/viewcvs/htree/htree.tar.gz?tarball=1&cvsroot=ruby>))

== Feature

* Permissive unified HTML/XML parser
* byte-to-byte roundtripping unparser
* XML namespace support
* Dedicated class for escaped string.  This ease sanitization.
* XHTML/XML generator
* template engine
* recursive template expansion
* converter to REXML document

== Reference Manual

((<URL:doc/index.html>))

== Usage Example

Following two-line script convert HTML to XHTML.

  require 'htree'
  HTree.parse(STDIN).display_xml

The conversion method to REXML is provides as to_rexml.

  HTree.parse(...).to_rexml

== License

Ruby's

== Author
Tanaka Akira <akr@m17n.org>
