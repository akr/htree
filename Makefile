RUBY=ruby
RD2HTML=rd2 -r rd/rd2html-lib.rb

all: README.html doc/index.html

README.html: README.rd
	$(RD2HTML) --html-title='htree - HTML/XML tree library' -o README README.rd

check test:
	$(RUBY) -I. test-all.rb

install:
	$(RUBY) install.rb

.PHONY: check test all install

RB = htree.rb $(wildcard htree/*.rb)
doc/index.html: $(RB)
	rm -rf doc
	rdoc $(RB)

