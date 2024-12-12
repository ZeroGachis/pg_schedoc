.PHONY : all dist pgtle clean install test

FILES = $(wildcard sql/*.sql)

UNITTESTS = $(shell find test/sql/ -type f -name '*.sql.in' | sed -e 's/.in//')

EXTENSION = schedoc

EXTVERSION   = $(shell grep -m 1 '[[:space:]]\{3\}"version":' META.json | \
	       sed -e 's/[[:space:]]*"version":[[:space:]]*"\([^"]*\)",\{0,1\}/\1/')

DATA = dist/schedoc--$(EXTVERSION).sql

DIST = dist/$(EXTENSION)--$(EXTVERSION).sql

PGTLEOUT = dist/pgtle.$(EXTENSION)--$(EXTVERSION).sql

TEST_SCHEMA = public

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)

# edit this value if you want to deploy by hand
SCHEMA = @extschema@

include $(PGXS)

all: $(DIST) $(PGTLEOUT) $(EXTENSION).control $(UNITTESTS)

clean:
	rm -f $(PGTLEOUT) $(DIST) $(UNITTESTS)

$(DIST): $(FILES)
	cat sql/table.sql > $@
	cat sql/function.sql >> $@
	cat sql/function-stop.sql >> $@
	cat sql/function-status.sql >> $@
	cat sql/start.sql >> $@
	cat $@ > dist/$(EXTENSION).sql

test:
	pg_prove -f test/sql/*.sql

test/sql/%.sql: test/sql/%.sql.in
	sed 's,_TEST_SCHEMA_,$(TEST_SCHEMA),g; ' $< > $@

$(PGTLEOUT): dist/$(EXTENSION)--$(EXTVERSION).sql pgtle_header.in pgtle_footer.in
	sed -e 's/_EXTVERSION_/$(EXTVERSION)/' pgtle_header.in > $(PGTLEOUT)
	cat dist/$(EXTENSION)--$(EXTVERSION).sql >> $(PGTLEOUT)
	cat pgtle_footer.in >> $(PGTLEOUT)

dist: $(PGTLEOUT)
	git archive --format zip --prefix=$(EXTENSION)-$(EXTVERSION)/ -o $(EXTENSION)-$(EXTVERSION).zip HEAD

$(EXTENSION).control: $(EXTENSION).control.in META.json
	sed 's,EXTVERSION,$(EXTVERSION),g; ' $< > $@;
