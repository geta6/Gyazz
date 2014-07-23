run:
	DEBUG=* npm start

compile:
	cd public/javascripts; make

push:
	git push

test:
	grunt test

backup:
	mongoexport -d gyazz -c pages > export/masuilab.mongoexport
