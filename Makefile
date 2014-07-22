# run: compile
run:
	DEBUG=* npm start

compile:
	cd public/javascripts; coffee -c gyazz_readwrite.coffee
	cd public/javascripts; coffee -c gyazz_buffer.coffee
	cd public/javascripts; coffee -c gyazz_lib.coffee
	cd public/javascripts; coffee -c gyazz_related.coffee
	cd public/javascripts; coffee -b -c gyazz_tag.coffee
	cd public/javascripts; coffee -c gyazz_notification.coffee
	cd public/javascripts; coffee -c gyazz.coffee

push:
	git push

test:
	grunt test

backup:
	mongoexport -d gyazz -c pages > export/masuilab.mongoexport
