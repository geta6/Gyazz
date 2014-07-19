run:
	DEBUG=* npm start

compile:
	grunt compile

push:
	git push

test:
	grunt test

backup:
	mongoexport -d gyazz -c pages > export/masuilab.mongoexport
