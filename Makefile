all: index.html doc/index.html

index.html: README.rd
	rd2 -o index README.rd

RB = htree.rb $(wildcard htree/*.rb)
doc/index.html: $(RB)
	rdoc $(RB)

