RUBY=ruby

all: README rdoc/index.html

README: misc/README.erb
	erb misc/README.erb > README

check test:
	$(RUBY) -I. test-all.rb

install:
	$(RUBY) install.rb

.PHONY: check test all install

RB = htree.rb htree/modules.rb $(wildcard htree/[a-l]*.rb) $(wildcard htree/[n-z]*.rb)
rdoc/index.html: $(RB)
	rm -rf doc
	rdoc --op rdoc $(RB)

