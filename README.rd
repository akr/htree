= htree - HTML/XML tree library

htree provides a tree data structure which represent HTML and XML data.

== Features

* Permissive unified HTML/XML parser
* byte-to-byte round-tripping unparser
* XML namespace support
* Dedicated class for escaped string.  This ease sanitization.
* XHTML/XML generator
* template engine
* recursive template expansion
* converter to REXML document

== Home Page

((<URL:http://cvs.m17n.org/~akr/htree/>))

== Download

* ((<URL:http://cvs.m17n.org/viewcvs/ruby/htree.tar.gz>))

== Install

  % ruby install.rb

== Reference Manual

((<URL:doc/index.html>))

== Usage Example

Following two-line script convert HTML to XHTML.

  require 'htree'
  HTree(STDIN).display_xml

The conversion method to REXML is provided as to_rexml.

  HTree(...).to_rexml

== License

Ruby's

== Author
Tanaka Akira <akr@m17n.org>
