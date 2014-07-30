run:
	DEBUG=* npm start

compile:
	grunt build

push:
	git push origin master

test:
	grunt test

backup:
	mongodump -d gyazz $(OPTS)


