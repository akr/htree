RUBY=ruby

all: README.html doc/index.html

README.html: README.rd
	rd2 -o README README.rd

check test:
	$(RUBY) -I. test-all.rb

install:
	$(RUBY) install.rb

.PHONY: check test all install

RB = htree.rb htree
doc/index.html: $(RB)
	rm -rf doc
	rdoc $(RB)

