all: index.html README.html doc/index.html

index.html: README.html
	cp README.html index.html

README.html: README.rd
	rd2 -o README README.rd

check test:
	ruby test-all.rb

.PHONY: check test all

RB = htree.rb htree
doc/index.html: $(RB)
	rm -rf doc
	rdoc $(RB)

