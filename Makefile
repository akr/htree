all: index.html README.html doc/index.html

index.html: README.html
	cp README.html index.html

README.html: README.rd
	rd2 -o README README.rd

RB = htree.rb htree
doc/index.html: $(RB)
	rdoc $(RB)

